extends BattleBoxBehaviour

@onready var items_container: Control = Box.get_node("Items")
@onready var text_containers: Array[Control] = [
	Box.get_node("Items/Columns/TextContainer1"),
	Box.get_node("Items/Columns/TextContainer2"),
]
@onready var items_labels: Array[RichTextLabel] = [
	Box.get_node("Items/Columns/TextContainer1/Viewport1/Column1"),
	Box.get_node("Items/Columns/TextContainer2/Viewport2/Column2"),
]
@onready var sliders: Array[ItemSlider] = [
	Box.get_node("Items/ScrollContainer/Slider1"),
	Box.get_node("Items/ScrollContainer/Slider2"),
]
@onready var soul: SoulBattle = Box.get_parent().get_node("Soul")

# Number of items in each column. Column 0 gets the first N, column 1 the rest.
var column_item_counts: Array[int] = [4, 3]
var visible_items := 3

var col := 0
var row := 0
var scroll_offset: Array[float] = [0.0, 0.0]

func _on_gain_control() -> void:
	col = 0
	row = 0
	scroll_offset[0] = 0.0
	scroll_offset[1] = 0.0

	items_container.show()
	soul.visible = true
	soul.menu_enable()

	# Let the nested HBoxContainer/MarginContainer layout resolve before we
	# measure line heights off of it - a single frame isn't always enough
	# once labels are nested inside Columns/TextContainerN.
	await get_tree().process_frame
	await get_tree().process_frame

	for i in text_containers.size():
		# TextContainerN's height is fixed directly in the scene (96px = 3 lines).
		text_containers[i].position.y = 0
		# ColumnN is the content - it moves inside the fixed window to scroll.
		items_labels[i].position.y = 0
		_update_slider(i)

	_update_soul_position()

func _line_height(c: int) -> float:
	var lines := items_labels[c].get_line_count()

	if lines <= 0:
		return 24.0

	return items_labels[c].get_content_height() / float(lines)

func _max_scroll(c: int) -> float:
	var line_height := _line_height(c)

	return max(
		(column_item_counts[c] - visible_items) * line_height,
		0.0
	)

func _update_soul_position() -> void:
	var line_height := _line_height(col)

	soul.global_position = Vector2(
		items_labels[col].global_position.x - 16.0,
		items_labels[col].global_position.y
			+ row * line_height
			+ line_height / 2.0
	)

func _update_scroll(c: int) -> void:
	var line_height := _line_height(c)
	var max_scroll := _max_scroll(c)
	var cursor_row := row if c == col else 0

	if cursor_row >= scroll_offset[c] / line_height + visible_items:
		scroll_offset[c] = (cursor_row - visible_items + 1) * line_height

	elif cursor_row < scroll_offset[c] / line_height:
		scroll_offset[c] = cursor_row * line_height

	scroll_offset[c] = clamp(
		scroll_offset[c],
		0.0,
		max_scroll
	)

	items_labels[c].position.y = -scroll_offset[c]

	_update_slider(c)

func _update_slider(c: int) -> void:
	var line_height := _line_height(c)

	# scroll_offset[c] is always set as a whole multiple of line_height in
	# _update_scroll, so this is just "how many lines have we scrolled".
	# ItemSlider animates its own Grabber toward offset + step_size * value
	# in its _process(), so we only ever set value - never touch Grabber
	# directly, or the slider's own lerp fights us and snaps it right back.
	sliders[c].value = int(round(scroll_offset[c] / line_height))

func input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		row = (row + 1) % column_item_counts[col]

		Box.click.play()
		_update_scroll(col)
		_update_soul_position()

	elif event.is_action_pressed("ui_up"):
		row = (row - 1 + column_item_counts[col]) % column_item_counts[col]

		Box.click.play()
		_update_scroll(col)
		_update_soul_position()

	elif event.is_action_pressed("ui_right") and col < text_containers.size() - 1:
		col += 1
		row = min(row, column_item_counts[col] - 1)

		Box.click.play()
		_update_scroll(col)
		_update_soul_position()

	elif event.is_action_pressed("ui_left") and col > 0:
		col -= 1
		row = min(row, column_item_counts[col] - 1)

		Box.click.play()
		_update_scroll(col)
		_update_soul_position()

	elif event.is_action_pressed("ui_accept"):
		# Global item index: column 0's items first, then column 1's.
		var offset := 0
		for i in col:
			offset += column_item_counts[i]

		Box.sub_choice = offset + row
		Box.click.play()
		Box.change_state(BattleBox.State.Blittering)

	elif event.is_action_pressed("ui_cancel"):
		Box.change_state(BattleBox.State.Menu)

	get_viewport().set_input_as_handled()

func _on_lose_control() -> void:
	items_container.hide()
