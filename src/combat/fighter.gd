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
const BODY_HALF_WIDTH := 27.0
const MIN_BODY_GAP := BODY_HALF_WIDTH * 2.0
var facing := 1.0
var dodge_velocity := 0.0
var recovery_time := 0.0
var feint_window := 0.0
var combo_hits := 0
var combo_window := 0.0
var counter_window := 0.0
var parry_window := 0.0
var parry_recovery := 0.0
var hit_reaction_time := 0.0
var attack_pose_time := 0.0
var active_move_id := ""
var last_hit_result := ""
var combat_clock := 0.0
signal combo_changed(hits: int)
signal confirmed_hit(move_id: String, target: CondenaFighter)
signal combat_event(event_name: String, move_id: String)
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
    _attack(str(equipped_moves[slot]), float(data["cost"]), attack_damage * float(data["damage"]), float(data["reach"]), float(data["duration"]), str(data["kind"]))

func _ready() -> void:
    # Colisión corporal real entre luchadores, sin atravesarse.
    var collider := CollisionShape2D.new()
    var body_shape := RectangleShape2D.new()
    body_shape.size = Vector2(BODY_HALF_WIDTH * 2.0, 150.0)
    collider.position = Vector2(0, -45)
    collider.shape = body_shape
    add_child(collider)
    collision_layer = 1
    collision_mask = 1
    health = max_health
    stamina = max_stamina
    health_changed.emit(health)
    stamina_changed.emit(stamina)

func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector2.ZERO
        return
    combat_clock += delta
    stun_time = maxf(0.0, stun_time - delta)
    leg_slow_time = maxf(0.0, leg_slow_time - delta)
    knockdown_time = maxf(0.0, knockdown_time - delta)
    recovery_time = maxf(0.0, recovery_time - delta)
    feint_window = maxf(0.0, feint_window - delta)
    combo_window = maxf(0.0, combo_window - delta)
    counter_window = maxf(0.0, counter_window - delta)
    parry_window = maxf(0.0, parry_window - delta)
    parry_recovery = maxf(0.0, parry_recovery - delta)
    hit_reaction_time = maxf(0.0, hit_reaction_time - delta)
    attack_pose_time = maxf(0.0, attack_pose_time - delta)
    if combo_window <= 0.0 and combo_hits > 0:
        combo_hits = 0
        combo_changed.emit(0)
    stamina = minf(max_stamina, stamina + (6.0 if blocking else 16.0) * delta)
    guard_pressure = maxf(0.0, guard_pressure - 9.0 * delta)
    stamina_changed.emit(stamina)
    if opponent != null and not opponent.dead:
        facing = signf(opponent.position.x - position.x) if absf(opponent.position.x - position.x) > 1.0 else facing
    # Desplazamiento horizontal fisico y estados explicitos.
    var horizontal_speed := 0.0
    if invulnerable:
        horizontal_speed = dodge_velocity
    elif not busy and not blocking and stun_time <= 0.0 and knockdown_time <= 0.0 and recovery_time <= 0.0:
        horizontal_speed = direction * move_speed
        if leg_slow_time > 0.0:
            horizontal_speed *= 0.65
    velocity = Vector2(horizontal_speed, 0.0)
    move_and_slide()
    position.x = clampf(position.x, 95.0, 1185.0)

func set_direction(value: float) -> void:
    direction = clampf(value, -1.0, 1.0)

func set_block(value: bool) -> void:
    if dead:
        return
    blocking = value and not busy and knockdown_time <= 0.0 and stun_time <= 0.0

func parry() -> void:
    # Defensa activa de alto riesgo: solo 0.16 s para leer un golpe.
    # Los agarres la superan; fallarla deja recuperacion castigable.
    if dead or busy or blocking or stun_time > 0.0 or knockdown_time > 0.0 or recovery_time > 0.0 or stamina < 14.0:
        return
    stamina -= 14.0
    busy = true
    attack_serial += 1
    var serial := attack_serial
    parry_window = 0.16
    combat_event.emit("parry_attempt", "")
    await get_tree().create_timer(0.16).timeout
    if not is_inside_tree() or dead or serial != attack_serial:
        return
    parry_window = 0.0
    await get_tree().create_timer(0.20).timeout
    if is_inside_tree() and not dead and serial == attack_serial:
        busy = false
        recovery_time = maxf(recovery_time, 0.20)

func quick_attack() -> void:
    use_move("light")

func heavy_attack() -> void:
    use_move("heavy")

func dodge() -> void:
    if dead or busy or blocking or stun_time > 0.0 or knockdown_time > 0.0 or recovery_time > 0.0 or stamina < 18.0:
        return
    stamina -= 18.0
    busy = true
    invulnerable = true
    var away := -1.0 if opponent != null and opponent.position.x > position.x else 1.0
    dodge_velocity = away * 525.0
    await get_tree().create_timer(0.2).timeout
    if is_inside_tree() and not dead:
        invulnerable = false
        dodge_velocity = 0.0
        busy = false
        recovery_time = 0.25
        combat_event.emit("dodge_recovery", "")

func grab_attack() -> void:
    use_move("grapple")

