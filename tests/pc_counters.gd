extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var fighter := CondenaFighter.new()
    var rival := CondenaFighter.new()
    root.add_child(fighter)
    root.add_child(rival)
    fighter.opponent = rival
    rival.opponent = fighter
    fighter.position.x = 400
    for id in CondenaFighter.MOVE_DATA:
        var move: Dictionary = CondenaFighter.MOVE_DATA[id]
        assert(fighter.equip_move("light", id))
        rival.position.x = 620
        var before := rival.health
        fighter.stamina = float(move.cost) - 1
        fighter.quick_attack()
        assert(not fighter.busy)
        fighter.stamina = 100
        fighter.quick_attack()
        assert(is_equal_approx(fighter.stamina, 100 - float(move.cost)))
        await create_timer(float(move.duration) + 0.06).timeout
        assert(rival.health == before and not fighter.busy and fighter.recovery_time > 0)
        fighter.quick_attack()
        assert(not fighter.busy)
        await create_timer(0.25).timeout
        rival.position.x = 463
        rival.set_block(true)
        fighter.quick_attack()
        await create_timer(float(move.duration) + 0.25).timeout
        assert(rival.health < before)
        if move.kind == "grab":
            assert(not rival.blocking and rival.last_hit_result == "hit")
        else:
            assert(rival.last_hit_result == "guarded")
        rival.health = rival.max_health
        rival.stamina = rival.max_stamina
        rival.guard_pressure = 0
        rival.set_block(false)
        await create_timer(0.9).timeout
    fighter.position.x = 380
    rival.position.x = 435
    rival.stamina = 100
    rival.dodge()
    assert(rival.invulnerable and rival.receive_hit(8, "grab", "clinch") == "evaded")
    await create_timer(0.24).timeout
    assert(not rival.invulnerable and rival.position.x > 435 and rival.recovery_time > 0)
    print("CONDENA COUNTERS OK: seis técnicas, alcance, coste, recuperación, guardia, agarres y esquiva.")
    quit()
