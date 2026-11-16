extends Node2D

@onready var hacker: CondenaFighter = $Hacker
@onready var chico: CondenaFighter = $Chico

var movement := 0.0
var match_over := false
var ai_cooldown := 0.0
var health_label: Label
var enemy_label: Label
var status_label: Label
var loadout_label: Label
var technique_buttons: Dictionary = {}
var match_started := false
var combat_ai: AIElChico
var start_button: Button
var loadout_button: Button
var hit_effect_time := 0.0
var hit_effect_position := Vector2.ZERO
var hit_effect_label := ""
var combat_feed: Array[String] = []
var feed_label: Label
var combo_label: Label
var player_health_bar: ProgressBar
var player_stamina_bar: ProgressBar
var enemy_health_bar: ProgressBar
var enemy_stamina_bar: ProgressBar
var elapsed_seconds := 0.0
var event_history: Array[Dictionary] = []
var fighter_stats: Dictionary = {"HACKER": {"hits": 0, "dodges": 0, "parries": 0, "counters": 0, "combos": 0}, "EL CHICO": {"hits": 0, "dodges": 0, "parries": 0, "counters": 0, "combos": 0}}
var timer_label: Label
var restart_button: Button
var tutorial_label: Label
var action_buttons: Array[Button] = []
var broadcast_view := false
var local_duel := false
var duel_mode_button: Button
var camera_impact := 0.0
var camera_impact_strength := 0.0
var impact_direction := 1.0
var match_export_path := ""
const MOVE_LABELS := {"jab": "JAB", "low_kick": "PATADA BAJA", "cross": "CROSS", "elbow": "CODAZO", "clinch": "CLINCH", "takedown": "DERRIBO"}
const EVENT_LABELS := {
    "feint": "AMAGUE",
    "attack_started": "ATAQUE",
    "hit_confirmed": "IMPACTO",
    "combo_hit": "COMBO",
    "attack_whiffed": "FALLÓ",
    "blocked_attack": "BLOQUEADO",
    "guarded": "DEFENSA",
    "guard_broken": "GUARDIA ROTA",
    "perfect_dodge": "ESQUIVA PERFECTA",
    "counter_hit": "CONTRAATAQUE",
    "dodge_recovery": "FIN DE ESQUIVA",
    "parry_attempt": "INTENTO DE PARADA",
    "perfect_parry": "PARADA PERFECTA",
    "attack_parried": "GOLPE CONTRARRESTADO"
}

func _ready() -> void:
    hacker.opponent = chico
    chico.opponent = hacker
    hacker.defeated.connect(func(): _finish(false))
    # Provisional: encuentros mas breves para probar lectura, recursos y combos.
    hacker.max_health = 120.0
    chico.max_health = 115.0
    hacker.health = hacker.max_health
    chico.health = chico.max_health
    chico.defeated.connect(func(): _finish(true))
    hacker.confirmed_hit.connect(_on_confirmed_hit)
    chico.confirmed_hit.connect(_on_confirmed_hit)
    hacker.combat_event.connect(func(event_name: String, move_id: String): _record_event("HACKER", event_name, move_id))
    chico.combat_event.connect(func(event_name: String, move_id: String): _record_event("EL CHICO", event_name, move_id))
    hacker.combo_changed.connect(_update_combo)
    _build_ui()
    _refresh_loadout_label()
    combat_ai = AIElChico.new()
    combat_ai.fighter = chico
    combat_ai.target = hacker
    add_child(combat_ai)
    combat_ai.set_physics_process(false)
    queue_redraw()

