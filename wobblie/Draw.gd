extends Node2D

onready var pen_size_slider := $UI/VBoxContainer/PenSizeGroup/PenSizeSlider
onready var pen_size_line_edit := $UI/VBoxContainer/PenSizeGroup/PenSizeLineEdit
onready var file_dialogue := $UI/FileDialog
onready var viewport := $UI/ViewportContainer/Viewport
onready var viewport_container: ViewportContainer = $UI/ViewportContainer

onready var normal_offset_slider := $UI/VBoxContainer/NormalOffsetGroup/NormalOffsetSlider
onready var normal_offset_line_edit := $UI/VBoxContainer/NormalOffsetGroup/NormalOffsetLineEdit

onready var time_influence_slider := $UI/VBoxContainer/TimeInfluenceGroup/TimeInfluenceSlider
onready var time_influence_line_edit := $UI/VBoxContainer/TimeInfluenceGroup/TimeInfluenceLineEdit

onready var y_div_slider := $UI/VBoxContainer/YDivGroup/YDivSlider
onready var y_div_line_edit := $UI/VBoxContainer/YDivGroup/YDivLineEdit

onready var layer_grid_container: GridContainer = $UI/VBoxContainer/Layers/GridContainer
onready var layer_1_button: Button = $UI/VBoxContainer/Layers/GridContainer/Layer1Button

onready var layer_1: Node = $UI/ViewportContainer/Viewport/Layer1
var layer_container = preload('res://LayerContainer.tscn')
var layer_button = preload('res://LayerButton.tscn')

var button_layer_number = 1 # Numbers that are on the layer buttons
var current_layer_index = 0 # Layer1 node is index 0
var current_layer

const WOBBLE_SHADER = preload('res://wobble_lines.gdshader')
const NORMAL_OFFSET_DEFAULT = 2.0
const TIME_INFLUENCE_DEFAULT = 2.0 
const Y_DIV_DEFAULT = 2.0
const PEN_SIZE_DEFAULT = 5.0

var normal_offset_value: float = NORMAL_OFFSET_DEFAULT
var time_influence_value: float = TIME_INFLUENCE_DEFAULT
var y_div_value: float = Y_DIV_DEFAULT
var pen_width: float = PEN_SIZE_DEFAULT

var undo_strokes_dictionary : Dictionary
var stroke_index = 0 # To ensure correct undo order, also one line is instanced at ready

var redo_strokes_dictionary : Dictionary
var redo_strokes_index = 0

var pen_color: Color
var pen_line2d: Line2D
var pen_on_canvas: bool

var frame_count = 0
const MAX_FRAMES = 60

#TODO:
#- Layer indicator (highlight)
#- Fix undo order (undo according to layer order i think)
#- Export folder to executable location
#- Somehow fix redo line parameters

#- Page setup
	#- Description
	#- Icon

#STRETCH GOALS:
#- Fill tool
#- GUI overhaul

func _ready() -> void:
	current_layer = layer_1
	pen_color = Color(0, 0, 0)
	instance_new_pen_stroke()
	
	pen_size_line_edit.text = str(pen_width)
	normal_offset_line_edit.text = str(normal_offset_value)
	time_influence_line_edit.text = str(time_influence_value)
	y_div_line_edit.text = str(y_div_value)
	
	var _extensions: Array = ['*.png', '*.jpg', '*.jpeg']
	for e in _extensions:
		file_dialogue.add_filter(e)

func _input(event: InputEvent) -> void:
	if (not pen_on_canvas): return
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			pen_line2d.add_point(viewport.get_mouse_position())
	elif event is InputEventMouseButton:
		instance_new_pen_stroke()

func _unhandled_key_input(_event: InputEventKey) -> void:
	if Input.is_action_just_pressed('undo'):
		undo()
	if Input.is_action_just_pressed('redo'):
		redo()

func _on_ColorPicker_color_changed(color: Color) -> void:
	pen_color = color

func _on_ClearButton_pressed() -> void:
	var _strokes = current_layer.get_children()
	if _strokes:
		for stroke in _strokes:
			stroke.queue_free()
			
func _on_UndoButton_pressed() -> void:
	undo()

