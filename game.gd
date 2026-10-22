extends Control

#variables
@onready var grid_container: GridContainer = $CenterContainer/MainHBox/GridWrapper/GridContainer
@onready var crosshairs: Control = $CenterContainer/MainHBox/GridWrapper/Crosshairs
@onready var row_labels_container: VBoxContainer = $CenterContainer/MainHBox/RowLabels
@onready var col_labels_container: HBoxContainer = $CenterContainer/MainHBox/GridWrapper/ColLabels
@onready var progress_bar: ProgressBar = $CenterContainer/MainHBox/GridWrapper/ProgressBar
@onready var Lclick= $CenterContainer/Lclick


var board_data = []
var width = 10
var height = 10
var default_value = 0
var total_correct: int = 0
var filled_correct: int = 0

var solution_board =[
	[1,1,0,0,1,1,1,1,1,0],
	[1,0,1,1,0,0,0,1,1,0],
	[1,0,1,0,1,0,0,1,1,1],
	[1,0,1,1,1,1,1,1,1,0],
	[1,0,0,0,0,0,0,0,1,1],
	[0,0,0,1,1,1,1,1,1,0],
	[1,1,0,1,1,1,1,1,0,0],
	[1,0,0,0,1,0,0,0,0,0],
	[1,1,0,1,0,0,0,0,0,0],
	[1,1,1,0,1,1,1,0,0,1],
]
var selected_cell: Button
var selected_index: Vector2i = Vector2i(-1, -1)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for y in range (height):
		var row=[]
		for x in range(width):
			row.append(default_value)
		board_data.append(row)
		
	for row in solution_board:
		for cell in row:
			if cell == 1:
				total_correct += 1

	progress_bar.min_value = 0
	progress_bar.max_value = total_correct
	progress_bar.value = 0
	
	create_legend_labels()
	create_board()
	#timeout only nessecary because board build animation takes a second
	await get_tree().create_timer(1.5).timeout
	draw_center_dividers()
	
	
func create_board():
	for x in range(width):
		for y in range(height):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(50,50)
			btn.set_meta("x",x)
			btn.set_meta("y",y)
		
			# Connect the gui_input signal to handle mouse clicks on the button
			btn.gui_input.connect(_on_button_gui_input.bind(btn))
			grid_container.add_child(btn)
			# Not nessecary just to show how the grid is built
			await get_tree().create_timer(0.01).timeout
			


func create_legend_labels() -> void:
	var button_size = Vector2(50, 50)
	
	# Fetch horizontal and vertical separation directly from GridContainer
	var h_sep = grid_container.get_theme_constant("h_separation")
	var v_sep = grid_container.get_theme_constant("v_separation")

	# If h_sep returns 0, set it to GridContainer's default override 
	if h_sep == 0:
		h_sep = 4

	# Column Labels
	for x in range(width):
		var col_data = get_column_data(x)
		var clues = get_line_clues(col_data)
		
		var lbl = Label.new()
		lbl.text = "\n".join(clues)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
		# Set exact width matching each button column + grid gap
		lbl.custom_minimum_size = Vector2(button_size.x, 0)
		await get_tree().create_timer(0.05).timeout
		col_labels_container.add_child(lbl)

	# Row Labels
	for y in range(height):
		var row_data = solution_board[y]
		var clues = get_line_clues(row_data)
		
		var lbl = Label.new()
		var text_clues = []
		for c in clues:
			text_clues.append(str(c))
		lbl.text = "  ".join(text_clues)
		
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, button_size.y)
		await get_tree().create_timer(0.05).timeout
		row_labels_container.add_child(lbl)
		
		
