class_name TestTree extends Node
tool # So that the test scenes can be collected and displayed in the editor.

# This is the core class for collecting and running `TestNode`s.
# Scenes are collected automatically upon instantiation within the project by default.
# You can extend this to create test suites covering different parts of the project.

signal tests_finished(result) # pass or fail.

# A directory within the project where test scenes are searched for recursively.
# Multiple directories are not supported by design.
# Create multiple `TestTree`s if you want to have your tests run in different places.
export(String, DIR) var directory = "res://"

# The pattern used to recognize scene files while collecting them.
# Note: this does not include the scene extension, which is appended automatically.
export var search_pattern := "test_*"

# Runs the test scenes automatically upon instantiation in `_ready()`.
export var autorun := true

# If an error occurs, pauses the execution of the code for further inspection.
# The execution is halted in the editor by default.
# If running the scene via the command-line, include `--debug` option.
# Individual `TestNode`s abide by this property.
export var debug_break := true

# Time in seconds to pause before instantiating a new test scene.
export(float, 0.0, 5.0) var pre_delay := 0.0
# Time in seconds to pause before testing the next scene.
export(float, 0.0, 5.0) var post_delay := 0.0

# Utility methods.
var methods = preload("methods.gd")

# Test scenes may yield.
var wait_funcs = []


func _enter_tree():
	collect_scenes()


func _ready():
	if autorun:
		test()


# Called before running any test scenes.
func before_test():
	pass

# Called after all detected scenes get tested.
func after_test():
	pass


func collect_scenes():
	assert(methods.dir_exists(directory))

	for res in $scenes.get_resource_list():
		$scenes.remove_resource(res)

	if OS.has_feature("standalone"):
		# This will not work in exported projects.
		# The test scenes must be updated manually in debug builds first,
		# so that `$scenes` will contain all the necessary scene paths.
		return

	if filename.find("addons") != -1:
		# Do not collect scenes if opening from `addons/` folder.
		# You must inherit `groot.tscn` in order to use it.
		return

	# Append `scn` to recognize both text (`tscn`) and binary (`scn`) files.
	var filter = search_pattern + "scn"
	var scene_files = methods.get_files_recursive(directory, filter)
	for path in scene_files:
		if OS.is_stdout_verbose():
			print("Loading scene: %s" % path)
		var scene = load(path)
		if not _scene_inherits_test_node(scene):
			continue
		$scenes.add_resource(path, scene)


func _scene_inherits_test_node(p_scene: PackedScene):
	var state = p_scene.get_state() as SceneState
	if state.get_node_count() > 0:
		for prop_idx in state.get_node_property_count(0): # Should be root.
			var prop_name = state.get_node_property_name(0, prop_idx)
			if prop_name == "script":
				var base = state.get_node_property_value(0, prop_idx).get_base_script()
				if base == TestNode or base == TestNode2D:
					return true
		# If the above doesn't work, check if the test scene is `PackedScene`.
		# This check should be done last, because the base scene may not have
		# `TestNode` script attached.
		var root = state.get_node_instance(0)
		if root is PackedScene:
			return _scene_inherits_test_node(root)
	return false


func test():
	if Engine.editor_hint:
		# Not supported by design.
		return

	before_test()

	var result = true
	wait_funcs.clear()

	var test_scenes_list = Array($scenes.get_resource_list())
	# Run similar tests closer to each other, makes testing more deterministic.
	test_scenes_list.sort()

	for s in test_scenes_list:
		var scene = $scenes.get_resource(s) as PackedScene
		assert(scene, "Bug: expected a scene!")

		if pre_delay > 0:
			yield(get_tree().create_timer(pre_delay), "timeout")

		var test_scene = scene.instance()
		test_scene.tree = self

		# Adding and removing a scene is the core logic behind testing in Groot.
		# Everything else must be handled by the scene's respective callbacks
		# by making assertions in `_ready()`, `_enter_tree()`, `_exit_tree()`,
		# or assertions in `test_*()` methods specified by `TestNode.test_prefix`.
		add_child(test_scene)

		# Make sure that all methods are called, so that the test tree does not
		# go for testing another scene before finishing this one prematurely.
		if test_scene.duration > 0.0:
			yield(test_scene, "completed")

		# Functions may yield, so we also need to wait for those functions to complete.
		# Note that the following is intended to help with `test_*` methods and may
		# not work if you yield within callbacks such as `_ready`. If that's the case,
		# you can set maximum test scene `duration`, or explicitly notify the test tree
		# to wait for those functions with `TestNode.wait_for` method.
		while not wait_funcs.empty():
			var state = wait_funcs.pop_back()
			if state.is_valid():
				yield(state, "completed")

		# If any test fail, mark the result as failing too.
		var test_passed = test_scene.get_fail_count() == 0
		if not test_scene.pending:
			result = result and test_passed

		print(test_scene.get_summary_text())

		if post_delay > 0:
			yield(get_tree().create_timer(post_delay), "timeout")

		# Cleanup!
		test_scene.queue_free()

	emit_signal("tests_finished", result)

	if result:
		print("All tests passed!")
	else:
		print("ERROR: some tests have failed.")

	after_test()

	return result
