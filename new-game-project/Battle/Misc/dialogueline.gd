extends Resource
class_name DialogueLine

@export_multiline var text: String = ""
@export var expression: Array[int] = [0, 0] ## e.g. [head_frame, body_frame] — read by your Enemy's _set_expression()
@export var pauses: Array[PauseMarker] = []
