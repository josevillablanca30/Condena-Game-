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
var combat_ai: Node
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
const ROUND_LIMIT_SECONDS := 90.0
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
var match_result := ""
var campaign_bridge: CampaignBridge
var campaign_mode := false
var campaign_button: Button
var selection := preload("res://src/ui/technique_select.gd").new()
var hud := CanvasLayer.new()
var continue_chapter := false
var prepared := false
var trigger_down := false
var story_screen: CondenaStoryScreen
var mobile_touch_actions: Dictionary = {}
var mobile_movement_touches: Dictionary = {}
var mobile_guard_touches: Dictionary = {}

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
    campaign_bridge = CampaignBridge.new()
    add_child(campaign_bridge)
    _build_ui()
    story_screen = CondenaStoryScreen.new()
    var story_layer := CanvasLayer.new()
    story_layer.layer = 10
    add_child(story_layer)
    story_layer.add_child(story_screen)
    story_layer.add_child(selection)
    selection.visibility_changed.connect(_sync_hud)
    story_screen.visibility_changed.connect(_sync_hud)
    selection.confirmed.connect(_confirm_techniques)
    story_screen.scene_finished.connect(_on_story_scene_finished)
    story_screen.save_choice = campaign_bridge.campaign.record_choice
    var saved: Dictionary = SaveSystemV2.load_profile().get("techniques", {})
    for slot in CondenaFighter.MOVE_SLOTS:
        if saved.has(slot):
            hacker.equip_move(slot, str(saved[slot]))
    _refresh_loadout_label()
    campaign_mode = bool(SaveSystemV2.load_profile().get("campaign_active", true))
    if campaign_mode:
        campaign_button.text = "CAMPAÑA: ACTIVADA"
        var status := campaign_bridge.current_status()
        tutorial_label.text = "CAPÍTULO 1 — ESCENA %d/9" % mini(9, int(status["scene"]) + 1)
    combat_ai = AIElChico.new()
    combat_ai.set("fighter", chico)
    combat_ai.set("target", hacker)
    add_child(combat_ai)
    combat_ai.set_physics_process(false)
    for b in action_buttons:
        b.visible = b in [start_button, duel_mode_button, campaign_button, loadout_button]
    start_button.text = "CONTINUAR CAMPAÑA" if campaign_mode else "INICIAR COMBATE"
    loadout_label.hide()
    loadout_button.visible = not campaign_mode
    start_button.grab_focus()
    if campaign_mode and get_tree().get_meta("resume_condena", false):
        get_tree().remove_meta("resume_condena")
        _open_campaign_step()
    queue_redraw()

func _sync_hud() -> void:
    hud.visible = not selection.visible and not story_screen.visible

func _input(event: InputEvent) -> void:
    if match_started and not match_over and _handle_pad(event):
        get_viewport().set_input_as_handled()
        return
    if not OS.has_feature("android") or not match_started or match_over:
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        var location := _touch_to_viewport(touch.position)
        if touch.pressed:
            _begin_mobile_touch(touch.index, location)
        else:
            _end_mobile_touch(touch.index)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        var location := _touch_to_viewport(drag.position)
        if mobile_movement_touches.has(drag.index):
            mobile_movement_touches[drag.index] = _movement_at(location)
            _refresh_mobile_direction()

func _handle_pad(event: InputEvent) -> bool:
    if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
        if event.axis_value > 0.55 and not trigger_down:
            hacker.grab_attack()
        trigger_down = event.axis_value > 0.55
        return true
    if not event is InputEventJoypadButton:
        return false
    if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
        hacker.set_block(event.pressed)
    elif event.pressed:
        match event.button_index:
            JOY_BUTTON_A: hacker.basic_attack()
            JOY_BUTTON_RIGHT_STICK: hacker.basic_heavy()
            JOY_BUTTON_X: hacker.quick_attack()
            JOY_BUTTON_Y: hacker.heavy_attack()
            JOY_BUTTON_B: hacker.dodge()
            JOY_BUTTON_RIGHT_SHOULDER: hacker.parry()
            JOY_BUTTON_LEFT_STICK: hacker.feint()
    return true

func _touch_to_viewport(screen_point: Vector2) -> Vector2:
    return get_viewport().get_canvas_transform().affine_inverse() * screen_point

