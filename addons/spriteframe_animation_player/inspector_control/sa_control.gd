tool
class_name SpriteFrameAnimationPlayerControl
extends Control

export var assigned_animation_label: NodePath
onready var _assigned_animation_label: Label = get_node(assigned_animation_label)

export(NodePath) var _animator_select_button: NodePath
onready var animator_select_button: OptionButton = get_node(_animator_select_button)

export(NodePath) var _current_animation_preview_container: NodePath
onready var current_animation_preview_container: Control = get_node(_current_animation_preview_container)

var animation_previews: Array

var animation_player: AnimationPlayer
var previous_animation: String

var spriteframes_view_res: PackedScene = load("res://addons/spriteframe_animation_player/spriteframes_view/sa_spriteframes_view.tscn")

func _ready():
	$PanelContainer/VBoxContainer/Button.connect("pressed", self, "refresh_animation")
	animator_select_button.connect("item_selected", self, "on_animator_item_selected")
	

func refresh_animation():
	for i in animator_select_button.get_item_count():
		animator_select_button.remove_item(i)

	for c in animation_previews:
		c.queue_free()

	if not animation_player.assigned_animation:
		return

	previous_animation = animation_player.assigned_animation
	_assigned_animation_label.text = animation_player.assigned_animation
	var animation: Animation = animation_player.get_animation(animation_player.assigned_animation)
	var tc := animation.get_track_count()
	if tc == 0:
		return

	var found := false
	for i in tc:
		var path := animation.track_get_path(i)
		var node := animation_player.get_tree().edited_scene_root.get_node(path) as AnimatedSprite
		if node == null:
			continue
		var animated_sprite = node as AnimatedSprite
		var sfv: SpriteFramesAnimationViewContainer = spriteframes_view_res.instance()
		sfv.sprite_frames = animated_sprite.frames
		animation_previews.append(sfv)
		animator_select_button.add_item(animated_sprite.name)
	on_animator_item_selected(0)
		
func on_animator_item_selected(idx: int) -> void:
	if current_animation_preview_container.get_child_count() > 0:
		current_animation_preview_container.remove_child(current_animation_preview_container.get_child(0))
	current_animation_preview_container.add_child(animation_previews[idx])

func _exit_tree():
	for c in animation_previews:
		c.queue_free()

# func _process(delta):
# 	if not animation_player:
# 		return

# 	if animation_player.assigned_animation == previous_animation:
# 		return
# 	refresh_animation()
