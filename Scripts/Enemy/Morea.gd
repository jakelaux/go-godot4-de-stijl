extends KinematicBody2D

signal morea_hit
signal morea_dead

const bullet_scene = preload("res://Scenes/Enemy/Bullet.tscn")

onready var shot_timer           = $ShotTimer 
onready var rotator              = $Rotator
onready var sprite               = $Sprite
onready var state_duration       = $StateDuration
onready var attack_particles     = $AttackParticles
onready var hurtbox              = $Hurtbox
onready var animation_player     = $AnimationPlayer
onready var telegraph_timer      = $TelegraphTimer
onready var slam_delay           = $SlamDelay
onready var morea_death_noise    = $MoreaDeathNoise
onready var win_sprite           = $WinSprite

export var ROTATE_SPEED          = 100
export var SHOT_TIMER_WAIT_TIME  = 0.2
export var SPAWN_POINT_COUNT     = 4
export var RADIUS                = 50
export var CHASE_DISTANCE        = 300
export var SLAM_WAIT_TIME        = 3
export var HEALTH                = 100
export var ACCELERATION          = 300
export var MAX_SPEED             = 80
export var FRICTION              = 150
export var CHASE_WAIT_TIME       = 3

enum states { BHELL1, BHELL2, BHELL3, BHELL4, CHASE, SLAM, IDLE }

var state           = states.CHASE
var velocity        = Vector2.ZERO
var knockback       = Vector2.ZERO
var step            = 2 * PI / SPAWN_POINT_COUNT
var state_running   = false
var world
var player
var rng 

var game_state = global_game_state

func _ready():
	world  = get_parent()
	player = world.get_node("Lester")
	rng    = RandomNumberGenerator.new()
	win_sprite.hide()
	rng.randomize()
	state = rng.randi_range(0,4)

func _process(delta):
	if game_state.playing == false:
		return 
	
	if not state_running:
		update_state()	
	match state: 
		states.BHELL1:
			state = states.CHASE
			animation_player.play("Attack")
			bullet_hell_manipulation(0, 0.3, 2, 3, delta)
			set_bullet_hell_spawn(delta)
		states.BHELL2:
			state = states.IDLE
			animation_player.play("Attack")
			bullet_hell_manipulation(30, 0.4, 4, 3, delta)
			set_bullet_hell_spawn(delta)
		states.BHELL3:
			state = states.IDLE
			animation_player.play("Attack")
			bullet_hell_manipulation(75, 0.5, 3, 4, delta)
			set_bullet_hell_spawn(delta)
		states.BHELL4:
			state = states.CHASE
			animation_player.play("Attack")
			bullet_hell_manipulation(50, 0.25, 3, 5, delta)
			set_bullet_hell_spawn(delta)
		states.SLAM:
			slam(delta)
		states.CHASE:
			chase(delta)
		states.IDLE:
			animation_player.play("idle")
			idle(delta)
			
	var new_rotation = rotator.rotation_degrees + ROTATE_SPEED * delta
	rotator.rotation_degrees = fmod(new_rotation, 360)
	
	velocity = move_and_slide(velocity)
	
func update_state():
	telegraph_timer.start()
	animation_player.play("idle")

func idle(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
func chase(delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0
	if not state_running:
		start_state_timer(CHASE_WAIT_TIME)

func slam(_delta):
	animation_player.play("Blink")
	slam_delay.start()
	
func set_bullet_hell_spawn(_delta):
	for i in range(SPAWN_POINT_COUNT):
		var spawn_point = Node2D.new()
		var pos = Vector2(RADIUS, 0).rotated(step * i)
		spawn_point.position = pos
		spawn_point.rotation = pos.angle()
		rotator.add_child(spawn_point)
		
		var spawn_point_sprite = Sprite.new()
		spawn_point_sprite.texture = load("res://Assets/enemy/spawn-visualization.png")
		spawn_point_sprite.scale = Vector2(.65,.65)
		spawn_point.add_child(spawn_point_sprite)
		
	shot_timer.wait_time = SHOT_TIMER_WAIT_TIME
	shot_timer.start()

func bullet_hell_manipulation(rotate_speed, shot_timer_wait, spawn_point_counter, duration, _delta):
	step                             = spawn_point_counter
	ROTATE_SPEED                     = rotate_speed
	SHOT_TIMER_WAIT_TIME             = shot_timer_wait
	SPAWN_POINT_COUNT                = spawn_point_counter
	if not state_running:
		start_state_timer(duration)

func start_state_timer(duration):
	state_running            = true
	state_duration.wait_time = duration
	state_duration.start()

func _on_ShotTimer_timeout():
	for s in rotator.get_children():
			var bullet = bullet_scene.instance()
			get_tree().root.add_child(bullet)
			bullet.position = s.global_position
			bullet.rotation = s.global_rotation
			
func handle_death():
	for spawn in rotator.get_children():
		rotator.remove_child(spawn)
	morea_death_noise.play()
	game_state.playing = false
	sprite.hide()
	win_sprite.show()
	emit_signal("morea_dead")
			
func game_reset():
	animation_player.play("RESET")
	sprite.show()
	win_sprite.hide()
	HEALTH = 100
			
func _on_Hurtbox_area_entered(_area):
	attack_particles.emitting = true
	HEALTH = HEALTH - rng.randi_range(1, 5)
	if HEALTH <= 0:
		handle_death()
	emit_signal("morea_hit")
	hurtbox.start_invincibility(0.4)
	var direction = global_position.direction_to(player.global_position)
	var knockback_direction = direction.rotated(deg2rad(180))
	velocity = knockback_direction * MAX_SPEED * 2

func _on_StateDuration_timeout():
	state_running = false
	state = states.CHASE
	for spawn in rotator.get_children():
		rotator.remove_child(spawn)


func _on_TelegraphTimer_timeout():
	if global_position.distance_to(player.global_position) > CHASE_DISTANCE:
		state = rng.randi_range(4,5)
	elif state == 0 or state == 1 or state == 2 or state == 3:
		if rng.randf() < .25:
			state = rng.randi_range(0,3)
		else:
			state = rng.randi_range(4,5)
	else:
		state = rng.randi_range(0,5)


func _on_SlamDelay_timeout():
	animation_player.play("Slam")
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * MAX_SPEED * 6
	if not state_running:
		start_state_timer(SLAM_WAIT_TIME)