func _movement_at(point: Vector2) -> float:
    if Rect2(38, 570, 92, 100).has_point(point):
        return -1.0
    if Rect2(143, 570, 92, 100).has_point(point):
        return 1.0
    return 0.0

func _begin_mobile_touch(index: int, point: Vector2) -> void:
    if point.x < 250.0 and point.y > 540.0:
        mobile_movement_touches[index] = _movement_at(point)
        _refresh_mobile_direction()
        return
    if Rect2(745, 510, 120, 70).has_point(point):
        mobile_guard_touches[index] = true
        hacker.set_block(true)
        return
    var regions := [
        {"rect": Rect2(875, 590, 110, 70), "action": "light"},
        {"rect": Rect2(995, 510, 110, 70), "action": "heavy"},
        {"rect": Rect2(620, 590, 110, 70), "action": "grapple"},
        {"rect": Rect2(1120, 590, 120, 70), "action": "dodge"},
        {"rect": Rect2(875, 505, 110, 70), "action": "parry"},
        {"rect": Rect2(500, 500, 115, 65), "action": "feint"}
    ]
    for region in regions:
        if region["rect"].has_point(point):
            mobile_touch_actions[index] = region["action"]
            match str(region["action"]):
                "light": hacker.quick_attack()
                "heavy": hacker.heavy_attack()
                "grapple": hacker.grab_attack()
                "dodge": hacker.dodge()
                "parry": hacker.parry()
                "feint": hacker.feint()
            return

func _end_mobile_touch(index: int) -> void:
    mobile_touch_actions.erase(index)
    mobile_movement_touches.erase(index)
    mobile_guard_touches.erase(index)
    _refresh_mobile_direction()
    if mobile_guard_touches.is_empty():
        hacker.set_block(false)

func _refresh_mobile_direction() -> void:
    movement = 0.0
    for value in mobile_movement_touches.values():
        movement += float(value)
    movement = clampf(movement, -1.0, 1.0)

func _process(delta: float) -> void:
    hit_effect_time = maxf(0.0, hit_effect_time - delta)
    camera_impact = maxf(0.0, camera_impact - delta)
    if match_started and not match_over:
        elapsed_seconds += delta
        var remaining := maxi(0, int(ceil(ROUND_LIMIT_SECONDS - elapsed_seconds)))
        timer_label.text = "R1  %02d:%02d" % [int(remaining / 60.0), remaining % 60]
        if elapsed_seconds >= ROUND_LIMIT_SECONDS:
            var player_fraction := hacker.health / maxf(1.0, hacker.max_health)
            var rival_fraction := chico.health / maxf(1.0, chico.max_health)
            if absf(player_fraction - rival_fraction) <= 0.001:
                _finish_draw()
            else:
                _finish(player_fraction > rival_fraction)
            return
    if match_over:
        return
    var keyboard_direction := 0.0
    if Input.is_key_pressed(KEY_A) or (not local_duel and Input.is_key_pressed(KEY_LEFT)):
        keyboard_direction -= 1.0
    if Input.is_key_pressed(KEY_D) or (not local_duel and Input.is_key_pressed(KEY_RIGHT)):
        keyboard_direction += 1.0
    var pads := Input.get_connected_joypads()
    if not pads.is_empty():
        var axis := Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X)
        if absf(axis) > 0.2:
            keyboard_direction += axis
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
        button.disabled = not match_started or match_over or not hacker.can_attack(cost)
    queue_redraw()