func draw_center_dividers() -> void:
	# Wait for GridContainer to compute layout sizes
	await get_tree().process_frame

	
	for child in crosshairs.get_children():
		child.queue_free()

	# Match crosshairs to GridContainer's position and size
	crosshairs.global_position = grid_container.global_position
	crosshairs.size = grid_container.size

	var line_thickness := 3.0
	var line_color := Color.WHITE

	var half_x: int = width / 2
	var half_y: int = height / 2

	var button_size = Vector2(50, 50)
	var h_sep = grid_container.get_theme_constant("h_separation")
	var v_sep = grid_container.get_theme_constant("v_separation")
	if h_sep == 0: h_sep = 4
	if v_sep == 0: v_sep = 4

	# Calculate center relative to crosshairs 
	var center_x_pos = half_x * (button_size.x + h_sep) - (h_sep / 2.0)
	var center_y_pos = half_y * (button_size.y + v_sep) - (v_sep / 2.0)

	# vertical crosshair
	var v_line = ColorRect.new()
	v_line.color = line_color
	v_line.size = Vector2(line_thickness, grid_container.size.y)
	v_line.position = Vector2(center_x_pos - (line_thickness / 2.0), 0)
	v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshairs.add_child(v_line)

	# horizontal crosshair
	var h_line = ColorRect.new()
	h_line.color = line_color
	h_line.size = Vector2(grid_container.size.x, line_thickness)
	h_line.position = Vector2(0, center_y_pos - (line_thickness / 2.0))
	h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshairs.add_child(h_line)

func _on_clear_button_pressed() -> void:
	clear_board()
	
# Calculates run lengths of consecutive 1s for a single array line
func get_line_clues(line: Array) -> Array:
	var clues = []
	var count = 0
	for cell in line:
		if cell == 1:
			count += 1
		elif count > 0:
			clues.append(count)
			count = 0
	if count > 0:
		clues.append(count)
	return clues if clues.size() > 0 else [0]

# Extracts a single column as an array (top to bottom)
func get_column_data(col_x: int) -> Array:
	var col = []
	for row_y in range(height):
		col.append(solution_board[row_y][col_x])
	return col


func _on_button_gui_input(event: InputEvent, btn: Button) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	var x: int = btn.get_meta("x")
	var y: int = btn.get_meta("y")

	if event.button_index == MOUSE_BUTTON_LEFT:
		handle_cell_action(x, y, btn, MOUSE_BUTTON_LEFT)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		handle_cell_action(x, y, btn, MOUSE_BUTTON_RIGHT)



func handle_cell_action(x: int, y: int, btn: Button, mouse_button: int) -> void:
	var current_val: int = board_data[x][y]

	#  Left-clicked cells are locked permanently
	if current_val == 1 or current_val == -1:
		print("Cell cannot be changed!")
		return

	var new_val: int = current_val

	if mouse_button == MOUSE_BUTTON_LEFT:
		# Check against solution_board 
		var correct_val: int = solution_board[x][y]
		
		if correct_val == 1:
			Lclick.play()
			new_val = 1 
		else:
			new_val = -1  
			
	elif mouse_button == MOUSE_BUTTON_RIGHT:
		# Toggle between rclick (2=Grey) and empty (0=Normal)
		if current_val == 2:
			new_val = 0
		else:
			new_val = 2

	# If state changed, update array and visual styling
	if new_val != current_val:
		board_data[x][y] = new_val
		update_cell_ui(btn, new_val)

		if new_val == 1:
			filled_correct += 1
			progress_bar.value = filled_correct
			if filled_correct == total_correct:
				print("Nonogram complete!")

func clear_board() -> void:
	# 1. Reset board_data values to default (0)
	for x in range(width):
		for y in range(height):
			board_data[x][y] = default_value

	# 2. Reset visual styling for all buttons in GridContainer
	for btn in grid_container.get_children():
		if btn is Button:
			update_cell_ui(btn, default_value)
	filled_correct = 0
	progress_bar.value = 0

func update_cell_ui(btn: Button, value: int) -> void:
	match value:
		0:
			# Normal
			btn.modulate = Color.WHITE
			btn.text = ""
		1:
			# Correct Lclick=green
			btn.modulate = Color.GREEN
			btn.text = "1"
		-1:
			# Incorrect Lclick=red
			btn.modulate = Color.RED
			btn.text = "X"
		2:
			# Rclick=grey
			btn.modulate = Color.GRAY
			btn.text = "?"