func feint() -> void:
    # Amague: provoca reacción sin crear hitbox ni daño.
    if dead or busy or blocking or stun_time > 0.0 or knockdown_time > 0.0 or recovery_time > 0.0 or stamina < 12.0:
        return
    stamina -= 12.0
    busy = true
    attack_serial += 1
    var serial := attack_serial
    feint_window = 0.18
    combat_event.emit("feint", "")
    await get_tree().create_timer(0.18).timeout
    if is_inside_tree() and not dead and serial == attack_serial:
        busy = false
        recovery_time = 0.12

func _attack(move_id: String, cost: float, damage: float, reach: float, duration: float, kind: String) -> void:
    if dead or busy or blocking or stun_time > 0.0 or knockdown_time > 0.0 or recovery_time > 0.0 or stamina < cost:
        return
    stamina -= cost
    busy = true
    attack_serial += 1
    attack_kind = kind
    active_move_id = move_id
    attack_pose_time = duration
    var counter_armed := counter_window > 0.0
    counter_window = 0.0
    combat_event.emit("attack_started", move_id)
    var serial := attack_serial
    var combo_damage_scale := maxf(0.60, 1.0 - float(combo_hits) * 0.12)
    var chained_hit := combo_hits > 0 and combo_window > 0.0
    var locked_facing := facing
    await get_tree().create_timer(duration * 0.45).timeout
    if not is_inside_tree() or dead or serial != attack_serial:
        return
    # La zona de impacto se proyecta delante del atacante, no alrededor de su centro.
    # Prototipo geométrico; los hitboxes por fotograma vendrán con las animaciones.
    if opponent != null and not opponent.dead:
        var relative_x := (opponent.position.x - position.x) * locked_facing
        var contact := relative_x >= BODY_HALF_WIDTH and relative_x - BODY_HALF_WIDTH <= reach
        if contact and not opponent.invulnerable:
            var result: String = opponent.receive_hit(damage * combo_damage_scale * (1.2 if counter_armed and not guarded_hit else 1.0), kind, move_id)
            if result == "parried":
                combo_hits = 0
                combo_window = 0.0
                combo_changed.emit(0)
                stun_time = maxf(stun_time, 0.38)
                attack_serial += 1
                busy = false
                attack_kind = ""
                active_move_id = ""
                attack_pose_time = 0.0
                recovery_time = maxf(recovery_time, 0.38)
                combat_event.emit("attack_parried", move_id)
                return
            if result == "guarded":
                combo_hits = 0
                combo_window = 0.0
                combo_changed.emit(0)
                combat_event.emit("blocked_attack", move_id)
            else:
                combo_hits = mini(combo_hits + 1, 5) if chained_hit else 1
                combo_window = 0.85
                combo_changed.emit(combo_hits)
                if counter_armed:
                    combat_event.emit("counter_hit", move_id)
                combat_event.emit("combo_hit" if chained_hit else "hit_confirmed", move_id)
            confirmed_hit.emit(move_id, opponent)
        else:
            if contact and opponent.invulnerable:
                opponent.counter_window = maxf(opponent.counter_window, 0.65)
                opponent.combat_event.emit("perfect_dodge", move_id)
            combo_hits = 0
            combo_window = 0.0
            combo_changed.emit(0)
            combat_event.emit("attack_whiffed", move_id)
    await get_tree().create_timer(duration * 0.55).timeout
    if is_inside_tree() and serial == attack_serial:
        busy = false
        attack_kind = ""
        active_move_id = ""
        attack_pose_time = 0.0
        recovery_time = 0.10 if kind == "quick" else 0.20

func receive_hit(damage: float, kind: String = "quick", move_id: String = "") -> String:
    if dead or invulnerable:
        last_hit_result = "evaded"
        return "evaded"
    if parry_window > 0.0 and kind != "grab":
        parry_window = 0.0
        attack_serial += 1
        busy = false
        counter_window = maxf(counter_window, 0.90)
        combat_event.emit("perfect_parry", move_id)
        last_hit_result = "parried"
        return "parried"
    hit_reaction_time = 0.24
    # La guardia absorbe daño pero no es universal: los agarres la superan.
    var was_blocking := blocking
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
    # El golpe interrumpe el ataque rival antes de su ventana de contacto.
    combo_hits = 0
    combo_window = 0.0
    combo_changed.emit(0)
    if busy and not blocking:
        attack_serial += 1
        busy = false
        attack_kind = ""
        active_move_id = ""
        attack_pose_time = 0.0
        recovery_time = maxf(recovery_time, 0.18)
    var guarded := was_blocking and not guard_broken and kind != "grab"
    if guarded:
        combat_event.emit("guarded", move_id)
    elif guard_broken:
        combat_event.emit("guard_broken", move_id)
    health = maxf(0.0, health - damage * (0.25 if guarded else 1.0))
    if move_id == "low_kick" and not guarded:
        leg_slow_time = maxf(leg_slow_time, 2.0)
    if move_id == "takedown" and not guarded:
        knockdown_time = maxf(knockdown_time, 0.85)
        stun_time = maxf(stun_time, 0.85)
    health_changed.emit(health)
    if health <= 0.0:
        blocking = false
        invulnerable = false
        dodge_velocity = 0.0
        dead = true
        attack_serial += 1
        defeated.emit()
    last_hit_result = "guarded" if guarded else "hit"
    return last_hit_result
