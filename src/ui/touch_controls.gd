extends CanvasLayer
class_name TouchControlsManager

@export var player: CondenaFighter

func _on_btn_golpe_rapido_pressed() -> void:
    if player: player.quick_attack()

func _on_btn_golpe_fuerte_pressed() -> void:
    if player: player.heavy_attack()

func _on_btn_agarre_pressed() -> void:
    if player and player.has_method("grab_attack"):
        player.call("grab_attack")

func _on_btn_esquiva_pressed() -> void:
    if player: player.dodge()

func _on_btn_bloquear_button_down() -> void:
    if player: player.set_block(true)

func _on_btn_bloquear_button_up() -> void:
    if player: player.set_block(false)
