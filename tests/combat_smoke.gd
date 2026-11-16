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

    arena.call("_toggle_duel_mode")
    if not arena.get("local_duel"):
        _fail("No se activo el modo duelo local")
        return
    arena.call("_start_combat")
    var ai: AIElChico = arena.get("combat_ai")
    if ai.is_physics_processing():
        _fail("La IA siguio activa en el duelo local")
        return

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

    await create_timer(0.40).timeout
    var parry_health: float = hacker.health
    hacker.parry()
    var parry_result: String = hacker.receive_hit(15.0, "heavy", "cross")
    if parry_result != "parried" or hacker.health != parry_health or hacker.counter_window <= 0.0:
        _fail("La parada perfecta no nego daño o no habilito contraataque")
        return
    await create_timer(0.50).timeout
    var grab_health: float = hacker.health
    hacker.parry()
    var grab_result: String = hacker.receive_hit(8.0, "grab", "clinch")
    if grab_result == "parried" or hacker.health >= grab_health:
        _fail("Un agarre no supero la parada")
        return
    # Efectos secundarios de tecnicas equipables.
    await create_timer(0.50).timeout
    hacker.stamina = hacker.max_stamina
    hacker.equip_move("light", "low_kick")
    hacker.quick_attack()
    await create_timer(0.50).timeout
    if chico.leg_slow_time <= 0.0:
        _fail("La patada baja no ralentizo al rival")
        return
    await create_timer(0.25).timeout
    hacker.stamina = hacker.max_stamina
    hacker.equip_move("grapple", "takedown")
    chico.position.x = hacker.position.x + 61.0
    hacker.grab_attack()
    await create_timer(0.55).timeout
    if chico.knockdown_time <= 0.0:
        _fail("El derribo no produjo knockdown")
        return

    # El historial de la pelea se mantiene en memoria sin llamadas remotas.
    var history: Array = arena.get("event_history")
    if history.size() < 5:
        _fail("No se registraron suficientes eventos de combate")
        return

    print("CONDENA SMOKE OK: escena, 1v1 local, golpes, combos, guardia, amague, parada, agarre, patada baja, derribo y eventos")
    quit(0)
