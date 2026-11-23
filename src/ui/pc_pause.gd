extends CanvasLayer

signal returned_to_menu
var veil := ColorRect.new()
var menu := VBoxContainer.new()
var resume: Button
var audio: CheckButton
var fullscreen: CheckButton
var previous_focus: Control

func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS
    veil.color = Color(0.025, 0.025, 0.025, 0.97)
    add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    veil.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_child(menu)
    menu.custom_minimum_size.x = 560
    menu.add_theme_constant_override("separation", 12)
    var heading := Label.new()
    heading.text = "CONDENA   /   PAUSA"
    heading.add_theme_font_size_override("font_size", 32)
    menu.add_child(heading)
    resume = Button.new()
    resume.text = "VOLVER AL JUEGO"
    resume.pressed.connect(close)
    menu.add_child(resume)
    audio = CheckButton.new()
    audio.text = "Sonido"
    menu.add_child(audio)
    fullscreen = CheckButton.new()
    fullscreen.text = "Pantalla completa"
    menu.add_child(fullscreen)
    var settings: Dictionary = SaveSystemV2.load_profile().get("pc_options", {})
    audio.button_pressed = settings.get("sound", true)
    fullscreen.button_pressed = settings.get("fullscreen", false)
    _apply()
    audio.toggled.connect(_save)
    fullscreen.toggled.connect(_save)
    var back := Button.new()
    back.text = "MENÚ PRINCIPAL · VOLVER AL ÚLTIMO GUARDADO"
    back.pressed.connect(func(): close(); returned_to_menu.emit())
    menu.add_child(back)
    veil.hide()

func _apply() -> void:
    AudioServer.set_bus_mute(0, not audio.button_pressed)
    if DisplayServer.get_name() != "headless":
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _save(_enabled: bool) -> void:
    _apply()
    var profile := SaveSystemV2.load_profile()
    profile["pc_options"] = {"sound": audio.button_pressed, "fullscreen": fullscreen.button_pressed}
    SaveSystemV2.save_profile(profile)

func open() -> void:
    previous_focus = get_viewport().gui_get_focus_owner()
    get_tree().paused = true
    veil.show()
    resume.grab_focus()

func close() -> void:
    veil.hide()
    get_tree().paused = false
    if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
        previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
    var toggle: bool = event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo
    if event is InputEventJoypadButton:
        toggle = event.button_index == JOY_BUTTON_START and event.pressed
    if toggle:
        get_viewport().set_input_as_handled()
        if veil.visible:
            close()
        else:
            open()