func _draw() -> void:
    var camera_shift := Vector2(impact_direction * camera_impact_strength * camera_impact / 0.15, 0.0)
    draw_set_transform(camera_shift)
    # Patio de condenados: profundidad, hormigon, rejas y luz dramatica.
    draw_rect(Rect2(0, 0, 1280, 720), Color("#111519"))
    draw_rect(Rect2(0, 0, 1280, 472), Color("#22272a"))
    for stripe in range(16):
        var sy := float(stripe) * 32.0
        draw_line(Vector2(0, sy), Vector2(1280, sy), Color("#2e3437"), 1.0)
    for column in range(11):
        var cx := float(column) * 128.0
        draw_rect(Rect2(cx, 0, 10, 468), Color("#191d20"))
        draw_line(Vector2(cx + 10, 0), Vector2(cx + 10, 468), Color("#454a4b"), 2.0)
    # Ventanales altos, barrotes y luz inclinada desde el corredor.
    for window_index in range(4):
        var wx := 95.0 + float(window_index) * 312.0
        draw_rect(Rect2(wx - 10, 48, 184, 218), Color("#121518"))
        draw_rect(Rect2(wx, 57, 164, 192), Color("#080b0e"))
        for bar_index in range(6):
            var bx := wx + 12.0 + float(bar_index) * 28.0
            draw_line(Vector2(bx, 57), Vector2(bx, 249), Color("#687071"), 6.0)
            draw_line(Vector2(bx - 2, 57), Vector2(bx - 2, 249), Color("#24292c"), 2.0)
        draw_line(Vector2(wx, 158), Vector2(wx + 164, 158), Color("#6b7170"), 7.0)
        draw_line(Vector2(wx - 10, 259), Vector2(wx + 174, 259), Color("#0b0d0f"), 10.0)
    for lamp in range(3):
        var lx := 190.0 + float(lamp) * 445.0
        draw_rect(Rect2(lx - 38, 7, 76, 13), Color("#080b0c"))
        draw_rect(Rect2(lx - 25, 20, 50, 7), Color("#a99b72"))
        draw_colored_polygon(PackedVector2Array([Vector2(lx - 24, 27), Vector2(lx + 24, 27), Vector2(lx + 160, 452), Vector2(lx - 160, 452)]), Color(0.71, 0.63, 0.44, 0.045))
    # Reclusos al fondo; siluetas a distintas alturas.
    for crowd_index in range(16):
        var sx := 22.0 + float(crowd_index) * 83.0
        var sy := 418.0 + float(crowd_index % 4) * 8.0
        var shadow := Color("#0c1012") if crowd_index % 3 else Color("#14191b")
        draw_circle(Vector2(sx, sy - 46), 16.0, shadow)
        draw_colored_polygon(PackedVector2Array([Vector2(sx - 19, sy - 27), Vector2(sx + 19, sy - 27), Vector2(sx + 28, 469), Vector2(sx - 28, 469)]), shadow)
    draw_rect(Rect2(0, 457, 1280, 19), Color("#0d1012"))
    draw_line(Vector2(0, 457), Vector2(1280, 457), Color("#656969"), 3.0)
    draw_colored_polygon(PackedVector2Array([Vector2(0, 476), Vector2(1280, 476), Vector2(1280, 720), Vector2(0, 720)]), Color("#34383a"))
    for depth in range(1, 7):
        var fy := 476.0 + pow(float(depth) / 6.0, 1.6) * 244.0
        draw_line(Vector2(0, fy), Vector2(1280, fy), Color("#494c4b"), 1.0 + float(depth) * 0.25)
    for floor_line in range(-8, 20):
        var foot_x := float(floor_line) * 116.0
        draw_line(Vector2(640.0 + (foot_x - 640.0) * 0.32, 476), Vector2(foot_x, 720), Color("#4b4d4c"), 1.0)
    draw_rect(Rect2(0, 470, 1280, 6), Color("#171b1d"))
    # Sombras de contacto para anclar los luchadores al suelo.
    for fighter in [hacker, chico]:
        var shadow_x: float = fighter.position.x
        draw_colored_polygon(PackedVector2Array([Vector2(shadow_x - 54, 486), Vector2(shadow_x + 54, 486), Vector2(shadow_x + 94, 505), Vector2(shadow_x - 94, 505)]), Color(0, 0, 0, 0.32))
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
    var technique := str(CondenaFighter.MOVE_LABELS.get(move_id, move_id))
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

    # Personajes originales dibujados por capas: anatomia, ropa y expresiones.
    var is_hacker := fighter == hacker
    var skin := Color("#c5a28b") if is_hacker else Color("#927466")
    var cloth := Color("#353d43") if is_hacker else Color("#656058")
    var cloth_dark := Color("#1c2429") if is_hacker else Color("#34302e")
    var ink := Color("#0a0b0e")
    var accent := Color("#b8a489") if is_hacker else Color("#8c3c32")
    var step_phase := sin(Time.get_ticks_msec() * 0.015) * 11.0 if absf(fighter.velocity.x) > 15.0 else 0.0
    var crouch := 19.0 if fighter.knockdown_time > 0.0 else 0.0
    var upper := p + Vector2(0, crouch)
    # Piernas con volumen y botas, separadas para leer la caminata.
    var rear_foot := upper + Vector2(-20.0 - step_phase, 61.0)
    var front_foot := upper + Vector2(23.0 + step_phase, 61.0)
    if kick_pose:
        front_foot = upper + Vector2(forward * (52.0 + reach_pose), 5.0)
    elif takedown_pose:
        front_foot = upper + Vector2(forward * 49.0, 54.0)
    draw_line(upper + Vector2(-13, 14), rear_foot, ink, 21.0)
    draw_line(upper + Vector2(13, 14), front_foot, ink, 21.0)
    draw_line(upper + Vector2(-13, 14), rear_foot, cloth_dark, 15.0)
    draw_line(upper + Vector2(13, 14), front_foot, cloth_dark, 15.0)
    draw_line(rear_foot + Vector2(-8, 0), rear_foot + Vector2(11, 0), ink, 12.0)
    draw_line(front_foot + Vector2(-8, 0), front_foot + Vector2(12, 0), ink, 12.0)
    # Chaqueta de presidiario y torso sombreado.
    draw_colored_polygon(PackedVector2Array([
        upper + Vector2(-30, -69), upper + Vector2(30, -69),
        upper + Vector2(33, 22), upper + Vector2(-33, 22)
    ]), ink)
    draw_colored_polygon(PackedVector2Array([
        upper + Vector2(-26, -65), upper + Vector2(26, -65),
        upper + Vector2(29, 17), upper + Vector2(-29, 17)
    ]), cloth)
    draw_line(upper + Vector2(0, -62), upper + Vector2(0, 15), cloth_dark, 4.0)
    draw_line(upper + Vector2(-24, -34), upper + Vector2(23, -34), cloth_dark, 3.0)
    draw_rect(Rect2(upper.x - 21, upper.y - 12, 42, 5), accent)
    # Cuello, oreja, craneo y cabello en silueta.
    draw_rect(Rect2(upper.x - 10, upper.y - 83, 20, 17), ink)
    draw_rect(Rect2(upper.x - 8, upper.y - 83, 16, 17), skin)
    draw_circle(upper + Vector2(0, -105), 28.0, ink)
    draw_circle(upper + Vector2(0, -105), 24.0, skin)
    draw_colored_polygon(PackedVector2Array([
        upper + Vector2(-25, -113), upper + Vector2(-19, -134),
        upper + Vector2(2, -138), upper + Vector2(24, -127),
        upper + Vector2(26, -111), upper + Vector2(12, -121),
        upper + Vector2(-7, -122)
    ]), ink)
    if not is_hacker:
        draw_rect(Rect2(upper.x - 21, upper.y - 100, 43, 8), ink)
        draw_line(upper + Vector2(-11, -89), upper + Vector2(15, -89), ink, 3.0)
    # Nariz y ceja orientadas al adversario.
    draw_line(upper + Vector2(forward * 9, -111), upper + Vector2(forward * 19, -111), ink, 3.0)
    draw_line(upper + Vector2(forward * 20, -105), upper + Vector2(forward * 27, -101), ink, 2.0)
    draw_line(upper + Vector2(forward * 8, -94), upper + Vector2(forward * 19, -95), cloth_dark, 2.0)
    # Guardia y golpes: extremidades articuladas con contorno oscuro.
    var shoulder_front := upper + Vector2(forward * 24.0, -54)
    var elbow_front := upper + Vector2(forward * (37.0 + reach_pose * 0.48), -57)
    var fist_front := upper + Vector2(forward * (42.0 + reach_pose), -78 if fighter.blocking else -53)
    var shoulder_back := upper + Vector2(-forward * 24.0, -55)
    var elbow_back := upper + Vector2(-forward * 36.0, -27)
    var fist_back := upper + Vector2(-forward * 12.0, -91 if fighter.blocking else -43)
    for segment in [[shoulder_back, elbow_back], [elbow_back, fist_back], [shoulder_front, elbow_front], [elbow_front, fist_front]]:
        draw_line(segment[0], segment[1], ink, 19.0)
        draw_line(segment[0], segment[1], cloth, 13.0)
    draw_circle(fist_front, 11.0, ink)
    draw_circle(fist_front, 8.0, skin)
    draw_circle(fist_back, 10.0, ink)
    draw_circle(fist_back, 7.0, skin)
    # Tintas de luz de borde para separar al personaje del fondo.
    draw_line(upper + Vector2(-26, -59), upper + Vector2(-27, 11), Color(0.82, 0.77, 0.66, 0.35), 2.0)

