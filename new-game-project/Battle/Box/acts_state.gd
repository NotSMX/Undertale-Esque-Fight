extends BattleBoxBehaviour

@onready var acts_container: Control = Box.get_node("Acts")
@onready var col1: RichTextLabel = Box.get_node("Acts/Options/Column1")
@onready var col2: RichTextLabel = Box.get_node("Acts/Options/Column2")
@onready var soul: SoulBattle = Box.get_parent().get_node("Soul")

var col_sizes := [2, 1] # Column1: Check, Shoo | Column2: Flex
var column := 0
var row := 0

func _on_gain_control() -> void:
	column = 0
	row = 0
	acts_container.show()
	soul.visible = true
	soul.menu_enable()
	await get_tree().process_frame
	_update_soul_position()

func _current_label() -> RichTextLabel:
	return col1 if column == 0 else col2

func _line_height(label: RichTextLabel) -> float:
	var font: Font = label.get_theme_font("normal_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	return font.get_height(font_size)

func _update_soul_position() -> void:
	var label := _current_label()
	var line_height := _line_height(label)
	soul.global_position = Vector2(
		label.global_position.x - 16.0,
		label.global_position.y + row * line_height + line_height / 2.0
	)

func _flat_choice() -> int:
	var index := 0
	for i in column:
		index += col_sizes[i]
	return index + row

func input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		row = (row + 1) % col_sizes[column]
		Box.click.play()
		_update_soul_position()
	elif event.is_action_pressed("ui_up"):
		row = (row - 1 + col_sizes[column]) % col_sizes[column]
		Box.click.play()
		_update_soul_position()
	elif event.is_action_pressed("ui_right"):
		if column < col_sizes.size() - 1:
			column += 1
			row = min(row, col_sizes[column] - 1)
			Box.click.play()
			_update_soul_position()
	elif event.is_action_pressed("ui_left"):
		if column > 0:
			column -= 1
			row = min(row, col_sizes[column] - 1)
			Box.click.play()
			_update_soul_position()
	elif event.is_action_pressed("ui_accept"):
		Box.sub_choice = _flat_choice()
		Box.change_state(BattleBox.State.Blittering)
	elif event.is_action_pressed("ui_cancel"):
		Box.change_state(BattleBox.State.Menu)
	get_viewport().set_input_as_handled()

func _on_lose_control() -> void:
	acts_container.hide()
	soul.visible = false