func _process(delta: float) -> void:
    hit_effect_time = maxf(0.0, hit_effect_time - delta)
    camera_impact = maxf(0.0, camera_impact - delta)
    if match_started and not match_over:
        elapsed_seconds += delta
        timer_label.text = "%02d:%02d" % [int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60]
    if match_over:
        return
    var keyboard_direction := 0.0
    if Input.is_key_pressed(KEY_A) or (not local_duel and Input.is_key_pressed(KEY_LEFT)):
        keyboard_direction -= 1.0
    if Input.is_key_pressed(KEY_D) or (not local_duel and Input.is_key_pressed(KEY_RIGHT)):
        keyboard_direction += 1.0
    hacker.set_direction(clampf(movement + keyboard_direction, -1.0, 1.0) if match_started else 0.0)
    if match_started and local_duel:
        var rival_direction := 0.0
        if Input.is_key_pressed(KEY_LEFT):
            rival_direction -= 1.0
        if Input.is_key_pressed(KEY_RIGHT):
            rival_direction += 1.0
        chico.set_direction(rival_direction)
    # La IA ahora se ejecuta desde AIElChico, sin duplicar ataques.
    health_label.text = "HACKER"
    player_health_bar.max_value = hacker.max_health
    player_health_bar.value = hacker.health
    player_stamina_bar.max_value = hacker.max_stamina
    player_stamina_bar.value = hacker.stamina
    enemy_health_bar.max_value = chico.max_health
    enemy_health_bar.value = chico.health
    enemy_stamina_bar.max_value = chico.max_stamina
    enemy_stamina_bar.value = chico.stamina
    for slot in technique_buttons:
        var button: Button = technique_buttons[slot]
        var move_id: String = str(hacker.equipped_moves[slot])
        var cost: float = float(CondenaFighter.MOVE_DATA[move_id]["cost"])
        button.disabled = not match_started or match_over or hacker.dead or hacker.busy or hacker.stamina < cost
    queue_redraw()

func _draw() -> void:
    var camera_shift := Vector2(impact_direction * camera_impact_strength * camera_impact / 0.15, 0.0)
    draw_set_transform(camera_shift)
    # Patio de la carcel: arte procedural original sin assets ni creditos externos.
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.075, 0.075, 0.075))
    draw_rect(Rect2(0, 0, 1280, 475), Color(0.13, 0.13, 0.13))
    for x in range(0, 1280, 128):
        draw_line(Vector2(x, 0), Vector2(x, 472), Color(0.19, 0.19, 0.19), 3.0)
    for y in range(90, 475, 92):
        draw_line(Vector2(0, y), Vector2(1280, y), Color(0.18, 0.18, 0.18), 2.0)
    # Ventanas con barrotes y siluetas de publico en segundo plano.
    for window_index in range(4):
        var wx := 96.0 + float(window_index) * 312.0
        draw_rect(Rect2(wx, 65, 170, 190), Color(0.035, 0.035, 0.035))
        for bar_index in range(5):
            var bx := wx + 18.0 + float(bar_index) * 33.0
            draw_line(Vector2(bx, 65), Vector2(bx, 255), Color(0.38, 0.38, 0.38), 6.0)
        draw_line(Vector2(wx, 170), Vector2(wx + 170, 170), Color(0.33, 0.33, 0.33), 5.0)
    for crowd_index in range(15):
        var sx := 32.0 + float(crowd_index) * 87.0
        var sy := 412.0 + float(crowd_index % 3) * 11.0
        draw_circle(Vector2(sx, sy - 38.0), 17.0, Color(0.065, 0.065, 0.065))
        draw_rect(Rect2(sx - 22.0, sy - 20.0, 44.0, 67.0), Color(0.065, 0.065, 0.065))
    draw_rect(Rect2(0, 480, 1280, 240), Color(0.22, 0.22, 0.22))
    draw_line(Vector2(0, 480), Vector2(1280, 480), Color(0.5, 0.5, 0.5), 4.0)
    for x in range(0, 1280, 80):
        draw_line(Vector2(x, 480), Vector2(x - 110, 720), Color(0.32, 0.32, 0.32), 1.0)
    _draw_fighter(hacker, Color(0.88, 0.88, 0.88))
    _draw_fighter(chico, Color(0.55, 0.55, 0.55))
    if hit_effect_time > 0.0:
        var strength := hit_effect_time / 0.18
        draw_arc(hit_effect_position, 24.0 + (1.0 - strength) * 18.0, 0.0, TAU, 20, Color(1.0, 0.94, 0.75, strength), 4.0)
        draw_line(hit_effect_position + Vector2(-32, -25), hit_effect_position + Vector2(32, 25), Color(1.0, 1.0, 1.0, strength), 3.0)
    draw_set_transform(Vector2.ZERO)

