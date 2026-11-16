extends SceneTree

func _initialize() -> void:
    var required := [
        "res://src/combat/combat_scene.tscn",
        "res://src/combat/combat_scene.gd",
        "res://src/combat/fighter.gd",
        "res://src/combat/character_animator.gd",
        "res://src/core/progression_manager.gd",
        "res://src/core/save_system_v2.gd",
        "res://src/ui/touch_controls.gd"
    ]
    var missing := 0
    for path in required:
        if not ResourceLoader.exists(path):
            push_error("Falta recurso: " + path)
            missing += 1
        else:
            print("Encontrado: ", path)
    if missing == 0:
        print("Archivos presentes. Esto NO verifica gameplay ni exportación Android.")
    quit(1 if missing > 0 else 0)
