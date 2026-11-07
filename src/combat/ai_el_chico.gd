extends Node
class_name AIElChico

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown -= delta
    var distance := target.position.x - fighter.position.x
    fighter.set_direction(signf(distance) if absf(distance) > 82.0 else 0.0)
    if absf(distance) <= 105.0 and cooldown <= 0.0:
        if randf() < 0.7:
            fighter.quick_attack()
        else:
            fighter.heavy_attack()
        cooldown = randf_range(1.2, 1.8)
