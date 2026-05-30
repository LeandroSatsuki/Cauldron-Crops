extends Panel

@onready var points_label: Label = $PointsLabel
@onready var btn_skill_golem: Button = $TeiaSkills/BtnSkillGolem
@onready var btn_skill_agua: Button = $TeiaSkills/BtnSkillAgua
@onready var btn_skill_dormir: Button = $TeiaSkills/BtnSkillDormir
@onready var btn_fechar: Button = $BtnFechar

func _ready() -> void:
	if btn_skill_agua:
		btn_skill_agua.tooltip_text = "Nascente Infinita\nCusto: 1 Ponto\nEfeito: Expande a capacidade máxima do poço para 20 de água."
	if btn_skill_dormir:
		btn_skill_dormir.tooltip_text = "Sono Saudável\nCusto: 1 Ponto\nEfeito: Reduz o custo base do sono para 2 moedas e suaviza o multiplicador de spam."
	if btn_skill_golem:
		btn_skill_golem.tooltip_text = "Mestre dos Golems\nCusto: 2 Pontos\nEfeito: Aumenta o limite máximo de Golems ativos em +1."
		
	if btn_skill_golem:
		btn_skill_golem.pressed.connect(_on_btn_skill_golem_pressed)
	if btn_skill_agua:
		btn_skill_agua.pressed.connect(_on_btn_skill_agua_pressed)
	if btn_skill_dormir:
		btn_skill_dormir.pressed.connect(_on_btn_skill_dormir_pressed)
	if btn_fechar:
		btn_fechar.pressed.connect(func(): visible = false)

func _process(_delta: float) -> void:
	if points_label:
		points_label.text = "Pontos de Alquimia: " + str(GlobalInventory.pontos_alquimia)
		
	if btn_skill_golem:
		btn_skill_golem.disabled = (GlobalInventory.pontos_alquimia < 2) or ("skill_golem" in GlobalInventory.skills_desbloqueadas)
	if btn_skill_agua:
		btn_skill_agua.disabled = (GlobalInventory.pontos_alquimia < 1) or ("skill_agua" in GlobalInventory.skills_desbloqueadas)
	if btn_skill_dormir:
		btn_skill_dormir.disabled = (GlobalInventory.pontos_alquimia < 1) or ("skill_dormir" in GlobalInventory.skills_desbloqueadas)

func _on_btn_skill_golem_pressed() -> void:
	if GlobalInventory.pontos_alquimia >= 2 and not ("skill_golem" in GlobalInventory.skills_desbloqueadas):
		GlobalInventory.pontos_alquimia -= 2
		GlobalInventory.skills_desbloqueadas.append("skill_golem")
		EconomyManager.max_golems += 1
		print("Habilidade Golem desbloqueada! Limite máximo: ", EconomyManager.max_golems)

func _on_btn_skill_agua_pressed() -> void:
	if GlobalInventory.pontos_alquimia >= 1 and not ("skill_agua" in GlobalInventory.skills_desbloqueadas):
		GlobalInventory.pontos_alquimia -= 1
		GlobalInventory.skills_desbloqueadas.append("skill_agua")
		EconomyManager.poco_capacidade_maxima = 20
		print("Habilidade Poço desbloqueada! Capacidade máxima de água: ", EconomyManager.poco_capacidade_maxima)

func _on_btn_skill_dormir_pressed() -> void:
	if GlobalInventory.pontos_alquimia >= 1 and not ("skill_dormir" in GlobalInventory.skills_desbloqueadas):
		GlobalInventory.pontos_alquimia -= 1
		GlobalInventory.skills_desbloqueadas.append("skill_dormir")
		print("Habilidade Sono Saudável desbloqueada!")
