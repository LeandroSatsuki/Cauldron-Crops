extends Node
const Writer := preload("res://Scripts/data/ProtectedSaveFile.gd")
const MAIN := preload("res://Scenes/Main.tscn")
var checks := 0
var failed := false

class FailingWriter extends "res://Scripts/data/ProtectedSaveFile.gd":
	var fail_backup := false
	func _replace(from: String, to: String) -> Error:
		if to.ends_with(".bak") == fail_backup:
			return ERR_FILE_CANT_WRITE
		return super._replace(from, to)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var sandbox := ProjectSettings.globalize_path("res://Builds/QA/").replace("\\", "/")
	if not OS.get_user_data_dir().replace("\\", "/").begins_with(sandbox):
		push_error("ProtectedSaveFileSmokeTest: exige APPDATA em Builds/QA; nenhum arquivo foi alterado.")
		get_tree().quit(1)
		return
	# Diretório exclusivo por execução, sem tocar arquivos de sessões anteriores.
	var dir := "user://protected_test_%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir + "/save.json"
	var writer := Writer.new()
	var first := {"version": 3.0, "probe": "primeiro á漢"}
	var second := {"version": 4.0, "probe": "segundo"}
	_check(writer.write(path, first).success and _read(path) == first, "primeira gravação/Unicode")
	_check(not FileAccess.file_exists(path + ".bak"), "primeiro save inventou backup")
	_check(writer.write(path, second).success and _read(path) == second and _read(path + ".bak") == first, "substituição e backup v3")
	var fail := FailingWriter.new()
	fail.fail_backup = true
	_check(not fail.write(path, first).success and _read(path) == second and _read(path + ".bak") == first, "falha de backup alterou original")
	fail.fail_backup = false
	_check(not fail.write(path, first).success and _read(path) == second and _read(path + ".bak") == second, "falha de promoção perdeu último válido")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	file.store_string("{incompleto")
	file.close()
	_check(_read(path) == second, "temporário incompleto afetou principal")
	_check(writer.write(path, first).success and _read(path) == first, "nova gravação não substituiu temporário órfão")
	_check(not writer.write(dir + "/missing/save.json", first).success, "diretório ausente não reportou erro")
	var blocked := dir + "/blocked.json"
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked + ".tmp"))
	_check(not writer.write(blocked, first).success and not FileAccess.file_exists(blocked), "temporário bloqueado criou principal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked + ".tmp"))
	_check(writer.write(blocked, first).success, "gravação após desbloquear")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked + ".bak.tmp"))
	_check(not writer.write(blocked, second).success and _read(blocked) == first, "backup temporário bloqueado perdeu principal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked + ".bak.tmp"))
	_check(writer.write(blocked, second).success and _read(blocked + ".bak") == first, "retomada após falha de backup")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{corrompido")
	file.close()
	_check(not writer.write(path, first).success and FileAccess.get_file_as_string(path) == "{corrompido" and _read(path + ".bak") == second, "principal inválido sobrescreveu backup")
	# Integração real save/load, somente com user:// isolado pelo runner.
	if failed:
		get_tree().quit(1)
		return
	PocoManager.set_process(false)
	var main := MAIN.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	main.process_mode = Node.PROCESS_MODE_DISABLED
	_check(SaveManager.save_game(), "save_game real falhou")
	var snapshot: Variant = _read(SaveManager.SAVE_PATH)
	_check(SaveManager.save_game() and _read(SaveManager.SAVE_PATH + ".bak") == snapshot, "backup real")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH + ".tmp"))
	_check(not SaveManager.save_game() and _read(SaveManager.SAVE_PATH) == snapshot and not SaveManager.last_file_error.is_empty(), "erro real não preservou save/feedback")
	if "--capture" in OS.get_cmdline_user_args():
		for frame in range(20):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Builds/QA/ProtectedSave"))
		get_viewport().get_texture().get_image().save_png("res://Builds/QA/ProtectedSave/error.png")
	var visible_error := false
	for child in get_tree().root.get_children():
		if child is AcceptDialog:
			visible_error = child.visible and "cópia de segurança" in child.dialog_text
			child.queue_free()
	_check(visible_error, "falha não mostrou aviso de backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH + ".tmp"))
	_check(SaveManager.load_game(), "load_game real falhou")
	_check(SaveManager.delete_save() and not FileAccess.file_exists(SaveManager.SAVE_PATH + ".bak"), "novo jogo manteve artefatos")
	if failed:
		get_tree().quit(1)
		return
	print("ProtectedSaveFileSmokeTest: PASS - %d verificações; arquivo, falhas e save/load isolados." % checks)
	get_tree().quit(0)

func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("ProtectedSaveFileSmokeTest: FAIL - " + message)
