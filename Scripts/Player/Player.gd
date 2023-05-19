extends KinematicBody2D

signal lester_hit
signal lester_dead

const smudge_scene = preload("res://Scenes/World/CanvasSmudge.tscn")

export var ACCELERATION  = 500
export var MAX_SPEED     = 80
export var DASH_SPEED    = 17000
export var DASH_DURATION = 1.5
export var FRICTION      = 500
export var HEALTH        = 4.5

enum { MOVE, DASH, ATTACK }

var state        = MOVE
var velocity     = Vector2.ZERO
var dash_vector  = Vector2.ZERO
var screen_size  = Vector2.ZERO
var game_state   = global_game_state

onready var sprite                 = $Sprite
onready var dash                   = $Dash
onready var animation_player       = $AnimationPlayer
onready var hitbox_pivot           = $HitboxPivot
onready var hitbox_collider        = $HitboxPivot/Hitbox/CollisionShape2D
onready var hurtbox                = $Hurtbox
onready var enemy_attack_particles = $EnemyAttackParticles
onready var hurt_sound             = $HurtSound
onready var dash_sound             = $DashSound
onready var attack_sound           = $AttackSound
onready var death_sound            = $DeathSound
onready var lose_image             = $loseImage

func _ready():
	screen_size = get_viewport_rect().size
	lose_image.hide()

func _physics_process(delta):
	if game_state.playing == false:
		return 
		
	match state:
		MOVE:
			move_state(delta)
		DASH:
			dash_state(delta)
		ATTACK:
			attack_state(delta)
			
func move_state(delta):
	var input_vector = get_input_vector()
	if Input.is_action_just_pressed("dash") && dash.canDash && !dash.isDashing():
		dash_sound.play()
		state = DASH
	if Input.is_action_just_pressed('attack'):
		attack_sound.play()
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		state = ATTACK
	elif input_vector != Vector2.ZERO:
		animation_player.play("walk")
		#walk
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		sprite.flip_h = velocity.x < 0
		hitbox_pivot.look_at(global_position + velocity.normalized())
	else:
		#idle
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		animation_player.play("Idle")
	move()
	
func dash_state(delta):
	dash.startDash(sprite, DASH_DURATION)
	dash_vector = get_input_vector()
	velocity = dash_vector * DASH_SPEED * delta
	state = MOVE
	move()
	
func attack_state(_delta):
	animation_player.play("AttackLR")
	hitbox_collider.disabled = false
	yield(animation_player,"animation_finished")
	hitbox_collider.disabled = true
	state = MOVE

func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	input_vector   = input_vector.normalized()
	return input_vector

func move():
	velocity = move_and_slide(velocity)
	self.global_position.x = clamp(self.global_position.x, 0, screen_size.x)
	self.global_position.y = clamp(self.global_position.y, 0, screen_size.y)

func handle_death():
	death_sound.play()
	game_state.playing = false
	sprite.hide()
	lose_image.show()
	emit_signal("lester_dead")

func game_reset():
	HEALTH      = 4.5
	animation_player.play("RESET")
	var smudges = get_tree().get_nodes_in_group("smudge")
	for smudge in smudges:
		smudge.queue_free()
	sprite.show()
	lose_image.hide()

func _on_Hurtbox_area_entered(area):
	if dash.isDashing():
		return
	hurt_sound.play()
	emit_signal("lester_hit")
	if HEALTH == 0:
		handle_death()
	HEALTH = HEALTH - .5
	var smudge = smudge_scene.instance()
	var smudge_sprite = smudge.get_node("Sprite")
	get_tree().root.add_child(smudge)
	smudge.position = global_position
	smudge_sprite.frame = rand_range(0,9)
	smudge_sprite.rotation_degrees = rand_range(0, 360)
	
	var source = area.get_parent()
	var direction = global_position.direction_to(source.global_position)
	var knockback_direction = direction.rotated(deg2rad(180))
	if (source.get_name()!= "Morea"):
		velocity = knockback_direction * MAX_SPEED
	else:
		velocity = knockback_direction * MAX_SPEED * .5
	enemy_attack_particles.emitting = true
