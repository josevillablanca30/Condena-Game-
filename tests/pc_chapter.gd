extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Run with a temporary XDG_DATA_HOME. Never overwrite a player's save.
    if FileAccess.file_exists(SaveSystemV2.SAVE_PATH):
        push_error("Usa un perfil temporal vacío.")
        quit(1)
        return
    var arena = load("res://src/combat/combat_scene.tscn").instantiate()
    root.add_child(arena)
    await process_frame
    arena.start_button.pressed.emit()
    var story: CondenaStoryScreen = arena.story_screen
    assert(story.visible and story.ambience.playing and not arena.hud.visible)
    story.next_button.pressed.emit()
    for i in 2:
        assert(story.clip_index == i and story.film.is_playing())
        await create_timer(0.6).timeout
        assert(story.film.stream_position > 0.1)
        await story.film.finished
        assert(story.still.texture != null and story.panel.visible)
        if i == 0:
            story.next_button.pressed.emit()
    assert(story.choices_box.get_child_count() == 3)
    var replies := ["Así me gusta, perkin culao.", "¡¿Qué dijiste, tonto rehueón?!", "¿Te creí choro, gil colao?"]
    for i in 3:
        if i > 0:
            story.present("EL COMEDOR", CondenaChapterOneScript.lines_for(1))
        story.choices_box.get_child(i).pressed.emit()
        assert(story.dialogue_label.text == replies[i])
        var persisted := CondenaCampaign.new()
        persisted.load_progress()
        assert(persisted.reputation == [-5, 10, 0][i])
        persisted.free()
    story.next_button.pressed.emit()
    assert(arena.selection.visible and not arena.match_started)
    var fighter: CondenaFighter = arena.hacker
    for slot in CondenaFighter.MOVE_SLOTS:
        for id in CondenaFighter.MOVE_DATA:
            assert(fighter.equip_move(slot, id))
            assert(fighter.equipped_moves[slot] == id)
            assert(fighter.equipped_moves.values().count(id) == 1)
    assert(not fighter.equip_move("invalid", "cross"))
    arena.selection.buttons[0].pressed.emit()
    arena.selection.layout.get_child(-1).pressed.emit()
    assert(arena.match_started and arena.chico.active_move_id == "jab")
    assert(arena.combat_ai.is_physics_processing())
    await create_timer(0.6).timeout
    assert(fighter.health < fighter.max_health)
    arena.combat_ai.set_physics_process(false)
    await create_timer(0.9).timeout
    var key := InputEventKey.new()
    key.keycode = KEY_H
    key.pressed = true
    root.push_input(key)
    await process_frame
    await process_frame
    assert(fighter.active_move_id == "jab")
    await create_timer(0.55).timeout
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_LEFT_SHOULDER
    pad.pressed = true
    root.push_input(pad)
    await process_frame
    await process_frame
    assert(fighter.blocking)
    pad.pressed = false
    root.push_input(pad)
    await process_frame
    await process_frame
    assert(not fighter.blocking)
    arena._finish(false)
    assert(arena.campaign_bridge.campaign.scene_index == 3)
    assert(arena.restart_button.text == "CONTINUAR CAPÍTULO")
    var campaign: CondenaCampaign = arena.campaign_bridge.campaign
    campaign.scene_index = 2
    assert(campaign.record_fight_result(0, true))
    assert(campaign.scene_index == 3 and campaign.choices["fight_0_won"])
    for index in [4, 7]:
        campaign.scene_index = index
        if index == 4:
            campaign.record_choice("flaco", "A")
        assert(arena.campaign_bridge.start_current_fight(fighter, arena.chico))
        assert(arena.campaign_bridge.submit_combat_result(true))
        assert(campaign.scene_index == index + 1)
    print("CONDENA PC OK: dos clips completos, tres réplicas y reputaciones guardadas, selector, IA, teclado, mando simulado y derrota.")
    quit()