func _build_ui() -> void:
    add_child(hud)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(ui)
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
    timer_label.text = "R1  01:30"
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
    campaign_button = _button(ui, "CAMPAÑA: DESACTIVADA", Vector2(460, 500), Vector2(360, 55), func(): _toggle_campaign())
    restart_button = _button(ui, "REPETIR COMBATE", Vector2(460, 350), Vector2(360, 75), _restart_or_continue)
    restart_button.hide()
    technique_buttons["light"] = _button(ui, "JAB", Vector2(875, 590), Vector2(110, 70), func(): hacker.quick_attack())
    technique_buttons["heavy"] = _button(ui, "CROSS", Vector2(995, 510), Vector2(110, 70), func(): hacker.heavy_attack())
    _button(ui, "ESQUIVA", Vector2(1120, 590), Vector2(120, 70), func(): _try_dodge())
    technique_buttons["grapple"] = _button(ui, "CLINCH", Vector2(620, 590), Vector2(110, 70), func(): hacker.grab_attack())
    loadout_label = Label.new()
    loadout_label.position = Vector2(300, 535)
    loadout_label.add_theme_font_size_override("font_size", 17)
    ui.add_child(loadout_label)
    loadout_button = _button(ui, "CAMBIAR TÉCNICAS", Vector2(460, 580), Vector2(360, 60), func(): _cycle_loadout())
    _button(ui, "AMAGUE", Vector2(500, 500), Vector2(115, 65), func(): _try_feint())
    _button(ui, "PARADA", Vector2(875, 505), Vector2(110, 70), func(): _try_parry())
    _button(ui, "BLOQUEO", Vector2(745, 510), Vector2(120, 70), func(): _set_player_block(true), func(): _set_player_block(false))

