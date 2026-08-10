extends HBoxContainer
class_name BattleHUD

@onready var Name: RichTextLabel = $Name
@onready var Lv: RichTextLabel = $Lv
@onready var HpBar: ProgressBar = $MarginContainer/HpBar
@onready var KrBar: ProgressBar = $MarginContainer/KrBar
@onready var HpBarContainer: MarginContainer = $MarginContainer
@onready var KrText: RichTextLabel = $KrText/KR
@onready var Hp: RichTextLabel = $Hp

@onready var soul: SoulBattle = get_parent().get_node("Soul")

@export var character_name: String = "CHARA"
@export var level: int = 1

func _ready() -> void:
	set_kr(true)
	_process(0.0)

func _process(_delta: float) -> void:
	Name.text = character_name
	Lv.text = "Lv " + str(level)
	HpBarContainer.custom_minimum_size.x = min(max(soul.max_hp * 1.2 + 1, 4), 160)
	HpBar.value = soul.hp - soul.kr
	KrBar.value = soul.hp
	HpBar.max_value = soul.max_hp
	KrBar.max_value = soul.max_hp
	var hptext := "[color=%s]" % Color.MAGENTA.to_html() if soul.kr > 0 else ""
	Hp.text = hptext + "%s / %s" % [soul.hp,soul.max_hp]

func set_kr(to := true) -> void:
	KrText.visible = to
	KrBar.visible = to
