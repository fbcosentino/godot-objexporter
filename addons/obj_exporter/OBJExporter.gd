extends Node

signal export_started
signal export_progress_updated(surf_idx, progress_value)
signal export_completed(object_file, material_file)

# Dump given mesh to obj file
func save_mesh_to_files(mesh: Mesh, file_path: String, object_name: String):
	# Based on:
	# https://github.com/fractilegames/godot-obj-export/blob/main/objexport.gd
	# https://github.com/mohammedzero43/CSGExport-Godot/blob/master/addons/CSGExport/csgexport.gd
	
	emit_signal("export_started")
	
	# Blank material, used when no material is assigned to mesh
	var blank_material = StandardMaterial3D.new()
	blank_material.resource_name = "BlankMaterial"
	
	var output = "mtllib "+object_name+".mtl\no " + object_name + "\n"
	var mat_output := ""
	
	# Write all surfaces in mesh (obj file indices start from 1)
	var index_base = 1
	for s in range(mesh.get_surface_count()):
		
		var surface = mesh.surface_get_arrays(s)
		if surface[ArrayMesh.ARRAY_INDEX] == null:
			push_warning("Saving only supports indexed meshes for now, skipping non-indexed surface " + str(s))
			continue
		
		var mat: StandardMaterial3D = mesh.surface_get_material(s)

		
		output += "g surface" + str(s) + "\n"
		
		for v in surface[ArrayMesh.ARRAY_VERTEX]:
			output += "v " + str(v.x) + " " + str(v.y) + " " + str(v.z) + "\n"
		
		var has_uv = false
		if surface[ArrayMesh.ARRAY_TEX_UV] != null:
			for uv in surface[ArrayMesh.ARRAY_TEX_UV]:
				output += "vt " + str(uv.x) + " " + str(1.0 - uv.y) + "\n"
			has_uv = true
		
		var has_n = false
		if surface[ArrayMesh.ARRAY_NORMAL] != null:
			for n in surface[ArrayMesh.ARRAY_NORMAL]:
				output += "vn " + str(n.x) + " " + str(n.y) + " " + str(n.z) + "\n"
			has_n = true
		
		
		if mat == null:
			mat = blank_material
		
		output += "usemtl "+str(mat)+"\n"
		
		# Write triangle faces
		# Note: Godot's front face winding order is different from obj file format
		var i = 0
		var indices = surface[ArrayMesh.ARRAY_INDEX]
		var indices_count = indices.size()
		while i < indices_count:
			
			output += "f " + str(index_base + indices[i])
			if has_uv:
				output += "/" + str(index_base + indices[i])
			if has_n:
				if not has_uv:
					output += "/"
				output += "/" + str(index_base + indices[i])
			
			output += " " + str(index_base + indices[i + 2])
			if has_uv:
				output += "/" + str(index_base + indices[i + 2])
			if has_n:
				if not has_uv:
					output += "/"
				output += "/" + str(index_base + indices[i + 2])
			
			output += " " + str(index_base + indices[i + 1])
			if has_uv:
				output += "/" + str(index_base + indices[i + 1])
			if has_n:
				if not has_uv:
					output += "/"
				output += "/" + str(index_base + indices[i + 1])
			
			output += "\n"
			
			if (i % 60) == 0: # Modulo must be multiple of 3 as it's the step
				emit_signal("export_progress_updated", s, i / float(indices_count))
				await get_tree().process_frame
			i += 3
		
		emit_signal("export_progress_updated", s, 1.0)
		
		index_base += surface[ArrayMesh.ARRAY_VERTEX].size()
		
		# Create Materials for current surface
		mat_output += str("newmtl "+str(mat))+'\n'
		mat_output += str("Kd ",mat.albedo_color.r," ",mat.albedo_color.g," ",mat.albedo_color.b)+'\n'
		mat_output += str("Ke ",mat.emission.r," ",mat.emission.g," ",mat.emission.b)+'\n'
		mat_output += str("d ",mat.albedo_color.a)+"\n"
	
	
	if not file_path.ends_with("/"):
		file_path += "/"
	
	var obj_file := file_path + object_name + ".obj"
	var file_obj = FileAccess.open(obj_file, FileAccess.WRITE)
	file_obj.store_string(output)
	
	var mat_file := file_path + object_name + ".mtl"
	var file_mtl = FileAccess.open(mat_file, FileAccess.WRITE)
	file_mtl.store_string(mat_output)
	
	emit_signal("export_completed", obj_file, mat_file)


func load_mesh_from_file(filename: String, material_filename: String = "") -> Mesh:
	# Transparent call to Ezcha's gd-obj
	
	return ObjParse.load_obj(filename, material_filename)
