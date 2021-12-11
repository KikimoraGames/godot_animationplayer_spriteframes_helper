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

var animation_player: AnimationPlayer


func _ready():
	_refresh_button.connect("pressed", self, "refresh_animation")
	_option_button.connect("item_selected", self, "_on_item_selected")
	_insert_button.connect("pressed", self, "_insert_track")
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
	_on_item_selected(0)

		
func _on_item_selected(idx: int) -> void:
	_current_animation_preview.sprite_frames = _option_button.get_item_metadata(idx)["frames"]


func _insert_track() -> void:
	var sm = _option_button.get_selected_metadata()
	var frames: SpriteFrames = sm["frames"]
	var target_node: AnimatedSprite = sm["node"]
	var target_node_path: = _animation_player_root_node().get_path_to(target_node)
	var target_animation := animation_player.get_animation(animation_player.assigned_animation)
	var source_animation := _current_animation_preview.get_current_animation()
	var t := animation_player.current_animation_position

	# first get all target_tracks
	var target_tracks = _get_target_tracks(target_animation, target_node)
	# insert tracks that don't exist
	for k in ["frames", "animation", "frame"]:
		if target_tracks[k] != -1:
			continue

		var idx := target_animation.add_track(Animation.TYPE_VALUE)
		var np := ""
		for n in target_node_path.get_name_count():
			np += "%s/" % target_node_path.get_name(n)
		np += ":%s" % k["property"]
		target_animation.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
		target_animation.track_set_path(idx, np)
		target_tracks[k] = idx
	# calculate total length
	var frequency := 1.0 / frames.get_animation_speed(source_animation)
	var source_animation_frame_count := frames.get_frame_count(source_animation)
	var total_length := target_animation.length - t if _fill_toggle.pressed else frequency * source_animation_frame_count
	var last_keyframe_time := t + total_length
	# clear keyframes during our animation 
	for tt in target_tracks:
		var track_idx :int = target_tracks[tt]
		for key_idx in range (target_animation.track_get_key_count(track_idx)-1, -1, -1):
			var key_time := target_animation.track_get_key_time(track_idx, key_idx)
			if key_time >= t && key_time <= last_keyframe_time:
				target_animation.track_remove_key(track_idx, key_idx)
	# add keys for "frames", "animation"
	for k in[	
				{"property": "frames", "value": frames},
				{"property":"animation", "value": source_animation},
			]:
		target_animation.track_insert_key(target_tracks[k["property"]], t, k["value"])
	# add key frames for "frame"
	var frame_track :int = target_tracks["frame"]
	for frame in source_animation_frame_count:
		frame = frame % source_animation_frame_count
		target_animation.track_insert_key(frame_track, t, frame)
		t += frequency
		if t > last_keyframe_time:
			break
	
	if _set_animation_length_toggle.pressed:
		target_animation.length = t
	
	_set_animation_length_toggle.pressed = false
	_fill_toggle.pressed = false

func _get_target_tracks(target_animation: Animation, target_node: Node) -> Dictionary:
	var target_tracks := []
	var tc := target_animation.get_track_count()
	for i in tc:
		var path := target_animation.track_get_path(i)
		var node := _animation_player_root_node().get_node(path) as AnimatedSprite
		if node == null || node != target_node:
			continue
		target_tracks.append({"path": path, "idx": i})
	
	var output := {}
	for path_idx in target_tracks:
		var p: NodePath = path_idx["path"]
		for i in p.get_subname_count():
			var sn := p.get_subname(i)
			match sn:
				"frames":
					output["frames"] = path_idx["idx"]
					break
				"animation":
					output["animation"] = path_idx["idx"]
					break
				"frame":
					output["frame"] = path_idx["idx"]
					break
	for k in ["frames", "animation", "frame"]:
		if not output.has(k):
			output[k] = -1
	return output