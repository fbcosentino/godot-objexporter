@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("OBJExporter", "res://addons/obj_exporter/OBJExporter.tscn")


func _exit_tree():
	remove_autoload_singleton("OBJExporter")
