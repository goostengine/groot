class_name TestNode extends Node

# This is the core class which does assertions. Can be run individually or via
# the `TestTree`. Usually, you'll want to create a scene with the `TestNode` as
# root, but they can also be nested. If you nest them, all assertions will be
# called starting from children order all at once, so this is more useful for
# testing data structures that do not necessarily interact with the scene system.
# Parent nodes report the total number of passed and failed asserts from all
# children recursively.

signal completed()

var tree = null # `TestTree`

# What kind of methods can be run automatically within the scene (optional).
# Empty prefix prevents running any pre-defined test methods (not assertions).
export var test_prefix = "test_"

# If enabled, the errors caused by asserts do not affect the test summary.
# The `debug_break` option is ignored as well.
# Note: only relevant for root nodes.
export var pending = false

# If an error occurs, pauses the execution of the code for further inspection.
# The `TestTree` ignores this property and disables this behavior by default.
export var debug_break = true

# The time in seconds this test is allowed to run.
# When the time reaches zero, the `verify()` method is called automatically.
# Note: only relevant for root nodes.
export var duration = 0.0 setget set_duration
func set_duration(p_duration):
	duration = max(0, p_duration)

# Statistics of running test scenes.
var _summary = {
	passed = 0,
	failed = 0,
}
#-------------------------------------------------------------------------------
# Virtual methods
#-------------------------------------------------------------------------------
# Called each time before running any test method.
func before_each():
	pass

# Called before running any tests.
func before_all():
	pass

# Called each time after running any test method.
func after_each():
	pass

# Called after all tests are finished.
func after_all():
	pass


# Called when `duration` reaches zero. By default, no assertions are
# made and this simply notifies the `TestTree` to end the test.
# Note: if you override this method, you must call `end()` function yourself.
func verify():
	end()


# If a child class has any `test_*` methods, those will be called automatically.
func _ready():
	if test_prefix.empty():
		return

	var test_methods = []
	for method in get_script().get_script_method_list():
		if method.name.begins_with(test_prefix):
			test_methods.push_back(method)
	test_methods.sort_custom(self, "_tests_sorter")

	if duration > 0.0:
		get_tree().create_timer(duration).connect("timeout", self, "verify")

	before_all()

	for method in test_methods:
		before_each()
		var state = call(method.name) as GDScriptFunctionState
		if state:
			wait_for(state)
			if state.is_valid():
				yield(state, "completed")
		after_each()

	after_all()


func _tests_sorter(test_a, test_b):
	if test_a.name < test_b.name:
		return true
	return false

#-------------------------------------------------------------------------------
# Public methods
#-------------------------------------------------------------------------------
# Notify the `TestTree` to wait for function to complete before proceeding with
# testing another scene if you use any `yield` statements within the scene.
#
# Note: this is NOT required to call if you `yield` within any `test_*`
# methods, for which this method is called automatically.
#
func wait_for(p_state: GDScriptFunctionState):
	if not tree:
		return
	if not tree.wait_funcs.has(p_state):
		tree.wait_funcs.push_back(p_state)

# Convenience method: `yield(sec(5), "timeout")`
func wait(p_seconds = 1.0):
	return get_tree().create_timer(p_seconds)

# Notify the `TestTree` that the scene finished execution.
func end():
	emit_signal("completed")

#-------------------------------------------------------------------------------
# Assertions
#-------------------------------------------------------------------------------
func check(condition, message = ""):
	if condition:
		_pass(message)
	else:
		_fail(message)


func assert_eq(got, expected, message = ""):
	var text = "got %s, expected to equal %s" % [got, expected]
	if got != expected:
		_fail(text, message)
	else:
		_pass(text, message)


func assert_ne(got, not_expected, message = ""):
	var text = "got %s, which expected to be anything except %s" % [got, not_expected]
	if got == not_expected:
		_fail(text, message)
	else:
		_pass(text, message)


func assert_eq_approx(got, expected, eps, message = ""):
	var text = "got %s, expected to equal %s +/- %s"  % [got, expected, eps]
	if got < (expected - eps) or got > (expected + eps):
		_fail(text, message)
	else:
		_pass(text, message)


