tool
extends Control

export(SpriteFrames) var sprite_frames: SpriteFrames
export(String) var animation_name: String
export(NodePath) var fps_value_label: NodePath
export(NodePath) var looping_value_label: NodePath
export(NodePath) var frame_count_label: NodePath
export(NodePath) var animation_preview_texture_rect: NodePath

var _current_frame: int = 0
var _time_since_last_frame: float = 0

onready var _fps_value_label: Label = get_node(fps_value_label)
onready var _looping_value_label: Label = get_node(looping_value_label)
onready var _frame_count_label: Label = get_node(frame_count_label)
onready var _animation_preview_texture_rect: TextureRect = get_node(animation_preview_texture_rect)


func _ready():
	if not sprite_frames || not animation_name:
		return
	set_data({"frames": sprite_frames, "name": animation_name})


func _process(delta):
		if not _animation_preview_texture_rect || not sprite_frames || not animation_name:
			return
		
		if sprite_frames.get_animation_speed(animation_name) == 0.0:
			return

		if sprite_frames.get_frame_count(animation_name) == 0:
				return

		_time_since_last_frame += delta;
		if _time_since_last_frame > 1.0 / sprite_frames.get_animation_speed(animation_name):
			_current_frame = (_current_frame + 1) % sprite_frames.get_frame_count(animation_name)
			_time_since_last_frame = 0;
			_animation_preview_texture_rect.texture = sprite_frames.get_frame(animation_name, _current_frame)


func set_data(d :Dictionary):
	sprite_frames = d["frames"]
	animation_name = d["name"]
	_fps_value_label.text = "%d" % sprite_frames.get_animation_speed(animation_name)
	_looping_value_label.text =  _is_looping(); 
	_frame_count_label.text = "%d" % sprite_frames.get_frame_count(animation_name)
	_animation_preview_texture_rect.texture = sprite_frames.get_frame(animation_name, _current_frame)


func _is_looping() -> String:
	if not sprite_frames:
		return "not looping"

	if sprite_frames.get_animation_loop(animation_name):
		return "looping"
	return "not looping"


