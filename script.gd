extends Node2D

var speed = 100
var velocity = Vector2()
var gravity = 2000
var direction = Vector2(1, 0)


var screen_size = Vector2()
var window_size = Vector2(200, 200)
var mouse_pos = Vector2()
var last_mos_pos = Vector2()
var usable_win = DisplayServer.screen_get_usable_rect()
var taskbar_y = usable_win.end.y

var time_since_idle = 0.0
var is_idling = false
var is_falling = true
var is_recovering = false

var is_dragging = false
var drag_offset = Vector2()

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D


func _ready():
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("senku_dragged")
	area.input_event.connect(_on_area_input)
	

func _physics_process(delta: float) -> void:
	
	var sprite_frames: SpriteFrames = $AnimatedSprite2D.sprite_frames
	var current_frame: String = $AnimatedSprite2D.animation
	var last_frame_index: int = sprite_frames.get_frame_count(current_frame) - 1
	
	var window_position = Vector2(DisplayServer.window_get_position())
	
	if is_dragging:
		mouse_pos = Vector2(DisplayServer.mouse_get_position())
		velocity = (mouse_pos - last_mos_pos) / delta / 2
		last_mos_pos = mouse_pos
		
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		return
	
	if is_falling:
		velocity.y += gravity * delta
	
		window_position += velocity * delta
		
		window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
		window_position.y = clamp(window_position.y, 0, taskbar_y - window_size.y)
		DisplayServer.window_set_position(Vector2i(window_position))
		
		if window_position.y == 0:
			velocity.y = 0
		else:
			velocity.lerp(Vector2.ZERO, 2 * delta)
			
		
		if window_position.y == taskbar_y - window_size.y:
			is_falling = false
			is_recovering = true
			print("is recovering")
			animated_sprite.play("senku_recover")
		return
	
	if is_recovering:
		if $AnimatedSprite2D.frame == last_frame_index:
			is_recovering = false
			animated_sprite.play("senku_walk")
		return
		
	if is_idling:
		if $AnimatedSprite2D.frame == last_frame_index:
			is_idling = false
			speed = 100
			animated_sprite.play("senku_walk")
		return
	
	window_position += direction * speed * delta
	#print(window_position)
	
	window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
	window_position.y = clamp(window_position.y, 0, taskbar_y - window_size.y)
	DisplayServer.window_set_position(Vector2i(window_position))
	if window_position.x <= 0 or window_position.x >= screen_size.x - window_size.x:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
	
	time_since_idle += delta
	#print(time_since_idle)
	if time_since_idle >= 5:
		maybe_idle()
	
	

func maybe_idle():
	if randf() < 0.02:
		is_idling = true
		time_since_idle = 0
		var r = randi() % 3
		if r == 0:
			animated_sprite.play("senku_earpicking")
			speed = 0
		if r == 1:
			animated_sprite.play("senku_reading")
		if r == 2:
			animated_sprite.play("senku_stand")

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_idling = false
			animated_sprite.play("senku_dragged")
			is_dragging = true
			
			mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false
			is_falling = true
			print("is falling")