func assert_ne_approx(got, not_expected, eps, message = ""):
	var text = "got %s, expected the value to be outside of %s +/- %s" % [got, not_expected, eps]
	if got < (not_expected - eps) or got > (not_expected + eps):
		_pass(text, message)
	else:
		_fail(text, message)


func assert_gt(got, expected, message = ""):
	var text = "got %s, expected to be greater than %s"  % [got, expected]
	if got > expected:
		_pass(text, message)
	else:
		_fail(text, message)


func assert_lt(got, expected, message = ""):
	var text = "got %s, expected to be less than %s"  % [got, expected]
	if got < expected:
		_pass(text, message)
	else:
		_fail(text, message)


func assert_true(got, message = ""):
	if got == true:
		_pass(message)
	else:
		_fail(message)


func assert_false(got, message = ""):
	if got == false:
		_pass(message)
	else:
		_fail(message)


func assert_between(got, expect_low, expect_high, message = ""):
	var text = "got %s, expected to be between %s and %s" % [got, expect_low, expect_high]
	if expect_low > expect_high:
		_fail(text, message)
	else:
		if got < expect_low or got > expect_high:
			_fail(text, message)
		else:
			_pass(text, message)


func assert_null(got, message = ""):
	var text = "got %s, expected to be null"  % [got]
	if got == null:
		_pass(text, message)
	else:
		_fail(text, message)


func assert_not_null(got, message = ""):
	var text = "got %s, expected to be anything but null"  % [got]
	if got != null:
		_pass(text, message)
	else:
		_fail(text, message)


func assert_valid(object, message = ""):
	var text = "Expected a valid object"
	if is_instance_valid(object):
		_fail(text, message)
	else:
		_pass(text, message)


func assert_is(object, p_class, message = ""):
	var text = "Expected %s to be %s" % [object, p_class]
	if object is p_class:
		_pass(text, message)
	else:
		_fail(text, message)

#-------------------------------------------------------------------------------
# Assertion results
#-------------------------------------------------------------------------------
func get_fail_count():
	var count = 0

	var to_visit = []
	to_visit.push_back(self)

	while not to_visit.empty():
		var cur_node = to_visit.pop_back()
		count += cur_node._summary.failed

		for idx in cur_node.get_child_count():
			var node = cur_node.get_child(idx)
			if not node.has_method("get_fail_count"):
				continue
			to_visit.push_front(node)

	return count


func get_pass_count():
	var count = 0

	var to_visit = []
	to_visit.push_back(self)

	while not to_visit.empty():
		var cur_node = to_visit.pop_back()
		count += cur_node._summary.passed

		for idx in cur_node.get_child_count():
			var node = cur_node.get_child(idx)
			if not node.has_method("get_pass_count"):
				continue
			to_visit.push_front(node)

	return count


func get_summary_text():
	var text = get_script().get_path() + ":" + name
	text += "\n"

	var pass_count = get_pass_count()
	var fail_count = get_fail_count()

	var total = pass_count + fail_count
	if total == 0:
		text += "\tNo assertions were made."
		return text

	var percent_passed = float(pass_count) / total * 100
	text += "\t%s of %s passed (%.0f%%)" % [pass_count, total, percent_passed]
	if fail_count > 0:
		text += "\n"
		text += str("\t", fail_count, " failed")

	return text

#-------------------------------------------------------------------------------
# Core pass/fail logic
#-------------------------------------------------------------------------------
func _pass(text, message = ""):
	_summary.passed += 1


func _fail(text, message = ""):
	_summary.failed += 1
	var should_break = debug_break
	if tree:
		should_break = tree.debug_break

	var err = text
	if not message.empty():
		err = text + ": " + message

	var err_info = ""

	var stack = get_stack()
	var real_idx = 2
	if stack and stack.size() > real_idx:
		var s = stack[real_idx]
		err_info = '"%s:%s"' % [s.source, s.line]

	var assert_msg = "%s in node \"%s\"" % [err_info, name]
	if not err.empty():
		assert_msg += ": %s" % err

	if should_break and not pending:
		# Please check the call stack.
		assert(false, assert_msg)

	push_error("Assertion failed in " + assert_msg)
