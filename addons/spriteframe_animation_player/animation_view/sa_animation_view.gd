tool
class_name SpriteFramesAnimationView
extends Control

export(SpriteFrames) var sprite_frames: SpriteFrames
export(String) var animation_name: String

export(NodePath) var _fps_value_label: NodePath
onready var fps_value_label: Label = get_node(_fps_value_label)

export(NodePath) var _looping_value_label: NodePath
onready var looping_value_label: Label = get_node(_looping_value_label)

export(NodePath) var _frame_count_label: NodePath
onready var frame_count_label: Label = get_node(_frame_count_label)

export(NodePath) var _animation_preview_texture_rect: NodePath
onready var animation_preview_texture_rect: TextureRect = get_node(_animation_preview_texture_rect)

var current_frame: int = 0
var time_since_last_frame: float = 0

func _ready():
	if not sprite_frames || not animation_name:
		return
	set_data({"frames": sprite_frames, "name": animation_name})

func set_data(d :Dictionary):
	sprite_frames = d["frames"]
	animation_name = d["name"]
	fps_value_label.text = "%d" % sprite_frames.get_animation_speed(animation_name)
	looping_value_label.text =  _is_looping(); 
	frame_count_label.text = "%d" % sprite_frames.get_frame_count(animation_name)
	animation_preview_texture_rect.texture = sprite_frames.get_frame(animation_name, current_frame)

func _is_looping() -> String:
	if not sprite_frames:
		return "not looping"

	if sprite_frames.get_animation_loop(animation_name):
		return "looping"
	return "not looping"

func _process(delta):
	if not animation_preview_texture_rect || not sprite_frames || not animation_name:
		return

	time_since_last_frame += delta;
	if time_since_last_frame > 1.0 / sprite_frames.get_animation_speed(animation_name):
		current_frame = (current_frame + 1) % sprite_frames.get_frame_count(animation_name)
		time_since_last_frame = 0;
		animation_preview_texture_rect.texture = sprite_frames.get_frame(animation_name, current_frame)
