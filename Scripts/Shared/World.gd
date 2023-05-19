extends Node2D

const gallery_image = preload("res://Scenes/World/GalleryImage.tscn")

export var time_slow   = 0.07
export var time_freeze = 0.2

onready var morea          = $Battle/Morea
onready var morea_health   = $Battle/UI/MoreaUI/MoreaHealth
onready var lester         = $Battle/Lester
onready var heartUIFull    = $Battle/UI/LesterUI/HeartFull
onready var heartUIEmpty   = $Battle/UI/LesterUI/HeartEmpty
onready var ui             = $Battle/UI
onready var menu           = $Menu
onready var menu_music     = $Menu/MenuMusic
onready var battle_music   = $Battle/BattleMusic
onready var gallery        = $Gallery
onready var gallery_wall   = $Gallery/Gallery/ScrollContainer/GalleryWall
onready var controls       = $Gallery/Gallery/Controls

var game_state = global_game_state
var hearts     = 10 setget set_hearts
var max_hearts = 10 setget set_max_hearts

func _ready():
	morea.connect("morea_hit", self, "morea_hit")
	morea.connect("morea_dead",self, "handle_game_end")
	lester.connect("lester_hit",self, "lester_hit")
	lester.connect("lester_dead",self, "handle_game_end")
	menu_music.play()
	ui.hide()
	gallery.hide()
	controls.hide()
	game_state.playing = false
	
func handle_game_end():
	ui.hide()
	add_to_gallery()
	yield(get_tree().create_timer(.5), 'timeout')
	ui.show()
	menu.show()
	morea.position  = Vector2(320,50)
	lester.position = Vector2(320, 272)
	morea.game_reset()
	lester.game_reset()
	set_hearts(lester.HEALTH)
	morea_health.value = morea.HEALTH
	battle_music.stop()
	menu_music.play()
	

##Background Image --> Photo by https://unsplash.com/@kiwihug?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText -- Kiwihug
##Credit to Sylvain22 on godot forum > https://godotengine.org/qa/21862/how-to-take-screenshot-of-the-game-and-use-as-texture-on-sprite
func add_to_gallery():
	#store current clear mode, capture screen, & wait for visual server to draw frame.
	var clear_mode = get_viewport().get_clear_mode()
	get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	# Wait until the frame has finished before getting the texture.
	yield(VisualServer, "frame_post_draw")
	
	#var viewport_size = get_viewport().get_visible_rect().size
	var texture       = get_viewport().get_texture()
	var img           = texture.get_data()
	img.resize(200,112,1)
	
	img.flip_y()
	get_viewport().set_clear_mode(clear_mode)
	# Create a texture for it.
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	
	# Set the texture to the captured image node.
	var gallery_image_instance = gallery_image.instance()
	gallery_image_instance.set_texture(tex)
	gallery_wall.add_child(gallery_image_instance)

func lester_hit():
	set_hearts(lester.HEALTH)
	
func morea_hit():
	morea_health.value = morea.HEALTH
	time_slowdown()

func time_slowdown():
	Engine.time_scale = time_slow
	yield(get_tree().create_timer(time_freeze * time_slow), "timeout")
	Engine.time_scale = 1

func set_hearts(value):
	hearts = clamp(value, 0, max_hearts)
	if heartUIFull != null:
		heartUIFull.rect_size.x = hearts * 32
	
func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = min(hearts, max_hearts)
	if heartUIEmpty != null:
		heartUIEmpty.rect_size.x = max_hearts * 32

func _on_Battle_pressed():
	menu.hide()
	menu_music.stop()
	ui.show()
	battle_music.play()
	game_state.playing = true

func _on_Gallery_pressed():
	gallery.show()


func _on_CloseGallery_pressed():
	gallery_wall.show()
	gallery.hide()
	controls.hide()


func _on_Controls_pressed():
	gallery.show()
	gallery_wall.hide()
	controls.show()
