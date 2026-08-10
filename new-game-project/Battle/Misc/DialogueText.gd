extends AdvancedTextTyper
class_name EnemySpeech

@export var current_character: characters = characters.GENERIC
enum characters {
	GENERIC,
	SANS,
	PAPYRUS,
	UNDYNE,
	UNDYNE_UNDYING,
	ALPHYS,
	ASGORE,
	FLOWEY,
	FLOWEY_EVIL,
	GASTER,
	METTATON,
	TEMMIE,
	TORIEL
}

const CLICK_NODE_NAMES := {
	characters.GENERIC: "Generic",
	characters.SANS: "Sans",
	characters.PAPYRUS: "Papyrus",
	characters.UNDYNE: "Undyne",
	characters.UNDYNE_UNDYING: "UndyneTheUndying",
	characters.ALPHYS: "Alphys",
	characters.ASGORE: "Asgore",
	characters.FLOWEY: "Flowey",
	characters.FLOWEY_EVIL: "FloweyEvil",
	characters.GASTER: "Gaster",
	characters.METTATON: "Mettaton",
	characters.TEMMIE: "Temmie",
	characters.TORIEL: "Toriel",
}

func character_customize() -> void:
	match current_character:
		characters.PAPYRUS:
			currentfont = load("res://Text/Fonts/papyrus.ttf")
		characters.SANS:
			currentfont = load("res://Text/Fonts/pixel-comic-sans-undertale-sans-font.ttf")
		characters.TEMMIE:
			entire_text_bbcode = "[shake amp=6]"

func _get_click_sound() -> AudioStreamPlayer:
	var node_name: String = CLICK_NODE_NAMES.get(current_character, "Generic")
	return get_node_or_null("Sounds/" + node_name)

func type_text_advanced(dialogues: Dialogues) -> void:
	typing = true
	var expressions: Array = dialogues.get_dialogues_single(Dialogues.DIALOGUE_EXPRESSIONS)
	for i: int in dialogues.dialogues.size():
		started_typing.emit(i)
		expression_set.emit(expressions[i])
		pauses = dialogues.dialogues[i].pauses
		await type_buffer(dialogues, i)
		await confirm
		get_viewport().set_input_as_handled()
	finished_all_texts.emit()
	typing = false
