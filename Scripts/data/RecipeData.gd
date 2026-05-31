extends Resource
class_name RecipeData

@export var id: String = ""
@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var categoria: String = "pocao"
@export var ingredientes: Array[String] = []
@export var resultado_item: String = ""
@export var resultado_quantidade: int = 1
@export var tempo_producao: float = 2.0
@export var ordem_importa: bool = false
@export var desbloqueada_por_padrao: bool = false
@export var recompensa_pontos_alquimia: int = 1
@export var tags: Array[String] = []
@export var versao_do_schema: int = 1