func _update_combo(hits: int) -> void:
    if combo_label != null:
        combo_label.text = "COMBO x%d" % hits if hits >= 2 else ""

func _record_event(actor: String, event_name: String, move_id: String) -> void:
    var technique := str(MOVE_LABELS.get(move_id, move_id))
    var entry := "%s: %s %s" % [actor, str(EVENT_LABELS.get(event_name, event_name)), technique]
    event_history.append({"time": snappedf(elapsed_seconds, 0.01), "fighter": actor, "event": event_name, "move": move_id})
    var stats: Dictionary = fighter_stats[actor]
    match event_name:
        "hit_confirmed":
            stats["hits"] += 1
        "combo_hit":
            stats["hits"] += 1
            stats["combos"] += 1
        "perfect_dodge":
            stats["dodges"] += 1
        "perfect_parry":
            stats["parries"] += 1
        "counter_hit":
            stats["counters"] += 1
    combat_feed.push_front(entry)
    if combat_feed.size() > 4:
        combat_feed.pop_back()
    if feed_label != null:
        feed_label.text = "\n".join(combat_feed)

func _on_confirmed_hit(move_id: String, target: CondenaFighter) -> void:
    hit_effect_position = target.position + Vector2(0, -48)
    hit_effect_time = 0.18
    hit_effect_label = move_id
    camera_impact = 0.15
    camera_impact_strength = 10.0 if move_id == "cross" or move_id == "takedown" else 5.0
    impact_direction = target.facing

