extends Node

enum ToolType {
	NONE,
	HOE
}

var active_tool: ToolType = ToolType.NONE

func select_tool(tool: ToolType) -> void:
	active_tool = tool
	print("ToolManager: ferramenta ativa = %s" % get_tool_name(active_tool))

func select_hoe() -> void:
	select_tool(ToolType.HOE)

func clear_tool() -> void:
	select_tool(ToolType.NONE)

func get_active_tool() -> ToolType:
	return active_tool

func is_hoe_selected() -> bool:
	return active_tool == ToolType.HOE

func get_tool_name(tool: int = -1) -> String:
	var tool_to_read: int = tool
	if tool_to_read < 0:
		tool_to_read = int(active_tool)

	match tool_to_read:
		ToolType.NONE:
			return "Nenhuma"
		ToolType.HOE:
			return "Enxada"
		_:
			return "Desconhecida"
