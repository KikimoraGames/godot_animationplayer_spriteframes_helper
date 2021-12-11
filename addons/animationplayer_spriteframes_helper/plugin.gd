tool
extends EditorPlugin

var plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	plugin = preload("res://addons/animationplayer_spriteframes_helper/ash_inspector_plugin.gd").new() 
	add_inspector_plugin(plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(plugin)