func _draw_fighter(fighter: CondenaFighter, tint: Color) -> void:
    var p := fighter.position
    var recoil := -fighter.facing * 12.0 * (fighter.hit_reaction_time / 0.24)
    p.x += recoil
    if fighter.knockdown_time > 0.0 and not fighter.dead:
        draw_rect(Rect2(p.x - 44, p.y + 26, 88, 20), tint)
        return
    if fighter.dead:
        draw_rect(Rect2(p.x - 48, p.y + 35, 96, 22), tint)
        return

    # Silueta legible en movimiento: guardia alta, amague y golpe son distinguibles.
    var forward := fighter.facing
    var reach_pose := 0.0
    var kick_pose := fighter.active_move_id == "low_kick"
    var takedown_pose := fighter.active_move_id == "takedown"
    var animation_phase := 0.0
    if fighter.busy and fighter.attack_kind != "":
        var move_data: Dictionary = CondenaFighter.MOVE_DATA.get(fighter.active_move_id, {})
        var duration := float(move_data.get("duration", 0.35))
        animation_phase = clampf(1.0 - fighter.attack_pose_time / maxf(0.01, duration), 0.0, 1.0)
        var extension := sin(animation_phase * PI)
        reach_pose = (55.0 if fighter.attack_kind == "heavy" else 38.0) * extension
        if fighter.attack_kind == "grab":
            reach_pose = 18.0 * extension
    elif fighter.feint_window > 0.0:
        reach_pose = 23.0 * sin((1.0 - fighter.feint_window / 0.18) * PI)
    if fighter.invulnerable:
        draw_arc(p + Vector2(0, -40), 75.0, 0.0, TAU, 24, Color(0.8, 0.8, 0.8, 0.5), 2.0)
    if fighter.parry_window > 0.0:
        draw_arc(p + Vector2(0, -70), 66.0, -PI * 0.8, PI * 0.4, 24, Color(1.0, 1.0, 1.0, 0.9), 5.0)
    if fighter.counter_window > 0.0:
        draw_arc(p + Vector2(0, -43), 67.0, -PI * 0.7, PI * 0.2, 22, Color(1.0, 0.9, 0.65), 3.0)

    draw_circle(p + Vector2(0, -100), 26, tint)
    draw_rect(Rect2(p.x - 28, p.y - 72, 56, 100), tint)
    var walking := absf(fighter.velocity.x) > 15.0
    var step_phase := sin(Time.get_ticks_msec() * 0.015) * 12.0 if walking else 0.0
    draw_line(p + Vector2(-15, 25), p + Vector2(-25 + step_phase, 62), tint, 15)
    if kick_pose:
        draw_line(p + Vector2(15, 25), p + Vector2(forward * (35.0 + reach_pose), 25.0), tint, 15)
    elif takedown_pose:
        draw_line(p + Vector2(15, 25), p + Vector2(forward * (25.0 + reach_pose), 53.0), tint, 15)
    else:
        draw_line(p + Vector2(15, 25), p + Vector2(25 - step_phase, 62), tint, 15)
    if fighter.blocking:
        draw_line(p + Vector2(-22, -55), p + Vector2(-13, -110), tint, 12)
        draw_line(p + Vector2(22, -55), p + Vector2(13, -110), tint, 12)
    else:
        var shoulder := p + Vector2(forward * 23.0, -52)
        var fist := p + Vector2(forward * (48.0 + reach_pose), -54)
        draw_line(shoulder, fist, tint, 13)
        draw_circle(fist, 8.0, tint)
        draw_line(p + Vector2(-forward * 23.0, -53), p + Vector2(-forward * 42.0, -12), tint, 12)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(ui)
    health_label = Label.new()
    health_label.position = Vector2(36, 25)
    health_label.add_theme_font_size_override("font_size", 22)
    ui.add_child(health_label)
    enemy_label = Label.new()
    enemy_label.text = "EL CHICO"
    enemy_label.position = Vector2(1130, 25)
    enemy_label.add_theme_font_size_override("font_size", 22)
    ui.add_child(enemy_label)
    player_health_bar = _meter(ui, Vector2(36, 61), Vector2(310, 19), Color(0.88, 0.88, 0.88))
    player_stamina_bar = _meter(ui, Vector2(36, 85), Vector2(310, 12), Color(0.66, 0.66, 0.66))
    enemy_health_bar = _meter(ui, Vector2(934, 61), Vector2(310, 19), Color(0.88, 0.88, 0.88))
    enemy_stamina_bar = _meter(ui, Vector2(934, 85), Vector2(310, 12), Color(0.66, 0.66, 0.66))
    status_label = Label.new()
    status_label.position = Vector2(435, 100)
    status_label.add_theme_font_size_override("font_size", 30)
    ui.add_child(status_label)
    timer_label = Label.new()
    timer_label.position = Vector2(604, 25)
    timer_label.add_theme_font_size_override("font_size", 28)
    timer_label.text = "00:00"
    ui.add_child(timer_label)
    tutorial_label = Label.new()
    tutorial_label.position = Vector2(340, 265)
    tutorial_label.size = Vector2(600, 65)
    tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tutorial_label.text = "Lee al rival: bloqueo pierde ante agarre; parada pierde ante agarre.\nAmaga para provocar errores y castiga las esquivas."
    tutorial_label.add_theme_font_size_override("font_size", 19)
    ui.add_child(tutorial_label)
    feed_label = Label.new()
    feed_label.position = Vector2(38, 117)
    feed_label.add_theme_font_size_override("font_size", 15)
    ui.add_child(feed_label)
    combo_label = Label.new()
    combo_label.position = Vector2(520, 170)
    combo_label.add_theme_font_size_override("font_size", 34)
    ui.add_child(combo_label)
    _button(ui, "◀", Vector2(38, 570), Vector2(92, 100), func(): movement = -1.0, func(): movement = 0.0)
    _button(ui, "▶", Vector2(143, 570), Vector2(92, 100), func(): movement = 1.0, func(): movement = 0.0)
    start_button = _button(ui, "INICIAR COMBATE", Vector2(460, 345), Vector2(360, 75), func(): _start_combat())
    start_button.add_theme_font_size_override("font_size", 25)
    duel_mode_button = _button(ui, "RIVAL: IA (CAMBIAR)", Vector2(460, 430), Vector2(360, 60), func(): _toggle_duel_mode())
    restart_button = _button(ui, "REPETIR COMBATE", Vector2(460, 350), Vector2(360, 75), func(): get_tree().reload_current_scene())
    restart_button.hide()
    technique_buttons["light"] = _button(ui, "JAB", Vector2(875, 590), Vector2(110, 70), func(): hacker.quick_attack())
    technique_buttons["heavy"] = _button(ui, "CROSS", Vector2(995, 510), Vector2(110, 70), func(): hacker.heavy_attack())
    _button(ui, "ESQUIVA", Vector2(1120, 590), Vector2(120, 70), func(): _try_dodge())
    technique_buttons["grapple"] = _button(ui, "CLINCH", Vector2(620, 590), Vector2(110, 70), func(): hacker.grab_attack())
    loadout_label = Label.new()
    loadout_label.position = Vector2(300, 535)
    loadout_label.add_theme_font_size_override("font_size", 17)
    ui.add_child(loadout_label)
    loadout_button = _button(ui, "CAMBIAR TÉCNICAS", Vector2(300, 585), Vector2(290, 65), func(): _cycle_loadout())
    _button(ui, "AMAGUE", Vector2(500, 500), Vector2(115, 65), func(): _try_feint())
    _button(ui, "PARADA", Vector2(875, 505), Vector2(110, 70), func(): _try_parry())
    _button(ui, "BLOQUEO", Vector2(745, 510), Vector2(120, 70), func(): _set_player_block(true), func(): _set_player_block(false))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event: InputEventKey = event
    if key_event.echo:
        return
    if key_event.keycode == KEY_SHIFT:
        if match_started and not match_over:
            hacker.set_block(key_event.pressed)
        return
    if key_event.keycode == KEY_0 and local_duel and match_started and not match_over:
        chico.set_block(key_event.pressed)
        return
    if not key_event.pressed:
        return
    if key_event.keycode == KEY_V and match_started and not match_over:
        broadcast_view = not broadcast_view
        for action_button in action_buttons:
            if action_button != start_button and action_button != loadout_button and action_button != restart_button:
                action_button.visible = not broadcast_view
        return
    if not match_started:
        if key_event.keycode == KEY_ENTER:
            _start_combat()
        return
    if match_over:
        return
    if local_duel:
        match key_event.keycode:
            KEY_1:
                chico.quick_attack()
            KEY_2:
                chico.heavy_attack()
            KEY_3:
                chico.grab_attack()
            KEY_4:
                chico.dodge()
            KEY_5:
                chico.parry()
            KEY_6:
                chico.feint()
    match key_event.keycode:
        KEY_J:
            hacker.quick_attack()
        KEY_K:
            hacker.heavy_attack()
        KEY_L:
            hacker.grab_attack()
        KEY_SPACE:
            hacker.dodge()
        KEY_F:
            hacker.parry()
        KEY_E:
            hacker.feint()

