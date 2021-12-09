tool
class_name SpriteFramesAnimationViewContainer
extends Control

export(SpriteFrames) var sprite_frames: SpriteFrames setget _set_sprite_frames, _get_sprite_frames
var _sprite_frames: SpriteFrames

export(NodePath) var _option_button: NodePath
onready var option_button: OptionButton = get_node(_option_button)

export(NodePath) var _animation_view: NodePath
onready var animation_view: SpriteFramesAnimationView = get_node(_animation_view)

func _set_sprite_frames(sf: SpriteFrames):
	_sprite_frames = sf
	_apply_sprite_frames()

func _get_sprite_frames() -> SpriteFrames:
	return _sprite_frames

func _ready():
		option_button.connect("item_selected", self, "on_item_selected")

func cleanup():
	option_button.clear()

func _apply_sprite_frames() -> void:
	cleanup()

	if not _sprite_frames:
		animation_view.visible = false
		return

	for a in _sprite_frames.get_animation_names():
		option_button.add_item(a)
		option_button.set_item_metadata(option_button.get_item_count()-1, {"frames": _sprite_frames, "name": a})

	if option_button.get_item_count() > 0:
			on_item_selected(0)

func on_item_selected(idx: int):
	animation_view.visible = true
	animation_view.set_data( option_button.get_item_metadata(idx))

func _exit_tree():
	cleanup()