@tool
extends EditorScript

func _run():
	var script = load("res://JunkScenes/%d.tscn")
	for i in range(1, 38):  # loop 1–37
		var path = "res://JunkScenes/%d.tscn" % i
		var packed: PackedScene = load(path)
		if not packed:
			print("⚠️ Could not load scene at ", path)
			continue

		# Unpack scene to a Node3D
		var scene = packed.instantiate()
		if not scene or not (scene is Node3D):
			print("⚠️ Scene at ", path, " is not a Node3D")
			continue

		# Only assign if no script is attached
		if scene.get_script() == null:
			scene.set_script(script)

		# Pack the modified scene back
		var new_packed = PackedScene.new()
		var ok = new_packed.pack(scene)
		if ok != OK:
			print("⚠️ Failed to pack scene at ", path)
			continue

		# Save correctly: ResourceSaver.save(resource, path)
		var result = ResourceSaver.save(new_packed, path)
		if result == OK:
			print("✅ Assigned SpaceJunk.gd to ", path)
		else:
			print("❌ Failed to save scene at ", path)
