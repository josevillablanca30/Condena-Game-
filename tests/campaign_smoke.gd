extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var campaign := CondenaCampaign.new()
    root.add_child(campaign)
    # Prueba aislada, sin escribir el guardado real del jugador.
    assert(campaign.scene_index == 0)
    assert(campaign.current_fight_index() == -1)
    assert(campaign.fight_index_for_scene(2) == 0)
    assert(campaign.fight_index_for_scene(4) == 1)
    assert(campaign.fight_index_for_scene(7) == 2)
    assert(campaign.opponent_for_fight(0)["id"] == "el_chico")
    assert(campaign.opponent_for_fight(1)["id"] == "el_flaco")
    assert(campaign.opponent_for_fight(2)["id"] == "preso_grande")
    assert(not campaign.record_fight_result(0, true))
    # Sin persistencia: comprobar el avance de estado directamente.
    campaign.scene_index = 2
    assert(campaign.current_fight_index() == 0)
    assert(campaign.record_fight_result(0, false))
    assert(campaign.scene_index == 3)
    assert(campaign.choices["fight_0_won"] == false)
    campaign.scene_index = 2
    assert(not campaign.advance_narrative())
    assert(campaign.scene_index == 2)
    campaign.completed_fights.append(0)
    assert(campaign.fight_index_for_scene(5) == 1)
    assert(campaign.opponent_for_fight(-1).is_empty())
    var screen := CondenaStoryScreen.new()
    root.add_child(screen)
    await process_frame
    assert(screen.next_button != null)
    screen.present("ESCENA", [{"speaker": "CONDENA", "text": "Prueba técnica"}])
    assert(screen.visible)
    assert(screen.dialogue_label.text == "Prueba técnica")
    screen._next_line()
    assert(not screen.visible)
    print("CONDENA CAMPAIGN SMOKE OK")
    quit(0)
