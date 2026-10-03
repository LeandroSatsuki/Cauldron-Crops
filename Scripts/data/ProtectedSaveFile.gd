extends RefCounted

# Arquivos adjacentes, mesmo volume. Não carrega backups automaticamente.
func write(path: String, data: Dictionary) -> Dictionary:
	var text := JSON.stringify(data)
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var error := _write_verified(temporary, text)
	if error != OK:
		return _failure("Não foi possível conferir o arquivo temporário.", error)
	if FileAccess.file_exists(path):
		var previous := FileAccess.open(path, FileAccess.READ)
		if previous == null:
			return _failure("Não foi possível ler o save anterior; ele foi preservado.", FileAccess.get_open_error())
		var old_text := previous.get_as_text()
		previous.close()
		if not _is_json_object(old_text):
			return _failure("Save anterior inválido; gravação recusada para preservar o arquivo e a cópia de segurança.", ERR_FILE_CORRUPT)
		error = _write_verified(backup + ".tmp", old_text)
		if error != OK:
			return _failure("Não foi possível preparar a cópia de segurança; save anterior preservado.", error)
		error = _replace(backup + ".tmp", backup)
		if error != OK:
			return _failure("Não foi possível atualizar a cópia de segurança; save anterior preservado.", error)
	error = _replace(temporary, path)
	if error != OK:
		return _failure("Não foi possível concluir a gravação; save anterior e cópia de segurança preservados.", error)
	return {"success": true, "error": OK, "message": ""}

func _write_verified(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.get_as_text()
	file.close()
	if written != text or not _is_json_object(written):
		return ERR_FILE_CORRUPT
	return OK

func _is_json_object(text: String) -> bool:
	var json := JSON.new()
	return json.parse(text) == OK and json.data is Dictionary

func _replace(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(to))

func _failure(message: String, error: Error) -> Dictionary:
	return {"success": false, "error": error, "message": message}