func _unhandled_key_input(event: InputEvent) -> void:
    if story_screen.visible or selection.visible or not event is InputEventKey:
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
            if action_button not in [start_button, loadout_button, restart_button, campaign_button, duel_mode_button]:
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
        KEY_U:
            hacker.basic_heavy()
        KEY_H:
            hacker.basic_attack()
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

func _open_campaign_step() -> void:
    var status := campaign_bridge.current_status()
    if bool(status["finished"]):
        status_label.text = "CAPÍTULO 1 COMPLETADO"
        return
    var scene_number := int(status["scene"]) + 1
    if int(status["fight_index"]) >= 0:
        if scene_number == 5 and not campaign_bridge.campaign.choices.has("flaco"):
            story_screen.present("ESCENA 05 — LA SEGUNDA PRUEBA", CondenaChapterOneScript.lines_for(4))
            return
        _start_combat()
        return
    var lines := CondenaChapterOneScript.lines_for(scene_number - 1)
    if scene_number == 1:
        lines[0]["ambience"] = true
        lines.insert(1, {"clip": 0})
    elif scene_number == 2:
        lines.push_front({"clip": 1})
    story_screen.present("CAPÍTULO 1 — EL POLLO | %s" % CondenaChapterOneScript.title_for(scene_number - 1),
        lines)

func _on_story_scene_finished() -> void:
    if not campaign_mode:
        return
    if campaign_bridge.campaign.current_fight_index() >= 0:
        _start_combat()
        return
    if campaign_bridge.advance_story_scene():
        var status := campaign_bridge.current_status()
        status_label.text = "ESCENA COMPLETADA — PROGRESO GUARDADO"
        if bool(status["finished"]):
            status_label.text = "CAPÍTULO 1 COMPLETADO"
        else:
            _open_campaign_step()

