class_name VolumeSlider
extends Control

## Audio volume control with mute toggle

signal volume_changed(value: float)
signal mute_toggled(muted: bool)

@export var label_text: String = "Volume"
@export var initial_value: float = 1.0
@export var is_muted: bool = false

@onready var label: Label = %Label
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel
@onready var mute_button: Button = %MuteButton


func _ready() -> void:
	label.text = label_text
	slider.value = initial_value * 100
	slider.value_changed.connect(_on_slider_changed)
	mute_button.pressed.connect(_on_mute_pressed)
	_update_display()


func setup(p_label: String, p_value: float, p_muted: bool) -> void:
	label_text = p_label
	initial_value = p_value
	is_muted = p_muted

	if label:
		label.text = label_text
		slider.value = initial_value * 100
		_update_display()


func _update_display() -> void:
	value_label.text = "%d%%" % int(slider.value)
	mute_button.text = "🔇" if is_muted else "🔊"

	if is_muted:
		slider.modulate.a = 0.5
		value_label.modulate.a = 0.5
	else:
		slider.modulate.a = 1.0
		value_label.modulate.a = 1.0


func _on_slider_changed(value: float) -> void:
	_update_display()
	volume_changed.emit(value / 100.0)


func _on_mute_pressed() -> void:
	is_muted = not is_muted
	_update_display()
	mute_toggled.emit(is_muted)


func get_value() -> float:
	return slider.value / 100.0
