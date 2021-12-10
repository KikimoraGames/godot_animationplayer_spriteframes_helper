tool
class_name SpriteFrameAnimationPlayerControl
extends Control

export(NodePath) var refresh_button: NodePath
export(NodePath) var assigned_animation_option_button: NodePath
export(NodePath) var option_button: NodePath
export(NodePath) var current_animation_preview: NodePath
export(NodePath) var option_button_container: NodePath
export(NodePath) var insert_button: NodePath
export(NodePath) var fill_toggle: NodePath
export(NodePath) var insert_control: NodePath
export(NodePath) var set_animation_length_toggle: NodePath
export(NodePath) var set_looping_toggle: NodePath

var _previous_animation: String

onready var _refresh_button: Button = get_node(refresh_button)
onready var _assigned_animation_option_button: OptionButton = get_node(assigned_animation_option_button)
onready var _option_button: OptionButton = get_node(option_button)
onready var _current_animation_preview: SpriteFramesAnimationViewContainer = get_node(current_animation_preview)
onready var _option_button_container: Control = get_node(option_button_container)
onready var _insert_button: Button = get_node(insert_button)
onready var _fill_toggle: CheckBox = get_node(fill_toggle)
onready var _insert_control: Control = get_node(insert_control)
onready var _set_animation_length_toggle: CheckBox = get_node(set_animation_length_toggle)
onready var _set_looping_toggle: CheckBox = get_node(set_looping_toggle)

var animation_player: AnimationPlayer


func _ready():
	_refresh_button.connect("pressed", self, "refresh_animation")
	_option_button.connect("item_selected", self, "on_item_selected")
	_insert_button.connect("pressed", self, "insert_track")
	_assigned_animation_option_button.connect("item_selected", self, "_on_animation_assigned")
	if not animation_player:
		return
	var anims = animation_player.get_animation_list()
	for a in anims:
		_assigned_animation_option_button.add_item(a)
		if animation_player.assigned_animation == a:
			var i := _assigned_animation_option_button.get_item_count()- 1
			_assigned_animation_option_button.select(i)
			refresh_animation()


func _exit_tree():
	_cleanup()


func _on_animation_assigned(idx: int) -> void:
	animation_player.assigned_animation = _assigned_animation_option_button.get_item_text(idx)
	refresh_animation()


func _cleanup():
	_option_button.clear()


func _animation_player_root_node() -> Node:
	return animation_player.get_node(animation_player.root_node)


func toggle_controls_visible(v: bool) -> void:
	_current_animation_preview.visible = v
	_insert_button.visible = v
	_insert_control.visible = v


func refresh_animation():
	if not animation_player.assigned_animation:
		return

	_cleanup()
	_previous_animation = animation_player.assigned_animation
	var animation: Animation = animation_player.get_animation(animation_player.assigned_animation)
	var tc := animation.get_track_count()
	if tc == 0:
		toggle_controls_visible(false)
		return
	
	var visited_nodes: Dictionary = {}
	for i in tc:
		var path := animation.track_get_path(i)
		var node := _animation_player_root_node().get_node(path) as AnimatedSprite
		if node == null || visited_nodes.has(node):
			continue
		visited_nodes[node] = null
		var animated_sprite = node as AnimatedSprite
		_option_button.add_item(animated_sprite.name)
		_option_button.set_item_metadata(_option_button.get_item_count()-1, {"frames": animated_sprite.frames, "node": animated_sprite})
	
	_option_button_container.visible = _option_button.get_item_count() > 0
	if _option_button.get_item_count() <= 0:
		toggle_controls_visible(false)
		return

	toggle_controls_visible(true)
	on_item_selected(0)

		
func on_item_selected(idx: int) -> void:
	_current_animation_preview.sprite_frames = _option_button.get_item_metadata(idx)["frames"]



func insert_track() -> void:
	var sm = _option_button.get_selected_metadata()
	var frames: SpriteFrames = sm["frames"]
	var target_node: AnimatedSprite = sm["node"]
	var target_node_path: = _animation_player_root_node().get_path_to(target_node)
	var target_animation := animation_player.get_animation(animation_player.assigned_animation)
	var source_animation := _current_animation_preview.get_current_animation()

	# first get all target_tracks
	var target_tracks := []
	var tc := target_animation.get_track_count()
	for i in tc:
		var path := target_animation.track_get_path(i)
		var node := _animation_player_root_node().get_node(path) as AnimatedSprite
		if node == null || node != target_node:
			continue
		target_tracks.append({"path": path, "idx": i})
	
	# clear all existing tracks for "frames", "animation", "frame"
	target_tracks.invert()
	for path_idx in target_tracks:
		var p: NodePath = path_idx["path"]
		var found := false
		for i in p.get_subname_count():
			var sn := p.get_subname(i)
			if sn == "frames" ||  sn == "animation" || sn == "frame":
				found = true
				break
		if (found):
			target_animation.remove_track(path_idx["idx"])
	
	# add keys for "frames", "animation"
	for k in [{"property": "frames", "value": frames}, {"property":"animation", "value": source_animation}]:
		var np := ""
		for n in target_node_path.get_name_count():
			np += "%s/" % target_node_path.get_name(n)
		np += ":%s" % k["property"]
		var idx := target_animation.add_track(Animation.TYPE_VALUE)
		target_animation.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
		target_animation.track_set_path(idx, np)
		target_animation.track_insert_key(idx, 0.0, k["value"])
	
	# add key frames for "frame"
	var frequency := 1.0 / frames.get_animation_speed(source_animation)
	var frame_track := target_animation.add_track(Animation.TYPE_VALUE)
	var np := ""
	for n in target_node_path.get_name_count():
		np += "%s/" % target_node_path.get_name(n)
	np += ":frame"
	target_animation.track_set_path(frame_track, np)
	target_animation.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
	
	var t := 0.0
	var should_exit := false
	while not should_exit:
		for frame in frames.get_frame_count(source_animation):
			target_animation.track_insert_key(frame_track, t, frame)
			t += frequency
		should_exit = !_fill_toggle.pressed || t >= target_animation.length
	
	if _set_animation_length_toggle.pressed:
		target_animation.length = t
	
	if _set_looping_toggle.pressed:
			target_animation.loop = frames.get_animation_loop(source_animation)