func _toggle_duel_mode() -> void:
    if match_started or match_over:
        return
    local_duel = not local_duel
    duel_mode_button.text = "RIVAL: JUGADOR 2" if local_duel else "RIVAL: IA (CAMBIAR)"
    tutorial_label.text = "DUELO LOCAL: P1 A/D + J/K/L + F/E/ESPACIO; P2 FLECHAS + 1/2/3 + 4/5/6" if local_duel else "Lee al rival: bloqueo pierde ante agarre; parada pierde ante agarre.\nAmaga para provocar errores y castiga las esquivas."

func _try_dodge() -> void:
    if match_started and not match_over:
        hacker.dodge()

func _set_player_block(value: bool) -> void:
    hacker.set_block(value and match_started and not match_over)

func _try_parry() -> void:
    if match_started and not match_over:
        hacker.parry()

func _try_feint() -> void:
    if match_started and not match_over:
        hacker.feint()

func _start_combat() -> void:
    if match_started or match_over:
        return
    match_started = true
    start_button.hide()
    loadout_button.hide()
    duel_mode_button.hide()
    tutorial_label.hide()
    combat_ai.set_physics_process(not local_duel)

func _cycle_loadout() -> void:
    if match_started or match_over or hacker.busy:
        return
    var alternate := hacker.equipped_moves["light"] == "jab"
    hacker.equip_move("light", "low_kick" if alternate else "jab")
    hacker.equip_move("heavy", "elbow" if alternate else "cross")
    hacker.equip_move("grapple", "takedown" if alternate else "clinch")
    _refresh_loadout_label()

