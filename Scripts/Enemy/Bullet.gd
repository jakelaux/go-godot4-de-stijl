extends Node2D

export var SPEED = 100

func _process(delta):
	position += transform.x * SPEED * delta
	#if bullet offscreen, kill it
	if position.x < get_viewport_rect().position.x or position.x > get_viewport_rect().size.x or position.y < get_viewport_rect().position.y or position.y > get_viewport_rect().size.y:
		queue_free()

func _on_Hitbox_area_entered(area):
	var lester = area.get_parent()
	var dash   = lester.get_node('Dash')
	if dash.isDashing():
		return
	queue_free()

func _on_Hitbox_body_entered(body):
	if body.get_name() == 'TileMap':
		queue_free()
