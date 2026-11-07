extends Node
class_name AIElFlaco

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0
var dodge_cooldown := 0.0

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown -= delta
    dodge_cooldown -= delta
    var distance := target.position.x - fighter.position.x
    var gap := absf(distance)
    if target.busy and gap < 115.0 and dodge_cooldown <= 0.0 and randf() < 0.08:
        fighter.dodge()
        dodge_cooldown = 1.4
    fighter.set_direction(signf(distance) if gap > 93.0 else (-signf(distance) if gap < 65.0 else 0.0))
    if gap <= 105.0 and cooldown <= 0.0:
        fighter.quick_attack()
        cooldown = randf_range(0.9, 1.4)
