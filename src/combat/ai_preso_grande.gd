extends Node
class_name AIPresoGrande

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0
var block_timer := 0.0
var last_read_serial := -1

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown = maxf(0, cooldown - delta)
    block_timer = maxf(0, block_timer - delta)
    var distance := target.position.x - fighter.position.x
    var gap := absf(distance)
    if target.busy and gap < 118 and last_read_serial != target.attack_serial:
        last_read_serial = target.attack_serial
        if randf() < 0.7:
            block_timer = 0.45
    fighter.set_block(block_timer > 0 and fighter.stamina >= 12)
    fighter.set_direction(signf(distance) if gap > 77 else 0.0)
    if cooldown > 0 or not fighter.can_attack(25):
        return
    if target.blocking and gap <= 88:
        fighter.grab_attack()
        cooldown = 1.5
    elif gap <= 114 and fighter.stamina >= 28:
        fighter.heavy_attack()
        cooldown = randf_range(1.5, 2.2)
