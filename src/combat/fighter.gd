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
var attack_kind := ""

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
    stamina = minf(max_stamina, stamina + (6.0 if blocking else 16.0) * delta)
    guard_pressure = maxf(0.0, guard_pressure - 9.0 * delta)
    stamina_changed.emit(stamina)
    velocity = Vector2(direction * move_speed if not busy and not blocking and stun_time <= 0.0 else 0.0, 0.0)
    move_and_slide()
    position.x = clampf(position.x, 95.0, 1185.0)

func set_direction(value: float) -> void:
    direction = clampf(value, -1.0, 1.0)

func set_block(value: bool) -> void:
    if dead:
        return
    blocking = value and not busy

func quick_attack() -> void:
    _attack(10.0, attack_damage, 95.0, 0.28, "quick")

func heavy_attack() -> void:
    _attack(28.0, attack_damage * 1.8, 105.0, 0.58, "heavy")

func dodge() -> void:
    if dead or busy or blocking or stamina < 18.0:
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
    _attack(25.0, attack_damage * 1.25, 65.0, 0.50, "grab")

func _attack(cost: float, damage: float, reach: float, duration: float, kind: String) -> void:
    if dead or busy or blocking or stun_time > 0.0 or stamina < cost:
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
        opponent.receive_hit(damage, kind)
    await get_tree().create_timer(duration * 0.55).timeout
    if is_inside_tree() and serial == attack_serial:
        busy = false

func receive_hit(damage: float, kind: String = "quick") -> void:
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
    health_changed.emit(health)
    if health <= 0.0:
        dead = true
        attack_serial += 1
        defeated.emit()
