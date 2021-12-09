tool
class_name SpriteFrameAnimationPlayerControl
extends Control

export var assigned_animation_label: NodePath
onready var _assigned_animation_label: Label = get_node(assigned_animation_label)

export(NodePath) var _option_button: NodePath
onready var option_button: OptionButton = get_node(_option_button)

export(NodePath) var _current_animation_preview: NodePath
onready var current_animation_preview: SpriteFramesAnimationViewContainer = get_node(_current_animation_preview)

export(NodePath) var _option_button_container: NodePath
onready var option_button_container: Control = get_node(_option_button_container)

var animation_player: AnimationPlayer
var previous_animation: String

func _ready():
	$PanelContainer/VBoxContainer/Button.connect("pressed", self, "refresh_animation")
	option_button.connect("item_selected", self, "on_item_selected")
	
func cleanup():
	option_button.clear()

func refresh_animation():
	if not animation_player.assigned_animation:
		return

	cleanup()
	previous_animation = animation_player.assigned_animation
	_assigned_animation_label.text = animation_player.assigned_animation
	var animation: Animation = animation_player.get_animation(animation_player.assigned_animation)
	var tc := animation.get_track_count()
	if tc == 0:
		current_animation_preview.visible = false
		return

	for i in tc:
		var path := animation.track_get_path(i)
		var node := animation_player.get_tree().edited_scene_root.get_node(path) as AnimatedSprite
		if node == null:
			continue
		var animated_sprite = node as AnimatedSprite
		option_button.add_item(animated_sprite.name)
		option_button.set_item_metadata(option_button.get_item_count()-1, animated_sprite.frames)
	
	option_button_container.visible = option_button.get_item_count() > 0
	if option_button.get_item_count() <= 0:
		current_animation_preview.visible = false
		return

	current_animation_preview.visible = true
	on_item_selected(0)

		
func on_item_selected(idx: int) -> void:
	current_animation_preview.sprite_frames = option_button.get_item_metadata(idx)

func _exit_tree():
	cleanup()

# func _process(delta):
# 	if not animation_player:
# 		return

# 	if animation_player.assigned_animation == previous_animation:
# 		return
# 	refresh_animation()