func _refresh_loadout_label() -> void:
    loadout_label.text = "Técnicas: %s / %s / %s" % [hacker.equipped_moves["light"], hacker.equipped_moves["heavy"], hacker.equipped_moves["grapple"]]
    for slot in technique_buttons:
        var move_id: String = str(hacker.equipped_moves[slot])
        var cost: int = int(CondenaFighter.MOVE_DATA[move_id]["cost"])
        technique_buttons[slot].text = "%s\n%d RES." % [MOVE_LABELS[move_id], cost]

func _meter(parent: Control, pos: Vector2, size: Vector2, fill_color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = pos
    bar.size = size
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var background_style := StyleBoxFlat.new()
    background_style.bg_color = Color(0.15, 0.15, 0.15, 0.85)
    var fill_style := StyleBoxFlat.new()
    fill_style.bg_color = fill_color
    bar.add_theme_stylebox_override("background", background_style)
    bar.add_theme_stylebox_override("fill", fill_style)
    parent.add_child(bar)
    return bar

func _button(parent: Control, caption: String, pos: Vector2, size: Vector2, pressed_action: Callable, released_action: Callable = Callable()) -> Button:
    var b := Button.new()
    b.text = caption
    b.position = pos
    b.size = size
    b.modulate.a = 0.88
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.button_down.connect(pressed_action)
    if released_action.is_valid():
        b.button_up.connect(released_action)
    parent.add_child(b)
    action_buttons.append(b)
    return b

func _finish(won: bool) -> void:
    match_over = true
    combat_ai.set_physics_process(false)
    hacker.set_direction(0.0)
    chico.set_direction(0.0)
    status_label.text = "GANASTE" if won else "PERDISTE"
    var winner := "HACKER" if won else "EL CHICO"
    var stats: Dictionary = fighter_stats[winner]
    status_label.text += " — La historia continúa"
    status_label.text += "\n%s: %d impactos · %d combos · %d esquivas · %d paradas · %d contras" % [winner, int(stats["hits"]), int(stats["combos"]), int(stats["dodges"]), int(stats["parries"]), int(stats["counters"])]
    restart_button.show()
    broadcast_view = false
    _save_match_record(winner)


func _save_match_record(winner: String) -> void:
    # Solo se guarda un JSON local, sin red, cuentas ni analitica remota.
    var record := {
        "schema_version": 1,
        "game": "CONDENA",
        "winner": winner,
        "duration_seconds": snappedf(elapsed_seconds, 0.01),
        "mode": "local_duel" if local_duel else "vs_ai",
        "stats": fighter_stats,
        "events": event_history
    }
    var file := FileAccess.open("user://condena_last_match.json", FileAccess.WRITE)
    if file == null:
        push_warning("No se pudo guardar el registro local del combate")
        return
    file.store_string(JSON.stringify(record, "\t"))
    file.close()
    match_export_path = ProjectSettings.globalize_path("user://condena_last_match.json")
