extends CanvasLayer

var command_history: Array[String] = []
var commands: Dictionary = {}

@onready var panel: PanelContainer = $Panel
@onready var log_output: RichTextLabel = $Panel/VBoxContainer/LogOutput
@onready var command_input: LineEdit = $Panel/VBoxContainer/CommandInput


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_register_builtin_commands()
	if command_input != null and not command_input.text_submitted.is_connected(execute_command):
		command_input.text_submitted.connect(execute_command)


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("dev_console") and event.is_action_pressed("dev_console"):
		toggle_console()
		get_viewport().set_input_as_handled()


func toggle_console() -> void:
	visible = not visible
	if visible and command_input != null:
		command_input.grab_focus()


func log_line(text: String) -> void:
	if log_output == null:
		return
	log_output.append_text(text + "\n")


func register_command(command_name: StringName, callable: Callable, description: String = "") -> void:
	if command_name == &"" or not callable.is_valid():
		return
	commands[command_name] = {
		"callable": callable,
		"description": description
	}


func execute_command(command_text: String) -> void:
	var trimmed := command_text.strip_edges()
	if command_input != null:
		command_input.clear()
	if trimmed.is_empty():
		return
	command_history.append(trimmed)
	log_line("> " + trimmed)
	var parts := trimmed.split(" ", false)
	var command_name := StringName(parts[0])
	if not commands.has(command_name):
		log_line("Unknown command: " + String(command_name))
		return
	var entry: Dictionary = commands[command_name]
	var callable: Callable = entry.get("callable", Callable())
	if callable.is_valid():
		callable.call(trimmed)


func clear_console() -> void:
	if log_output != null:
		log_output.clear()


func _register_builtin_commands() -> void:
	register_command(&"help", Callable(self, "_command_help"), "List available commands.")
	register_command(&"clear", Callable(self, "_command_clear"), "Clear console output.")
	register_command(&"errors", Callable(self, "_command_errors"), "Show where to review engine errors.")
	register_command(&"save", Callable(self, "_command_save"), "Save through SaveManager if available.")
	register_command(&"load", Callable(self, "_command_load"), "Load through SaveManager if available.")
	register_command(&"scene", Callable(self, "_command_scene"), "Print the current scene path.")


func _command_help(_command_text: String = "") -> void:
	log_line("Commands:")
	for command_name in commands.keys():
		var entry: Dictionary = commands[command_name]
		log_line("- " + String(command_name) + ": " + str(entry.get("description", "")))


func _command_clear(_command_text: String = "") -> void:
	clear_console()


func _command_errors(_command_text: String = "") -> void:
	log_line("Check the Godot Debugger Errors tab or Output panel for engine errors.")


func _command_save(_command_text: String = "") -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("save_game"):
		var result: Variant = save_manager.call("save_game")
		log_line("Save requested. Result: " + str(result))
		return
	log_line("SaveManager.save_game() is unavailable.")


func _command_load(_command_text: String = "") -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_game"):
		save_manager.call("load_game")
		log_line("Load requested.")
		return
	log_line("SaveManager.load_game() is unavailable.")


func _command_scene(_command_text: String = "") -> void:
	var current_scene := get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		log_line("Current scene: " + current_scene.scene_file_path)
		return
	log_line("Current scene path is unavailable.")
