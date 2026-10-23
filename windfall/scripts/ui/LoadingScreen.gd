extends CanvasLayer

@onready var loading_label: Label = $Panel/LoadingLabel
@onready var progress_bar: ProgressBar = $Panel/ProgressBar


func _ready() -> void:
	visible = false


func show_loading(message: String = "Loading...") -> void:
	set_message(message)
	visible = true


func hide_loading() -> void:
	visible = false


func set_progress(value: float) -> void:
	if progress_bar == null:
		return
	progress_bar.value = clampf(value, progress_bar.min_value, progress_bar.max_value)


func set_message(message: String) -> void:
	if loading_label == null:
		return
	loading_label.text = message
