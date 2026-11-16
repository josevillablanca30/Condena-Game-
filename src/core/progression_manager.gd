extends Node
class_name ProgressionManager

signal ranked_unlocked

var current_year: int = 1
var player_exp: int = 0
var pvp_ranked_unlocked: bool = false
var physical_stage: String = "Año 1 (Débil)"

func set_year(year: int) -> void:
    current_year = clampi(year, 1, 10)
    _update_physical_evolution()
    _check_ranked_unlock()

func _update_physical_evolution() -> void:
    if current_year < 5:
        physical_stage = "Año 1 (Débil)"
    elif current_year < 10:
        physical_stage = "Año 5 (Entrenado)"
    else:
        physical_stage = "Año 10 (Consolidado)"

func _check_ranked_unlock() -> void:
    if current_year >= 5 and not pvp_ranked_unlocked:
        pvp_ranked_unlocked = true
        ranked_unlocked.emit()

func to_dict() -> Dictionary:
    return {"year": current_year, "exp": player_exp, "ranked_unlocked": pvp_ranked_unlocked}

func from_dict(data: Dictionary) -> void:
    current_year = clampi(int(data.get("year", 1)), 1, 10)
    player_exp = maxi(0, int(data.get("exp", 0)))
    pvp_ranked_unlocked = bool(data.get("ranked_unlocked", false)) or current_year >= 5
    _update_physical_evolution()
