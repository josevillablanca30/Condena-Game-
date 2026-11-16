extends Node
class_name AIElChico

@export var fighter: CondenaFighter
@export var target: CondenaFighter
var cooldown := 0.0
var decision_time := 0.0
var guard_time := 0.0

func _physics_process(delta: float) -> void:
    if fighter == null or target == null or fighter.dead or target.dead:
        return
    cooldown = maxf(0.0, cooldown - delta)
    decision_time = maxf(0.0, decision_time - delta)
    guard_time = maxf(0.0, guard_time - delta)
    var distance := target.position.x - fighter.position.x
    var gap := absf(distance)
    var low_stamina := fighter.stamina < 32.0
    # La IA deja espacio para reaccionar y recupera resistencia.
    if low_stamina:
        fighter.set_block(false)
        fighter.set_direction(-signf(distance) if gap < 160.0 else 0.0)
        return
    if guard_time > 0.0:
        fighter.set_direction(0.0)
        fighter.set_block(true)
        return
    fighter.set_block(false)
    fighter.set_direction(signf(distance) if gap > 90.0 else 0.0)
    if decision_time <= 0.0 and gap <= 125.0 and not fighter.busy:
        decision_time = randf_range(0.45, 0.95)
        if target.blocking and gap <= 75.0 and fighter.stamina >= 25.0:
            fighter.grab_attack()
            cooldown = 1.15
        elif target.busy and target.attack_kind != "" and gap <= 110.0:
            # Decision probabilistica y con enfriamiento: no lee golpes futuros.
            var defensive_roll := randf()
            if defensive_roll < 0.24 and fighter.stamina >= 38.0:
                fighter.dodge()
                cooldown = 0.75
            elif defensive_roll < 0.62:
                guard_time = randf_range(0.20, 0.42)
        elif cooldown <= 0.0 and gap <= 110.0:
            if fighter.stamina >= 28.0 and randf() < 0.35:
                fighter.heavy_attack()
            else:
                fighter.quick_attack()
            cooldown = randf_range(0.85, 1.45)
