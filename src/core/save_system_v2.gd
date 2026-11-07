extends Node
class_name SaveSystemV2

const SAVE_PATH := "user://save_condena.json"
const SAVE_VERSION := 2

static func save_profile(data: Dictionary) -> bool:
    var payload := data.duplicate(true)
    payload["save_version"] = SAVE_VERSION
    var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
    if file == null:
        push_error("No se pudo abrir el archivo temporal de guardado.")
        return false
    file.store_string(JSON.stringify(payload))
    file.flush()
    file.close()
    var absolute_temp := ProjectSettings.globalize_path(SAVE_PATH + ".tmp")
    var absolute_save := ProjectSettings.globalize_path(SAVE_PATH)
    var err := DirAccess.rename_absolute(absolute_temp, absolute_save)
    if err != OK:
        push_error("No se pudo finalizar el guardado: %s" % err)
        return false
    return true

static func load_profile() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK or not (json.data is Dictionary):
        push_warning("Guardado corrupto o incompatible.")
        return {}
    return json.data
