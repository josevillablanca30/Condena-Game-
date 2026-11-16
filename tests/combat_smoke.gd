extends SceneTree

# Smoke test sin plugins ni servicios de pago. Ejecutar con Godot 4.2.2:
# godot --headless --path . --script res://tests/combat_smoke.gd

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("CONDENA SMOKE: " + message)
    quit(1)

func _run() -> void:
    var packed: PackedScene = load("res://src/combat/combat_scene.tscn")
    if packed == null:
        _fail("No carga la escena principal")
        return
    var arena: Node2D = packed.instantiate()
    root.add_child(arena)
    await process_frame

    var hacker: CondenaFighter = arena.get_node("Hacker")
    var chico: CondenaFighter = arena.get_node("Chico")
    if hacker.opponent != chico or chico.opponent != hacker:
        _fail("Los luchadores no tienen rivales enlazados")
        return
    if hacker.health <= 0.0 or chico.health <= 0.0:
        _fail("La pelea empieza sin salud")
        return

    hacker.position.x = 500.0
    chico.position.x = 585.0
    var health_before: float = chico.health
    hacker.quick_attack()
    await create_timer(0.40).timeout
    if chico.health >= health_before:
        _fail("El jab en alcance no hizo daño")
        return

    hacker.quick_attack()
    await create_timer(0.40).timeout
    if hacker.combo_hits < 2:
        _fail("Dos golpes confirmados no registraron combo")
        return

    chico.set_block(true)
    var guarded_before: float = chico.health
    hacker.quick_attack()
    await create_timer(0.40).timeout
    var guarded_damage: float = guarded_before - chico.health
    if guarded_damage <= 0.0 or guarded_damage >= hacker.attack_damage:
        _fail("El bloqueo no redujo el daño del jab")
        return

    chico.set_block(false)
    var after_guard: float = chico.health
    hacker.feint()
    await create_timer(0.25).timeout
    if chico.health != after_guard:
        _fail("El amague infligio daño")
        return

    await create_timer(0.20).timeout
    var parry_health: float = hacker.health
    hacker.parry()
    var parry_result: String = hacker.receive_hit(15.0, "heavy", "cross")
    if parry_result != "parried" or hacker.health != parry_health or hacker.counter_window <= 0.0:
        _fail("La parada perfecta no nego daño o no habilito contraataque")
        return
    await create_timer(0.40).timeout
    var grab_health: float = hacker.health
    hacker.parry()
    var grab_result: String = hacker.receive_hit(8.0, "grab", "clinch")
    if grab_result == "parried" or hacker.health >= grab_health:
        _fail("Un agarre no supero la parada")
        return
    print("CONDENA SMOKE OK: escena, rivales, impactos, combos, bloqueo, amague, parada y agarre")
    quit(0)
