extends Node
class_name CondenaCampaign

# Estructura tecnica del capitulo. Los textos del guion aprobado se integran
# por separado: este archivo no inventa escenas ni dialogos.
const COMEDOR_REPUTATION := {"A": -5, "B": 10, "C": 0}
const CHAPTER_ID := "el_pollo"
const SCENE_COUNT := 9
const FIGHT_SCENES := [2, 4, 7]
const SAVE_KEY := "campaign"
const OPPONENTS := [
    {"id": "el_chico", "name": "EL CHICO", "health": 115.0, "speed": 160.0, "damage": 8.0},
    {"id": "el_flaco", "name": "EL FLACO", "health": 125.0, "speed": 205.0, "damage": 9.0},
    {"id": "preso_grande", "name": "PRESO GRANDE", "health": 165.0, "speed": 125.0, "damage": 13.0}
]

var scene_index: int = 0
var completed_fights: Array[int] = []
var choices: Dictionary = {}

# La decisión guardada es la fuente única, incluso para partidas antiguas.
var reputation: int:
    get:
        return int(COMEDOR_REPUTATION.get(choices.get("comedor", ""), 0))

func load_progress() -> void:
    var profile := SaveSystemV2.load_profile()
    var data: Dictionary = profile.get(SAVE_KEY, {})
    scene_index = clampi(int(data.get("scene_index", 0)), 0, SCENE_COUNT)
    completed_fights.clear()
    for value in data.get("completed_fights", []):
        var index := int(value)
        if index >= 0 and index < OPPONENTS.size() and not completed_fights.has(index):
            completed_fights.append(index)
    choices = data.get("choices", {}).duplicate(true)

func save_progress() -> bool:
    var profile := SaveSystemV2.load_profile()
    profile[SAVE_KEY] = {
        "chapter_id": CHAPTER_ID,
        "scene_index": scene_index,
        "completed_fights": completed_fights.duplicate(),
        "choices": choices.duplicate(true)
    }
    return SaveSystemV2.save_profile(profile)

func fight_index_for_scene(index: int) -> int:
    return FIGHT_SCENES.find(index)

func current_fight_index() -> int:
    return fight_index_for_scene(scene_index)

func opponent_for_fight(index: int) -> Dictionary:
    if index < 0 or index >= OPPONENTS.size():
        return {}
    return OPPONENTS[index].duplicate(true)

func record_choice(key: String, value: Variant) -> bool:
    if key.is_empty():
        return false
    var previous: Dictionary = choices.duplicate(true)
    choices[key] = value
    if save_progress():
        return true
    choices = previous
    return false

func advance_narrative() -> bool:
    if scene_index >= SCENE_COUNT:
        return false
    if current_fight_index() >= 0 and not completed_fights.has(current_fight_index()):
        return false
    scene_index += 1
    if save_progress():
        return true
    scene_index -= 1
    return false

func record_fight_result(fight_index: int, won: bool) -> bool:
    if fight_index != current_fight_index():
        return false
    var previous_fights: Array[int] = completed_fights.duplicate()
    var previous_choices := choices.duplicate(true)
    choices["fight_%d_won" % fight_index] = won
    if not completed_fights.has(fight_index):
        completed_fights.append(fight_index)
    if advance_narrative():
        return true
    completed_fights = previous_fights
    choices = previous_choices
    return false

func is_chapter_complete() -> bool:
    return scene_index >= SCENE_COUNT
