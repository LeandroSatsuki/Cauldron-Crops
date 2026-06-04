extends Node

enum ToolType {
	NONE,
	HOE,
	SEED,
	WATERING_CAN,
	HARVEST
}

var active_tool: ToolType = ToolType.NONE

func select_tool(tool: ToolType) -> void:
	if active_tool == tool:
		clear_tool()
		return

	active_tool = tool
	print("ToolManager: ferramenta ativa = %s" % get_tool_name(active_tool))

func select_hoe() -> void:
	select_tool(ToolType.HOE)

func select_seed() -> void:
	select_tool(ToolType.SEED)

func select_watering_can() -> void:
	select_tool(ToolType.WATERING_CAN)

func select_harvest() -> void:
	select_tool(ToolType.HARVEST)

func clear_tool() -> void:
	if active_tool == ToolType.NONE:
		return

	active_tool = ToolType.NONE
	print("ToolManager: ferramenta ativa = %s" % get_tool_name(active_tool))

func get_active_tool() -> ToolType:
	return active_tool

func is_hoe_selected() -> bool:
	return active_tool == ToolType.HOE

func is_seed_selected() -> bool:
	return active_tool == ToolType.SEED

func is_watering_can_selected() -> bool:
	return active_tool == ToolType.WATERING_CAN

func is_harvest_selected() -> bool:
	return active_tool == ToolType.HARVEST

func get_tool_name(tool: int = -1) -> String:
	var tool_to_read: int = tool
	if tool_to_read < 0:
		tool_to_read = int(active_tool)

	match tool_to_read:
		ToolType.NONE:
			return "Nenhuma"
		ToolType.HOE:
			return "Enxada"
		ToolType.SEED:
			return "Semente"
		ToolType.WATERING_CAN:
			return "Regador"
		ToolType.HARVEST:
			return "Colheita"
		_:
			return "Desconhecida"
