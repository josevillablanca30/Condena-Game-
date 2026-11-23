extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    if FileAccess.file_exists(SaveSystemV2.SAVE_PATH):
        push_error("Ejecutar con perfil temporal vacío.")
        quit(1)
        return
    var route := int(OS.get_environment("CONDENA_TEST_ROUTE"))
    assert(route in [0, 1, 2])
    assert(change_scene_to_file("res://src/combat/combat_scene.tscn") == OK)
    await process_frame
    await process_frame
    current_scene.start_button.pressed.emit()
    var visited: Array[int] = []
    var resumed := false
    while true:
        await process_frame
        var arena = current_scene
        if arena == null:
            continue
        var campaign: CondenaCampaign = arena.campaign_bridge.campaign
        var scene := campaign.scene_index
        if not visited.has(scene):
            visited.append(scene)
        if scene == 9:
            assert(visited == [0,1,2,3,4,5,6,7,8,9])
            assert(campaign.completed_fights == [0,1,2])
            assert(campaign.reputation == [-5,10,0][route])
            assert(campaign.moral_consequences()[["aliado_joven","pierde_moralidad","respeto_por_miedo"][route]])
            assert(campaign.choices["flaco"] == ["A","B","C"][route])
            break
        var story: CondenaStoryScreen = arena.story_screen
        if story.visible:
            if story.film.is_playing():
                await story.film.finished
            elif story.waiting_for_choice:
                story.choices_box.get_child(route).pressed.emit()
                if scene == 5 and not resumed:
                    resumed = true
                    arena.pause_screen.open()
                    arena.pause_screen.menu.get_child(-1).pressed.emit()
                    await process_frame
                    await process_frame
                    current_scene.start_button.pressed.emit()
            else:
                story.next_button.pressed.emit()
        elif arena.selection.visible:
            arena.selection.layout.get_child(-1).pressed.emit()
        elif arena.match_over:
            assert(arena.continue_chapter)
            arena.restart_button.pressed.emit()
        elif arena.match_started:
            var index := campaign.current_fight_index()
            assert(arena.chico.fighter_name == ["EL CHICO","EL FLACO","PRESO GRANDE"][index])
            assert(arena.combat_ai.is_physics_processing())
            arena.combat_ai.set_physics_process(false)
            # Fijar salud y distancia sólo para comprobar ambas salidas por impacto real.
            await create_timer(0.8).timeout
            var win := (index + route) % 2 == 0
            var attacker: CondenaFighter = arena.hacker if win else arena.chico
            var defender: CondenaFighter = attacker.opponent
            defender.health = 1.0
            defender.position.x = attacker.position.x + (65 if win else -65)
            await physics_frame
            await physics_frame
            attacker.basic_attack()
            arena.pause_screen.open()
            var elapsed: float = arena.elapsed_seconds
            await create_timer(0.45).timeout
            assert(defender.health == 1 and arena.elapsed_seconds == elapsed)
            arena.pause_screen.close()
            await create_timer(0.45).timeout
            assert(arena.match_over and campaign.choices["fight_%d_won" % index] == win)
            arena.restart_button.pressed.emit()
    print("FULL CHAPTER OK route ", route, " scenes ", visited)
    quit()
