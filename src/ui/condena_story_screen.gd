extends Control
class_name CondenaStoryScreen

# Pantalla narrativa reutilizable. Los dialogos reales se cargan desde datos,
# nunca se inventan en el controlador.
signal scene_finished
signal choice_selected(choice_id: String, value: String)

var title_label: Label
var speaker_label: Label
var dialogue_label: RichTextLabel
var next_button: Button
var choices_box: VBoxContainer
var lines: Array[Dictionary] = []
var line_index := 0
var waiting_for_choice := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var backdrop := ColorRect.new()
    backdrop.color = Color("#101418")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    var panel := PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.50
    panel.anchor_bottom = 0.92
    add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1b2228")
    style.border_color = Color("#8e8274")
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    panel.add_theme_stylebox_override("panel", style)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 12)
    panel.add_child(layout)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 24)
    layout.add_child(title_label)
    speaker_label = Label.new()
    speaker_label.add_theme_font_size_override("font_size", 20)
    speaker_label.add_theme_color_override("font_color", Color("#c6a98b"))
    layout.add_child(speaker_label)
    dialogue_label = RichTextLabel.new()
    dialogue_label.bbcode_enabled = false
    dialogue_label.fit_content = false
    dialogue_label.custom_minimum_size = Vector2(0, 110)
    dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dialogue_label.add_theme_font_size_override("normal_font_size", 22)
    layout.add_child(dialogue_label)
    choices_box = VBoxContainer.new()
    layout.add_child(choices_box)
    next_button = Button.new()
    next_button.text = "CONTINUAR"
    next_button.custom_minimum_size = Vector2(0, 56)
    next_button.pressed.connect(_next_line)
    layout.add_child(next_button)
    hide()

func present(scene_title: String, scene_lines: Array[Dictionary]) -> void:
    title_label.text = scene_title
    lines = scene_lines.duplicate(true)
    line_index = 0
    waiting_for_choice = false
    show()
    _show_line()

func _show_line() -> void:
    for child in choices_box.get_children():
        child.queue_free()
    if line_index >= lines.size():
        hide()
        scene_finished.emit()
        return
    var entry: Dictionary = lines[line_index]
    speaker_label.text = str(entry.get("speaker", ""))
    dialogue_label.text = str(entry.get("text", ""))
    next_button.visible = true
    waiting_for_choice = false
    var options: Array = entry.get("choices", [])
    if not options.is_empty():
        waiting_for_choice = true
        next_button.hide()
        for option in options:
            if not option is Dictionary:
                continue
            var choice: Dictionary = option
            var button := Button.new()
            button.text = str(choice.get("label", ""))
            button.custom_minimum_size = Vector2(0, 52)
            var key := str(choice.get("id", ""))
            var value := str(choice.get("value", ""))
            button.pressed.connect(_choose.bind(key, value))
            choices_box.add_child(button)

func _choose(key: String, value: String) -> void:
    if not waiting_for_choice:
        return
    waiting_for_choice = false
    choice_selected.emit(key, value)
    _next_line()

func _next_line() -> void:
    if waiting_for_choice:
        return
    line_index += 1
    _show_line()
