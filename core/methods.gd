extends Reference


static func get_files(p_path, p_filter = "*"):
	var files = []

	var fs = Directory.new()
	var err = fs.open(p_path)
	if err != OK:
		return []

	fs.list_dir_begin(true, true)

	var item = fs.get_next()
	while not item.empty():
		if not fs.current_is_dir() and item.match(p_filter):
			files.push_back(p_path.plus_file(item))
		item = fs.get_next()

	fs.list_dir_end()

	return files


static func get_directories(p_path):
	var directories = []

	var fs = Directory.new()
	var err = fs.open(p_path)
	if err != OK:
		return []

	fs.list_dir_begin(true, true)

	var item = fs.get_next()
	while not item.empty():
		if fs.current_is_dir():
			directories.push_back(p_path.plus_file(item))
		item = fs.get_next()

	fs.list_dir_end()

	return directories


static func get_directories_recursive(p_path):
	var directories = []
	var to_visit = []
	to_visit.push_back(p_path)

	while not to_visit.empty():
		var cur_dir = to_visit.pop_back()
		directories.push_back(cur_dir)

		for dir in get_directories(cur_dir):
			to_visit.push_front(dir)

	return directories


static func get_files_recursive(p_path, p_filter = "*"):
	var files = []
	var directories = get_directories_recursive(p_path)

	for dir in directories:
		var dir_files = get_files(dir, p_filter)
		for f in dir_files:
			files.push_back(f)

	return files


static func dir_exists(p_path):
	var fs = Directory.new()
	return fs.dir_exists(p_path)
