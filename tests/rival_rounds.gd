extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    if FileAccess.file_exists(SaveSystemV2.SAVE_PATH):
        quit(1)
        return
    seed(7631)
    var index := int(OS.get_environment("CONDENA_RIVAL"))
    var arena = load("res://src/combat/combat_scene.tscn").instantiate()
    root.add_child(arena)
    await process_frame
    var campaign: CondenaCampaign = arena.campaign_bridge.campaign
    campaign.scene_index = CondenaCampaign.FIGHT_SCENES[index]
    if index == 1:
        assert(campaign.record_choice("flaco", "A"))
    arena._start_combat()
    arena.selection.layout.get_child(-1).pressed.emit()
    # Controles de jugador contra IA activa, con salud, tiempo y resistencia de campaña.
    while not arena.match_over:
        var distance: float = arena.chico.position.x - arena.hacker.position.x
        arena.movement = signf(distance) if absf(distance) > 83 else 0
        if absf(distance) <= 118 and arena.hacker.can_attack(10):
            if arena.chico.blocking and absf(distance) <= 90:
                arena.hacker.grab_attack()
            elif arena.chico.busy and arena.chico.attack_kind == "heavy":
                arena.hacker.parry()
            elif arena.hacker.stamina > 50 and arena.chico.recovery_time > 0:
                arena.hacker.heavy_attack()
            else:
                arena.hacker.quick_attack()
        await physics_frame
    assert(arena.match_result != "EMPATE")
    assert(arena.hacker.health < arena.hacker.max_health or arena.chico.health < arena.chico.max_health)
    assert(arena.event_history.any(func(e): return e.fighter == arena.chico.fighter_name and e.event == "attack_started"))
    await create_timer(1.0).timeout
    print("ROUND OK ", arena.chico.fighter_name, " / ", arena.match_result, " / ", snappedf(arena.elapsed_seconds, 0.1), " s")
    quit()