func redo():
	if redo_strokes_index > 0:
		redo_strokes_index -= 1
	pen_line2d = Line2D.new()
	var _mat = ShaderMaterial.new()
	pen_line2d.material = _mat
	pen_line2d.antialiased = true
	pen_line2d.begin_cap_mode = 2
	pen_line2d.end_cap_mode = 2
	pen_line2d.joint_mode = 2
	
	pen_line2d.default_color = pen_color
	pen_line2d.width = pen_width
	_mat.set_shader_param('normal_offset', normal_offset_value)
	_mat.set_shader_param('time_influence', time_influence_value)
	_mat.set_shader_param('y_div', y_div_value)
	
	_mat.set_shader(WOBBLE_SHADER)
	pen_line2d.material = _mat
	
	if redo_strokes_dictionary and redo_strokes_index >= 0:
		var stroke = redo_strokes_dictionary[redo_strokes_index]
		for point in stroke:
			pen_line2d.add_point(point)
#
	get_current_layer(false)
	current_layer.add_child(pen_line2d)
	
	pen_line2d.add_to_group('strokes')
	
func undo():
	var _strokes = get_tree().get_nodes_in_group('strokes')
	if _strokes:
		for stroke in _strokes:
			if stroke.get_point_count() > 0:
				redo_strokes_dictionary[redo_strokes_index] = stroke.points
		
		redo_strokes_index += 1
		
		if weakref(_strokes.pop_back()).get_ref() and _strokes.size() > 0:
			_strokes.pop_back().queue_free()
			_strokes.pop_back().queue_free()
		else:
			return

func _on_RedoButton_pressed() -> void:
	if redo_strokes_index > 0:
		redo()
	
func _on_ViewportContainer_mouse_entered() -> void:
	pen_on_canvas = true
	
func _on_ViewportContainer_mouse_exited() -> void:
	pen_on_canvas = false
	
func instance_new_pen_stroke():
	var _mat = ShaderMaterial.new()
	normal_offset_slider.value = normal_offset_value
	time_influence_slider.value = time_influence_value
	y_div_slider.value = y_div_value
	_mat.set_shader_param('normal_offset', normal_offset_value)
	_mat.set_shader_param('time_influence', time_influence_value)
	_mat.set_shader_param('y_div', y_div_value)
	_mat.set_shader(WOBBLE_SHADER)
	pen_line2d = Line2D.new()
	pen_line2d.material = _mat
	pen_line2d.antialiased = true
	pen_line2d.begin_cap_mode = 2
	pen_line2d.end_cap_mode = 2
	pen_line2d.joint_mode = 2
	pen_line2d.default_color = pen_color
	pen_line2d.width = pen_width

	get_current_layer(true)
	
	pen_line2d.add_to_group('strokes')
	undo_strokes_dictionary[stroke_index] = pen_line2d
	stroke_index += 1

# REFACTOR
func _on_HSlider_value_changed(value: float) -> void:
	pen_width = value
	pen_size_line_edit.text = str(value)

func _on_PenSizeLineEdit_text_entered(new_text: String) -> void:
	pen_size_slider.value = float(new_text)
	pen_width = float(new_text)
	
func _on_TimeInfluenceSlider_value_changed(value: float) -> void:
	time_influence_value = value
	time_influence_line_edit.text = str(value)
	
func _on_TimeInfluenceLineEdit_text_entered(new_text: String) -> void:
	time_influence_slider.value = float(new_text)
	time_influence_value = float(new_text)

func _on_NormalOffsetSlider_value_changed(value: float) -> void:
	normal_offset_value = value
	normal_offset_line_edit.text = str(value)

func _on_NormalOffsetLineEdit_text_entered(new_text: String) -> void:
	normal_offset_slider.value = float(new_text)
	normal_offset_value = float(new_text)

func _on_YDivSlider_value_changed(value: float) -> void:
	y_div_value = value
	y_div_line_edit.text = str(value)

func _on_YDivLineEdit_text_entered(new_text: String) -> void:
	y_div_slider.value = float(new_text)
	y_div_value = float(new_text)

func _on_SaveButton_pressed() -> void:
	file_dialogue.popup()

func _on_FileDialog_confirmed() -> void:
	pass

func switch_layers(layer_id):
	current_layer_index = int(layer_id) - 1
	get_current_layer(false)

func _on_AddLayerButton_pressed() -> void:
	button_layer_number += 1
	var _layer_button = layer_button.instance()
	_layer_button.text = str(button_layer_number)
	layer_grid_container.add_child(_layer_button)
	
	current_layer_index = button_layer_number - 1
	var _layer_container = layer_container.instance()
	viewport.add_child(_layer_container)
	
	_layer_button.connect('pressed', self, 'switch_layers', [_layer_button.text])

func _on_Layer1Button_pressed() -> void:
	current_layer_index = 0
	current_layer = layer_1

func get_current_layer(add_line2d: bool):
	var _i = 0
	for c in viewport.get_children():
		if current_layer_index == _i:
			if add_line2d:
				c.add_child(pen_line2d)
			current_layer = c
			break
		_i += 1
