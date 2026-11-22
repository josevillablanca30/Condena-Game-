extends Control
class_name CondenaStoryScreen

# Pantalla narrativa reutilizable. Los dialogos reales se cargan desde datos,
# nunca se inventan en el controlador.
signal scene_finished
signal choice_selected(choice_id: String, value: String)

const CLIPS := ["res://assets/cinematics/1000153316", "res://assets/cinematics/1000153319"]
var film := VideoStreamPlayer.new()
var still := TextureRect.new()
var panel := PanelContainer.new()
var ambience := AudioStreamPlayer.new()
var clip_index := -1
var title_label: Label
var speaker_label: Label
var dialogue_label: RichTextLabel
var next_button: Button
var choices_box: VBoxContainer
var lines: Array[Dictionary] = []
var save_choice: Callable
var line_index := 0
var waiting_for_choice := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var backdrop := ColorRect.new()
    backdrop.color = Color.BLACK
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    still.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(still)
    film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    film.expand = true
    film.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(film)
    film.finished.connect(_film_finished)
    film.hide()
    ambience.stream = preload("res://assets/cinematics/ambiente.ogg")
    add_child(ambience)
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.44
    panel.anchor_bottom = 0.92
    add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.05, 0.05, 0.93)
    style.border_color = Color("#777777")
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
    speaker_label.add_theme_color_override("font_color", Color("#cccccc"))
    layout.add_child(speaker_label)
    dialogue_label = RichTextLabel.new()
    dialogue_label.bbcode_enabled = false
    dialogue_label.fit_content = false
    dialogue_label.custom_minimum_size = Vector2(0, 65)
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
    still.texture = null
    panel.show()
    title_label.text = scene_title
    lines = scene_lines.duplicate(true)
    line_index = 0
    waiting_for_choice = false
    show()
    _show_line()

func _show_line() -> void:
    for child in choices_box.get_children():
        choices_box.remove_child(child)
        child.queue_free()
    if line_index >= lines.size():
        hide()
        scene_finished.emit()
        return
    var entry: Dictionary = lines[line_index]
    if entry.has("clip"):
        clip_index = int(entry["clip"])
        ambience.stop()
        film.stream = load(CLIPS[clip_index] + ".ogv")
        panel.hide()
        film.show()
        film.play()
        if clip_index == 0:
            film.modulate.a = 0.0
            create_tween().tween_property(film, "modulate:a", 1.0, 0.45)
        return
    panel.anchor_top = 0.30 if entry.has("ambience") else 0.44
    panel.anchor_bottom = 0.70 if entry.has("ambience") else 0.92
    if entry.has("ambience"):
        ambience.play()
    speaker_label.text = str(entry.get("speaker", ""))
    dialogue_label.text = str(entry.get("text", ""))
    next_button.visible = true
    next_button.grab_focus()
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
            if choices_box.get_child_count() == 1:
                button.grab_focus()

func _choose(key: String, value: String) -> void:
    if not waiting_for_choice:
        return
    if save_choice.is_valid() and not save_choice.call(key, value):
        title_label.text = "No se pudo guardar. Vuelve a elegir para reintentar."
        return
    waiting_for_choice = false
    choice_selected.emit(key, value)
    if key == "comedor":
        title_label.text = "EL COMEDOR  ·  REPUTACIÓN %s" % CondenaCampaign.COMEDOR_REPUTATION[value]
    var entry: Dictionary = lines[line_index]
    for option in entry.get("choices", []):
        if option is Dictionary and str(option.get("id", "")) == key and str(option.get("value", "")) == value:
            var reply := str(option.get("reply", ""))
            if not reply.is_empty():
                lines.insert(line_index + 1, {"speaker": entry.get("speaker", ""), "text": reply})
            break
    _next_line()

func _next_line() -> void:
    if waiting_for_choice:
        return
    line_index += 1
    _show_line()

func _film_finished() -> void:
    still.texture = load(CLIPS[clip_index] + ".jpg")
    film.hide()
    panel.show()
    _next_line()
