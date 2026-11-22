extends Node
class_name AIElFlaco

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0
var last_read_serial := -1

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown = maxf(0, cooldown - delta)
    var distance := target.position.x - fighter.position.x
    var gap := absf(distance)
    fighter.set_direction(signf(distance) if gap > 90 else (-signf(distance) if gap < 75 else 0.0))
    if not fighter.can_attack(10):
        return
    if target.busy and gap < 115 and last_read_serial != target.attack_serial:
        last_read_serial = target.attack_serial
        if fighter.stamina >= 28 and randf() < 0.35:
            fighter.dodge()
            return
    if gap <= 116 and (fighter.counter_window > 0 or target.recovery_time > 0 or cooldown <= 0):
        fighter.quick_attack()
        cooldown = randf_range(0.9, 1.4)
