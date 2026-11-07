extends AnimatedSprite2D
class_name CharacterAnimator

signal action_completed

var is_busy := false
var current_action := ""

func _ready() -> void:
    animation_finished.connect(_on_animation_finished)

func play_action(name: String) -> bool:
    if is_busy and name != "hit_impact" and name != "knockout" and name != "defeat":
        return false
    if sprite_frames == null or not sprite_frames.has_animation(name):
        return false
    is_busy = true
    current_action = name
    play(name)
    return true

func play_loop(name: String) -> void:
    if is_busy or sprite_frames == null or not sprite_frames.has_animation(name):
        return
    if animation != name or not is_playing():
        play(name)

func _on_animation_finished() -> void:
    if not is_busy:
        return
    var finished_action := current_action
    is_busy = false
    current_action = ""
    action_completed.emit()
    if finished_action != "knockout" and finished_action != "defeat":
        play_loop("idle")

func force_unlock() -> void:
    is_busy = false
    current_action = ""
    play_loop("idle")
