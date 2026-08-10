extends Resource
class_name Dialogues

const DIALOGUE_EXPRESSIONS := "expression"

@export var dialogues: Array[DialogueLine] = []

func get_dialogues_single(property: String) -> Array:
	var result: Array = []
	for line in dialogues:
		result.append(line.get(property))
	return result
