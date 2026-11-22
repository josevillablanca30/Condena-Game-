extends ColorRect

signal confirmed
var fighter: CondenaFighter
var buttons: Array[Button] = []
var layout := VBoxContainer.new()
const DETAILS := {
    "jab": "Rápido y de bajo coste. La guardia reduce el impacto.",
    "low_kick": "Mayor alcance. Al conectar reduce la movilidad. Se puede bloquear.",
    "cross": "Alto daño. Una esquiva deja tiempo para responder.",
    "elbow": "Potente a corta distancia. Fuera de alcance pierde el intercambio.",
    "clinch": "Supera guardia y parada. Una retirada puede dejarlo corto.",
    "takedown": "Derriba al conectar. Alto coste y recuperación larga."
}

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    color = Color("#101010")
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    center.add_child(layout)
    layout.add_theme_constant_override("separation", 14)
    var heading := Label.new()
    heading.text = "PREPARA TUS TRES TÉCNICAS"
    heading.add_theme_font_size_override("font_size", 30)
    layout.add_child(heading)
    for slot in CondenaFighter.MOVE_SLOTS:
        var button := Button.new()
        button.custom_minimum_size = Vector2(770, 64)
        button.pressed.connect(_cycle.bind(slot))
        layout.add_child(button)
        buttons.append(button)
    var guide := Label.new()
    guide.text = "Mover: A/D o stick izquierdo     Guardia: Shift / LB\nGolpe rápido: H / A     Golpe fuerte: U / clic en stick derecho\nEsquiva: Espacio / B     Parada: F / RB     Amago: E / clic en stick izquierdo"
    layout.add_child(guide)
    var play := Button.new()
    play.text = "ENTRAR A LA PELEA"
    play.custom_minimum_size.y = 52
    play.pressed.connect(func(): hide(); confirmed.emit())
    layout.add_child(play)
    hide()

func present(selected: CondenaFighter) -> void:
    fighter = selected
    _refresh()
    show()
    buttons[0].grab_focus()

func _cycle(slot: String) -> void:
    var ids := CondenaFighter.MOVE_DATA.keys()
    var index := ids.find(fighter.equipped_moves[slot])
    fighter.equip_move(slot, ids[(index + 1) % ids.size()])
    _refresh()

func _refresh() -> void:
    for i in buttons.size():
        var id: String = fighter.equipped_moves[CondenaFighter.MOVE_SLOTS[i]]
        var label: String = ["J / X", "K / Y", "L / RT"][i]
        buttons[i].text = "%s   ·   %s   ·   %d RES\n%s" % [label, CondenaFighter.MOVE_LABELS[id], int(CondenaFighter.MOVE_DATA[id]["cost"]), DETAILS[id]]
