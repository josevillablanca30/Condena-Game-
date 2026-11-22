extends Node
class_name CampaignBridge

# Conector independiente entre la campana y el combate. No altera el motor.
signal chapter_progressed(scene_index: int)
signal fight_finished(won: bool, fight_index: int)

var campaign: CondenaCampaign
var active_fight_index := -1

func _ready() -> void:
    campaign = CondenaCampaign.new()
    add_child(campaign)
    campaign.load_progress()

func start_current_fight(player: CondenaFighter, opponent: CondenaFighter) -> bool:
    if campaign.is_chapter_complete():
        return false
    active_fight_index = campaign.current_fight_index()
    if active_fight_index < 0:
        return false
    var config := campaign.opponent_for_fight(active_fight_index)
    if config.is_empty():
        return false
    opponent.armored_grabs = active_fight_index == 2
    opponent.guard_damage_scale = 0.15 if active_fight_index == 2 else 0.25
    opponent.fighter_name = str(config["name"])
    opponent.max_health = float(config["health"])
    opponent.health = opponent.max_health
    opponent.move_speed = float(config["speed"])
    opponent.attack_damage = float(config["damage"])
    player.health = player.max_health
    player.stamina = player.max_stamina
    opponent.stamina = opponent.max_stamina
    return true

func submit_combat_result(won: bool) -> bool:
    if active_fight_index < 0:
        return false
    var completed_index := active_fight_index
    active_fight_index = -1
    var advanced := campaign.record_fight_result(completed_index, won)
    fight_finished.emit(won, completed_index)
    if advanced:
        chapter_progressed.emit(campaign.scene_index)
    return advanced

func advance_story_scene() -> bool:
    var advanced := campaign.advance_narrative()
    if advanced:
        chapter_progressed.emit(campaign.scene_index)
    return advanced

func current_status() -> Dictionary:
    return {
        "chapter": CondenaCampaign.CHAPTER_ID,
        "scene": campaign.scene_index,
        "total_scenes": CondenaCampaign.SCENE_COUNT,
        "fight_index": campaign.current_fight_index(),
        "finished": campaign.is_chapter_complete()
    }
