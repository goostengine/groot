extends EditorScript
tool

const TYPES = [
	'Node2D',
]

func _run():
	var base_dir = get_script().resource_path.get_base_dir()
	var source = base_dir.plus_file("test_node.gd")

	var notice = "# NOTE: This file is GENERATED, edit test_node.gd instead!\n"

	var r = File.new()
	r.open(source, File.READ)
	var script = r.get_as_text()
	r.close()

	for type in TYPES:
		print_debug("Writing TestNode code for: " + type)
		var target

		match type:
			"Node2D":
				target = base_dir.plus_file("test_node_2d.gd")

		assert(target != null)

		var w = File.new()
		w.open(target, File.WRITE)
		w.store_line(notice)
		w.store_string(script.replace("Node", type))
