tool
class_name SpriteFramesAnimationViewContainer
extends Control

export(SpriteFrames) var sprite_frames: SpriteFrames

export(NodePath) var _option_button: NodePath
onready var option_button: OptionButton = get_node(_option_button)

export(NodePath) var _preview_container: NodePath
onready var preview_container: Control = get_node(_preview_container)

var animation_view_res: PackedScene = load("res://addons/spriteframe_animation_player/animation_view/sa_animation_view.tscn")
var animation_previews: Array

func _ready():
	option_button.connect("item_selected", self, "on_item_selected")

	for a in sprite_frames.get_animation_names():
		var av: SpriteFramesAnimationView = animation_view_res.instance()
		av.sprite_frames = sprite_frames
		av.animation_name = a
		animation_previews.append(av)
		option_button.add_item(a)

	on_item_selected(0)
		
func on_item_selected(idx: int):
	if preview_container.get_child_count() > 0:
		preview_container.remove_child(preview_container.get_child(0))
	preview_container.add_child(animation_previews[idx])