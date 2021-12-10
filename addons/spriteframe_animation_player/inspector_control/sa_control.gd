tool
class_name SpriteFrameAnimationPlayerControl
extends Control

export(NodePath) var refresh_button: NodePath
onready var _refresh_button: Button = get_node(refresh_button)

export(NodePath) var assigned_animation_option_button: NodePath
onready var _assigned_animation_option_button: OptionButton = get_node(assigned_animation_option_button)

export(NodePath) var _option_button: NodePath
onready var option_button: OptionButton = get_node(_option_button)

export(NodePath) var _current_animation_preview: NodePath
onready var current_animation_preview: SpriteFramesAnimationViewContainer = get_node(_current_animation_preview)

export(NodePath) var _option_button_container: NodePath
onready var option_button_container: Control = get_node(_option_button_container)

export(NodePath) var _insert_button: NodePath
onready var insert_button: Button = get_node(_insert_button)

export(NodePath) var _fill_toggle: NodePath
onready var fill_toggle: CheckBox = get_node(_fill_toggle)

var animation_player: AnimationPlayer
var previous_animation: String

func _ready():
	_refresh_button.connect("pressed", self, "refresh_animation")
	option_button.connect("item_selected", self, "on_item_selected")
	insert_button.connect("pressed", self, "insert_track")
	_assigned_animation_option_button.connect("item_selected", self, "on_animation_assigned")
	if not animation_player:
		return
	var anims = animation_player.get_animation_list()
	for a in anims:
		_assigned_animation_option_button.add_item(a)
		if animation_player.assigned_animation == a:
			var i := _assigned_animation_option_button.get_item_count()- 1
			_assigned_animation_option_button.select(i)
			refresh_animation()

func on_animation_assigned(idx: int) -> void:
	animation_player.assigned_animation = _assigned_animation_option_button.get_item_text(idx)
	refresh_animation()

func cleanup():
	option_button.clear()

func animation_player_root_node() -> Node:
	return animation_player.get_node(animation_player.root_node)

func refresh_animation():
	if not animation_player.assigned_animation:
		return

	cleanup()
	previous_animation = animation_player.assigned_animation
	var animation: Animation = animation_player.get_animation(animation_player.assigned_animation)
	var tc := animation.get_track_count()
	if tc == 0:
		current_animation_preview.visible = false
		insert_button.visible = false
		return
	
	var visited_nodes: Dictionary = {}
	for i in tc:
		var path := animation.track_get_path(i)
		var node := animation_player_root_node().get_node(path) as AnimatedSprite
		if node == null || visited_nodes.has(node):
			continue
		visited_nodes[node] = null
		var animated_sprite = node as AnimatedSprite
		option_button.add_item(animated_sprite.name)
		option_button.set_item_metadata(option_button.get_item_count()-1, {"frames": animated_sprite.frames, "node": animated_sprite})
	
	option_button_container.visible = option_button.get_item_count() > 0
	if option_button.get_item_count() <= 0:
		current_animation_preview.visible = false
		insert_button.visible = false
		return

	current_animation_preview.visible = true
	insert_button.visible = true
	on_item_selected(0)

		
func on_item_selected(idx: int) -> void:
	current_animation_preview.sprite_frames = option_button.get_item_metadata(idx)["frames"]

func _exit_tree():
	cleanup()

func insert_track() -> void:
	var sm = option_button.get_selected_metadata()
	var frames: SpriteFrames = sm["frames"]
	var target_node: AnimatedSprite = sm["node"]
	var target_node_path: = animation_player_root_node().get_path_to(target_node)
	var target_animation := animation_player.get_animation(animation_player.assigned_animation)
	var source_animation := current_animation_preview.get_current_animation()

	# first get all target_tracks
	var target_tracks := []
	var tc := target_animation.get_track_count()
	for i in tc:
		var path := target_animation.track_get_path(i)
		var node := animation_player_root_node().get_node(path) as AnimatedSprite
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
		should_exit = !fill_toggle.pressed || t >= target_animation.length
	
# func _process(delta):
# 	if not animation_player:
# 		return

# 	if animation_player.assigned_animation == previous_animation:
# 		return
# 	refresh_animation()
