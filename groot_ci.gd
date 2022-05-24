class_name TestTreeCI extends TestTree
tool

export var quit_on_finished = false
export var quit_on_success = true

export(int, 0, 125) var pass_exit_code = 0
export(int, 0, 125) var fail_exit_code = 1


func _init():
	debug_break = false


func _on_tests_finished(result: bool):
	var success := result
	OS.exit_code = pass_exit_code if success else fail_exit_code

	if quit_on_finished or (success and quit_on_success):
		get_tree().quit()
