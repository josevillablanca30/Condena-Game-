extends CharacterBody2D
class_name CondenaFighter

signal health_changed(value: float)
signal stamina_changed(value: float)
signal defeated

@export var fighter_name: String = "Hacker"
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var move_speed: float = 220.0
@export var attack_damage: float = 12.0
@export var is_enemy: bool = false

var health: float
var stamina: float
var direction: float = 0.0
var blocking := false
var busy := false
var dead := false
var opponent: CondenaFighter
var attack_serial := 0
var invulnerable := false
var stun_time := 0.0
var guard_pressure := 0.0
var leg_slow_time := 0.0
var knockdown_time := 0.0
var attack_kind := ""
# Repertorio configurable: las técnicas comparten ranuras y tienen costes propios.
var equipped_moves: Dictionary = {"light": "jab", "heavy": "cross", "grapple": "clinch"}
const MOVE_DATA := {
    "jab": {"kind": "quick", "cost": 10.0, "damage": 1.0, "reach": 95.0, "duration": 0.28},
    "low_kick": {"kind": "quick", "cost": 16.0, "damage": 1.1, "reach": 120.0, "duration": 0.43},
    "cross": {"kind": "heavy", "cost": 28.0, "damage": 1.8, "reach": 105.0, "duration": 0.58},
    "elbow": {"kind": "heavy", "cost": 22.0, "damage": 1.45, "reach": 70.0, "duration": 0.38},
    "clinch": {"kind": "grab", "cost": 25.0, "damage": 1.25, "reach": 65.0, "duration": 0.50},
    "takedown": {"kind": "grab", "cost": 36.0, "damage": 1.55, "reach": 55.0, "duration": 0.72}
}
const MOVE_SLOTS := {"light": ["jab", "low_kick"], "heavy": ["cross", "elbow"], "grapple": ["clinch", "takedown"]}

func equip_move(slot: String, move_id: String) -> bool:
    if busy or dead or not MOVE_SLOTS.has(slot) or not move_id in MOVE_SLOTS[slot]:
        return false
    equipped_moves[slot] = move_id
    return true

func use_move(slot: String) -> void:
    if not equipped_moves.has(slot):
        return
    var data: Dictionary = MOVE_DATA[equipped_moves[slot]]
    _attack(float(data["cost"]), attack_damage * float(data["damage"]), float(data["reach"]), float(data["duration"]), str(data["kind"]))

func _ready() -> void:
    health = max_health
    stamina = max_stamina
    health_changed.emit(health)
    stamina_changed.emit(stamina)

func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector2.ZERO
        return
    stun_time = maxf(0.0, stun_time - delta)
    leg_slow_time = maxf(0.0, leg_slow_time - delta)
    knockdown_time = maxf(0.0, knockdown_time - delta)
    stamina = minf(max_stamina, stamina + (6.0 if blocking else 16.0) * delta)
    guard_pressure = maxf(0.0, guard_pressure - 9.0 * delta)
    stamina_changed.emit(stamina)
    velocity = Vector2(direction * move_speed * (0.65 if leg_slow_time > 0.0 else 1.0) if not busy and not blocking and stun_time <= 0.0 and knockdown_time <= 0.0 else 0.0, 0.0)
    move_and_slide()
    position.x = clampf(position.x, 95.0, 1185.0)

func set_direction(value: float) -> void:
    direction = clampf(value, -1.0, 1.0)

func set_block(value: bool) -> void:
    if dead:
        return
    blocking = value and not busy

func quick_attack() -> void:
    use_move("light")

func heavy_attack() -> void:
    use_move("heavy")

func dodge() -> void:
    if dead or busy or blocking or knockdown_time > 0.0 or stamina < 18.0:
        return
    stamina -= 18.0
    busy = true
    invulnerable = true
    var start_x := position.x
    var away := -1.0 if opponent != null and opponent.position.x > position.x else 1.0
    var tween := create_tween()
    tween.tween_property(self, "position:x", clampf(start_x + away * 105.0, 95.0, 1185.0), 0.2)
    await tween.finished
    if is_inside_tree():
        invulnerable = false
        busy = false

func grab_attack() -> void:
    use_move("grapple")

func _attack(cost: float, damage: float, reach: float, duration: float, kind: String) -> void:
    if dead or busy or blocking or stun_time > 0.0 or knockdown_time > 0.0 or stamina < cost:
        return
    stamina -= cost
    busy = true
    attack_serial += 1
    attack_kind = kind
    var serial := attack_serial
    await get_tree().create_timer(duration * 0.45).timeout
    if not is_inside_tree() or dead or serial != attack_serial:
        return
    if opponent != null and not opponent.dead and absf(opponent.position.x - position.x) <= reach:
        opponent.receive_hit(damage, kind, equipped_moves.get("light", "") if kind == "quick" else equipped_moves.get("heavy", "") if kind == "heavy" else equipped_moves.get("grapple", ""))
    await get_tree().create_timer(duration * 0.55).timeout
    if is_inside_tree() and serial == attack_serial:
        busy = false

func receive_hit(damage: float, kind: String = "quick", move_id: String = "") -> void:
    if dead or invulnerable:
        return
    # Agarres contrarrestan bloqueo; ataques fuertes desgastan la guardia.
    var guard_broken := false
    if blocking and kind != "grab":
        var guard_cost := 8.0 if kind == "quick" else 24.0
        stamina = maxf(0.0, stamina - guard_cost)
        guard_pressure += guard_cost
        guard_broken = stamina <= 0.0 or guard_pressure >= 55.0
        if guard_broken:
            blocking = false
            guard_pressure = 0.0
            stun_time = 0.55
    elif blocking and kind == "grab":
        blocking = false
        stun_time = 0.4
    if not guard_broken:
        stun_time = 0.12 if kind != "grab" else 0.3
    var guarded := blocking and kind != "grab"
    health = maxf(0.0, health - damage * (0.25 if guarded else 1.0))
    if move_id == "low_kick" and not guarded:
        leg_slow_time = maxf(leg_slow_time, 2.0)
    if move_id == "takedown" and not guarded:
        knockdown_time = maxf(knockdown_time, 0.85)
        stun_time = maxf(stun_time, 0.85)
    health_changed.emit(health)
    if health <= 0.0:
        dead = true
        attack_serial += 1
        defeated.emit()