func _toggle_campaign() -> void:
    if match_started or match_over:
        return
    campaign_mode = not campaign_mode
    loadout_button.visible = not campaign_mode
    if campaign_mode:
        local_duel = false
        duel_mode_button.text = "RIVAL: IA"
    start_button.text = "CONTINUAR CAMPAÑA" if campaign_mode else "INICIAR COMBATE"
    campaign_button.text = "CAMPAÑA: ACTIVADA" if campaign_mode else "CAMPAÑA: DESACTIVADA"
    var profile := SaveSystemV2.load_profile()
    profile["campaign_active"] = campaign_mode
    SaveSystemV2.save_profile(profile)
    var status := campaign_bridge.current_status()
    tutorial_label.text = "Capítulo 1 — escena %d/9. EL POLLO." % (int(status["scene"]) + 1) if campaign_mode else "Lee al rival: bloqueo pierde ante agarre; parada pierde ante agarre."

func _toggle_duel_mode() -> void:
    if match_started or match_over:
        return
    local_duel = not local_duel
    if local_duel and campaign_mode:
        campaign_mode = false
        loadout_button.show()
        start_button.text = "INICIAR COMBATE"
        campaign_button.text = "CAMPAÑA: DESACTIVADA"
        var profile := SaveSystemV2.load_profile()
        profile["campaign_active"] = false
        SaveSystemV2.save_profile(profile)
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

func _select_campaign_ai(index: int) -> void:
    if is_instance_valid(combat_ai):
        combat_ai.set_physics_process(false)
        combat_ai.queue_free()
    match index:
        1:
            combat_ai = AIElFlaco.new()
        2:
            combat_ai = AIPresoGrande.new()
        _:
            combat_ai = AIElChico.new()
    combat_ai.set("fighter", chico)
    combat_ai.set("target", hacker)
    add_child(combat_ai)
    combat_ai.set_physics_process(false)

func _start_combat() -> void:
    if match_started or match_over:
        return
    if campaign_mode and (campaign_bridge.campaign.current_fight_index() < 0 or (campaign_bridge.campaign.scene_index == 4 and not campaign_bridge.campaign.choices.has("flaco"))):
        _open_campaign_step()
        return
    if not prepared:
        selection.present(hacker)
        return
    if campaign_mode:
        if not campaign_bridge.start_current_fight(hacker, chico):
            status_label.text = "Completa las escenas narrativas antes del siguiente combate."
            return
        _select_campaign_ai(campaign_bridge.active_fight_index)
        enemy_label.text = chico.fighter_name
        enemy_health_bar.max_value = chico.max_health
        enemy_health_bar.value = chico.health
    match_started = true
    for b in action_buttons:
        b.visible = b != restart_button
        b.focus_mode = Control.FOCUS_NONE
    status_label.text = ""
    start_button.hide()
    loadout_button.hide()
    loadout_label.hide()
    duel_mode_button.hide()
    campaign_button.hide()
    tutorial_label.hide()
    combat_ai.set_physics_process(not local_duel)
    if campaign_mode and campaign_bridge.active_fight_index == 0:
        chico.position.x = hacker.position.x + 118.0
        chico.facing = -1.0
        chico.quick_attack()

func _cycle_loadout() -> void:
    if match_started or match_over or hacker.busy:
        return
    selection.present(hacker)

func _confirm_techniques() -> void:
    var profile := SaveSystemV2.load_profile()
    profile["techniques"] = hacker.equipped_moves.duplicate()
    SaveSystemV2.save_profile(profile)
    prepared = true
    _refresh_loadout_label()
    _start_combat()

func _refresh_loadout_label() -> void:
    loadout_label.text = "Técnicas: %s / %s / %s" % [hacker.equipped_moves["light"], hacker.equipped_moves["heavy"], hacker.equipped_moves["grapple"]]
    for slot in technique_buttons:
        var move_id: String = str(hacker.equipped_moves[slot])
        var cost: int = int(CondenaFighter.MOVE_DATA[move_id]["cost"])
        technique_buttons[slot].text = "%s\n%s · %d" % [CondenaFighter.MOVE_LABELS[move_id], {"light": "J/X", "heavy": "K/Y", "grapple": "L/RT"}[slot], cost]

