extends EditorInspectorPlugin

var _animation_player: AnimationPlayer

func can_handle(object):
	return object is AnimationPlayer


func parse_begin(object):
	_animation_player = object


func parse_end():
	var control_instance =	preload("res://addons/animationplayer_spriteframes_helper/ash_inspector/ash_inspector.tscn").instance()
	control_instance.set("animation_player", _animation_player)
	var ep = EditorProperty.new()
	ep.add_child(control_instance)
	ep.set_bottom_editor(control_instance)
	add_custom_control(ep)
	