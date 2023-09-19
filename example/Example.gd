extends Node3D

@onready var settings_panel = $SettingsPanel
@onready var progress_bar = $ProgressBar

func _ready():
	OBJExporter.export_started.connect(_on_export_started)
	OBJExporter.export_completed.connect(_on_export_completed)
	OBJExporter.export_progress_updated.connect(_on_export_progress)
	
	progress_bar.hide()


func _on_export_started():
	print("Export started")
	
	settings_panel.hide()
	progress_bar.value = 0.0
	progress_bar.show()



func _on_export_completed(obj_file, mat_file):
	print("Export completed: ", obj_file, ", ", mat_file)
	
	settings_panel.show()
	progress_bar.hide()



func _on_export_progress(surf_idx, progress_value):
	print("Surf(%d): %s" % [surf_idx, str(progress_value)])
	
	progress_bar.value = progress_value * 100.0


func _on_button_pressed():
	OBJExporter.save_mesh_to_files($MeshInstance3D.mesh, $SettingsPanel/EditPath.text, $SettingsPanel/EditFilename.text)