func _meter(parent: Control, pos: Vector2, size: Vector2, fill_color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = pos
    bar.size = size
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var background_style := StyleBoxFlat.new()
    background_style.bg_color = Color("#101519")
    background_style.border_color = Color("#697276")
    background_style.set_border_width_all(2)
    background_style.set_corner_radius_all(3)
    var fill_style := StyleBoxFlat.new()
    fill_style.bg_color = fill_color
    fill_style.set_corner_radius_all(2)
    bar.add_theme_stylebox_override("background", background_style)
    bar.add_theme_stylebox_override("fill", fill_style)
    parent.add_child(bar)
    return bar

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    style.content_margin_left = 6.0
    style.content_margin_right = 6.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style

func _button(parent: Control, caption: String, pos: Vector2, size: Vector2, pressed_action: Callable, released_action: Callable = Callable()) -> Button:
    var b := Button.new()
    b.text = caption
    b.position = pos
    b.size = size
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color("#f0e9dd"))
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)
    b.add_theme_color_override("font_disabled_color", Color("#8c9091"))
    b.add_theme_stylebox_override("normal", _button_style(Color("#192126"), Color("#667277")))
    b.add_theme_stylebox_override("hover", _button_style(Color("#2a363b"), Color("#a4ada9")))
    b.add_theme_stylebox_override("pressed", _button_style(Color("#6b3430"), Color("#d7a48a")))
    b.add_theme_stylebox_override("disabled", _button_style(Color("#1b2022"), Color("#353c40")))
    b.add_theme_stylebox_override("focus", _button_style(Color("#303030"), Color.WHITE))
    if released_action.is_valid():
        b.button_down.connect(pressed_action)
    else:
        b.pressed.connect(pressed_action)
    if released_action.is_valid():
        b.button_up.connect(released_action)
    parent.add_child(b)
    action_buttons.append(b)
    return b

func _finish_draw() -> void:
    if match_over:
        return
    _finish_match("EMPATE", "EMPATE")

func _finish(won: bool) -> void:
    var winner := "HACKER" if won else "EL CHICO"
    var result_title := ("GANA HACKER" if won else "GANA EL CHICO") if local_duel else ("GANASTE" if won else "PERDISTE")
    _finish_match(winner, result_title)

func _finish_match(winner: String, result_title: String) -> void:
    if match_over:
        return
    match_over = true
    match_result = winner
    mobile_touch_actions.clear()
    mobile_movement_touches.clear()
    mobile_guard_touches.clear()
    movement = 0.0
    hacker.attack_serial += 1
    chico.attack_serial += 1
    hacker.set_physics_process(false)
    chico.set_physics_process(false)
    combat_ai.set_physics_process(false)
    hacker.set_direction(0.0)
    chico.set_direction(0.0)
    status_label.position.x = 80
    status_label.size.x = 1120
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.text = result_title
    if winner != "EMPATE":
        var stats: Dictionary = fighter_stats[winner]
        status_label.text += "\n%s: %d impactos · %d combos · %d esquivas · %d paradas · %d contras" % [winner, int(stats["hits"]), int(stats["combos"]), int(stats["dodges"]), int(stats["parries"]), int(stats["counters"])]
    for action_button in action_buttons:
        if action_button != restart_button:
            action_button.hide()
    hacker.set_block(false)
    chico.set_block(false)
    player_health_bar.value = hacker.health
    enemy_health_bar.value = chico.health
    player_stamina_bar.value = hacker.stamina
    enemy_stamina_bar.value = chico.stamina
    restart_button.show()
    restart_button.focus_mode = Control.FOCUS_ALL
    restart_button.grab_focus()
    broadcast_view = false
    _save_match_record(winner)
    if campaign_mode and winner != "EMPATE":
        var progressed := campaign_bridge.submit_combat_result(winner == "HACKER")
        if progressed:
            restart_button.text = "CONTINUAR CAPÍTULO"
            continue_chapter = true
            if campaign_bridge.campaign.scene_index == 3:
                tutorial_label.text = "El Chico cae abatido contra una mesa. Los presos murmuran. El protagonista queda exhausto." if winner == "HACKER" else "El Chico derriba al protagonista y lo humilla."
                tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                tutorial_label.show()


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

func _restart_or_continue() -> void:
    if continue_chapter:
        get_tree().set_meta("resume_condena", true)
    get_tree().reload_current_scene()
