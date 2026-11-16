extends Node2D

@onready var hacker: CondenaFighter = $Hacker
@onready var chico: CondenaFighter = $Chico

var movement := 0.0
var match_over := false
var ai_cooldown := 0.0
var health_label: Label
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
    "dodge_recovery": "FIN DE ESQUIVA"
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
    if match_over:
        return
    hacker.set_direction(movement if match_started else 0.0)
    # La IA ahora se ejecuta desde AIElChico, sin duplicar ataques.
    health_label.text = "HACKER  %d VIDA | %d RES.            EL CHICO  %d VIDA | %d RES." % [int(hacker.health), int(hacker.stamina), int(chico.health), int(chico.stamina)]
    for slot in technique_buttons:
        var button: Button = technique_buttons[slot]
        var move_id: String = str(hacker.equipped_moves[slot])
        var cost: float = float(CondenaFighter.MOVE_DATA[move_id]["cost"])
        button.disabled = not match_started or match_over or hacker.dead or hacker.busy or hacker.stamina < cost
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.09, 0.09, 0.09))
    draw_rect(Rect2(0, 495, 1280, 225), Color(0.22, 0.22, 0.22))
    for x in range(0, 1280, 80):
        draw_line(Vector2(x, 495), Vector2(x - 110, 720), Color(0.34, 0.34, 0.34), 1.0)
    _draw_fighter(hacker, Color(0.88, 0.88, 0.88))
    _draw_fighter(chico, Color(0.55, 0.55, 0.55))
    if hit_effect_time > 0.0:
        var strength := hit_effect_time / 0.18
        draw_arc(hit_effect_position, 24.0 + (1.0 - strength) * 18.0, 0.0, TAU, 20, Color(1.0, 0.94, 0.75, strength), 4.0)
        draw_line(hit_effect_position + Vector2(-32, -25), hit_effect_position + Vector2(32, 25), Color(1.0, 1.0, 1.0, strength), 3.0)

func _update_combo(hits: int) -> void:
    if combo_label != null:
        combo_label.text = "COMBO x%d" % hits if hits >= 2 else ""

func _record_event(actor: String, event_name: String, move_id: String) -> void:
    var technique := str(MOVE_LABELS.get(move_id, move_id))
    var entry := "%s: %s %s" % [actor, str(EVENT_LABELS.get(event_name, event_name)), technique]
    combat_feed.push_front(entry)
    if combat_feed.size() > 4:
        combat_feed.pop_back()
    if feed_label != null:
        feed_label.text = "\n".join(combat_feed)

func _on_confirmed_hit(move_id: String, target: CondenaFighter) -> void:
    hit_effect_position = target.position + Vector2(0, -48)
    hit_effect_time = 0.18
    hit_effect_label = move_id

func _draw_fighter(fighter: CondenaFighter, tint: Color) -> void:
    var p := fighter.position
    if fighter.knockdown_time > 0.0 and not fighter.dead:
        draw_rect(Rect2(p.x - 44, p.y + 26, 88, 20), tint)
        return
    if fighter.dead:
        draw_rect(Rect2(p.x - 48, p.y + 35, 96, 22), tint)
        return

    # Silueta legible en movimiento: guardia alta, amague y golpe son distinguibles.
    var forward := fighter.facing
    var reach_pose := 0.0
    if fighter.busy and fighter.attack_kind != "":
        reach_pose = 46.0 if fighter.attack_kind == "heavy" else 30.0
    elif fighter.feint_window > 0.0:
        reach_pose = 23.0
    if fighter.invulnerable:
        draw_arc(p + Vector2(0, -40), 75.0, 0.0, TAU, 24, Color(0.8, 0.8, 0.8, 0.5), 2.0)
    if fighter.counter_window > 0.0:
        draw_arc(p + Vector2(0, -43), 67.0, -PI * 0.7, PI * 0.2, 22, Color(1.0, 0.9, 0.65), 3.0)

    draw_circle(p + Vector2(0, -100), 26, tint)
    draw_rect(Rect2(p.x - 28, p.y - 72, 56, 100), tint)
    draw_line(p + Vector2(-15, 25), p + Vector2(-25, 62), tint, 15)
    draw_line(p + Vector2(15, 25), p + Vector2(25, 62), tint, 15)
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
    health_label.add_theme_font_size_override("font_size", 25)
    ui.add_child(health_label)
    status_label = Label.new()
    status_label.position = Vector2(435, 100)
    status_label.add_theme_font_size_override("font_size", 30)
    ui.add_child(status_label)
    feed_label = Label.new()
    feed_label.position = Vector2(38, 85)
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
    technique_buttons["light"] = _button(ui, "JAB", Vector2(875, 590), Vector2(110, 70), func(): hacker.quick_attack())
    technique_buttons["heavy"] = _button(ui, "CROSS", Vector2(995, 510), Vector2(110, 70), func(): hacker.heavy_attack())
    _button(ui, "ESQUIVA", Vector2(1120, 590), Vector2(120, 70), func(): hacker.dodge())
    technique_buttons["grapple"] = _button(ui, "CLINCH", Vector2(620, 590), Vector2(110, 70), func(): hacker.grab_attack())
    loadout_label = Label.new()
    loadout_label.position = Vector2(300, 535)
    loadout_label.add_theme_font_size_override("font_size", 17)
    ui.add_child(loadout_label)
    loadout_button = _button(ui, "CAMBIAR TÉCNICAS", Vector2(300, 585), Vector2(290, 65), func(): _cycle_loadout())
    _button(ui, "AMAGUE", Vector2(500, 500), Vector2(115, 65), func(): _try_feint())
    _button(ui, "BLOQUEO", Vector2(745, 510), Vector2(120, 70), func(): hacker.set_block(true), func(): hacker.set_block(false))

func _try_feint() -> void:
    if match_started and not match_over:
        hacker.feint()

func _start_combat() -> void:
    if match_started or match_over:
        return
    match_started = true
    start_button.hide()
    loadout_button.hide()
    combat_ai.set_physics_process(true)

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
    return b

func _finish(won: bool) -> void:
    match_over = true
    combat_ai.set_physics_process(false)
    hacker.set_direction(0.0)
    chico.set_direction(0.0)
    status_label.text = "GANASTE" if won else "PERDISTE"
    status_label.text += " — La historia continúa"
