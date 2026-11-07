extends Node
class_name AIPresoGrande

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0
var block_timer := 0.0

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown -= delta
    block_timer = maxf(0.0, block_timer - delta)
    var distance := target.position.x - fighter.position.x
    var gap := absf(distance)
    if target.busy and gap < 100.0 and block_timer <= 0.0 and randf() < 0.07:
        fighter.set_block(true)
        block_timer = 0.6
    if block_timer <= 0.0:
        fighter.set_block(false)
    fighter.set_direction(signf(distance) if gap > 85.0 else 0.0)
    if gap <= 105.0 and cooldown <= 0.0 and not fighter.blocking:
        fighter.heavy_attack()
        cooldown = randf_range(2.0, 3.0)
