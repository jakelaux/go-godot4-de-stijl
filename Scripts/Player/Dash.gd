extends Node2D

export var  dash_delay = .5

onready var dash_timer  = $DashTimer
onready var ghost_timer = $GhostTimer 
onready var dust        = $Dust

var ghostScene = preload("res://Scenes/Player/DashGhost.tscn")
var canDash = true
var sprite

func startDash(player_sprite, duration):
	self.sprite          = player_sprite
	dash_timer.wait_time = duration
	dash_timer.start()
	ghost_timer.start()
	dust.restart()
	dust.emitting = true
	instanceGhost()

func instanceGhost():
	var ghost: Sprite        = ghostScene.instance()
	get_parent().get_parent().add_child(ghost)
	ghost.global_position     = global_position
	ghost.texture             = sprite.texture
	ghost.vframes             = sprite.vframes
	ghost.hframes             = sprite.hframes
	ghost.frame               = sprite.frame
	ghost.flip_h              = sprite.flip_h
	
func isDashing():
	return !dash_timer.is_stopped()

func endDash():
	ghost_timer.stop()
	canDash = false
	yield(get_tree().create_timer(dash_delay), 'timeout')
	canDash = true

func _on_DashTimer_timeout():
	endDash()

func _on_GhostTimer_timeout():
	instanceGhost()
