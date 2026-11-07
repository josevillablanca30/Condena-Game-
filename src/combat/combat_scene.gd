extends Node2D

@onready var hacker: CondenaFighter = $Hacker
@onready var chico: CondenaFighter = $Chico

var movement := 0.0
var match_over := false
var ai_cooldown := 0.0
var health_label: Label
var status_label: Label

func _ready() -> void:
    hacker.opponent = chico
    chico.opponent = hacker
    hacker.defeated.connect(func(): _finish(false))
    chico.max_health = 620.0
    hacker.max_health = 740.0
    hacker.health = 740.0
    chico.health = 620.0
    chico.defeated.connect(func(): _finish(true))
    _build_ui()
    var ai := AIElChico.new()
    ai.fighter = chico
    ai.target = hacker
    add_child(ai)
    queue_redraw()

func _process(delta: float) -> void:
    if match_over:
        return
    hacker.set_direction(movement)
    # La IA ahora se ejecuta desde AIElChico, sin duplicar ataques.
    health_label.text = "HACKER  %d HP | %d RES.            EL CHICO  %d HP" % [int(hacker.health), int(hacker.stamina), int(chico.health)]
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.09, 0.09, 0.09))
    draw_rect(Rect2(0, 495, 1280, 225), Color(0.22, 0.22, 0.22))
    for x in range(0, 1280, 80):
        draw_line(Vector2(x, 495), Vector2(x - 110, 720), Color(0.34, 0.34, 0.34), 1.0)
    _draw_fighter(hacker, Color(0.88, 0.88, 0.88))
    _draw_fighter(chico, Color(0.55, 0.55, 0.55))

func _draw_fighter(fighter: CondenaFighter, tint: Color) -> void:
    var p := fighter.position
    if fighter.dead:
        draw_rect(Rect2(p.x - 48, p.y + 35, 96, 22), tint)
        return
    draw_circle(p + Vector2(0, -100), 26, tint)
    draw_rect(Rect2(p.x - 28, p.y - 72, 56, 100), tint)
    draw_line(p + Vector2(-15, 25), p + Vector2(-25, 62), tint, 15)
    draw_line(p + Vector2(15, 25), p + Vector2(25, 62), tint, 15)
    draw_line(p + Vector2(-25, -55), p + Vector2(-48, -2), tint, 12)
    draw_line(p + Vector2(25, -55), p + Vector2(48, -2), tint, 12)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS
    layer.add_child(ui)
    health_label = Label.new()
    health_label.position = Vector2(36, 25)
    health_label.add_theme_font_size_override("font_size", 25)
    ui.add_child(health_label)
    status_label = Label.new()
    status_label.position = Vector2(435, 100)
    status_label.add_theme_font_size_override("font_size", 30)
    ui.add_child(status_label)
    _button(ui, "◀", Vector2(38, 570), Vector2(92, 100), func(): movement = -1.0, func(): movement = 0.0)
    _button(ui, "▶", Vector2(143, 570), Vector2(92, 100), func(): movement = 1.0, func(): movement = 0.0)
    _button(ui, "RÁPIDO", Vector2(875, 590), Vector2(110, 70), func(): hacker.quick_attack())
    _button(ui, "FUERTE", Vector2(995, 510), Vector2(110, 70), func(): hacker.heavy_attack())
    _button(ui, "ESQUIVA", Vector2(1120, 590), Vector2(120, 70), func(): hacker.dodge())
    _button(ui, "AGARRE", Vector2(620, 590), Vector2(110, 70), func(): hacker.grab_attack())
    _button(ui, "BLOQUEO", Vector2(745, 510), Vector2(120, 70), func(): hacker.set_block(true), func(): hacker.set_block(false))

func _button(parent: Control, caption: String, pos: Vector2, size: Vector2, pressed_action: Callable, released_action: Callable = Callable()) -> void:
    var b := Button.new()
    b.text = caption
    b.position = pos
    b.size = size
    b.modulate.a = 0.8
    b.button_down.connect(pressed_action)
    if released_action.is_valid():
        b.button_up.connect(released_action)
    parent.add_child(b)

func _finish(won: bool) -> void:
    match_over = true
    hacker.set_direction(0.0)
    chico.set_direction(0.0)
    status_label.text = "GANASTE" if won else "PERDISTE"
    status_label.text += " — La historia continúa"
