class_name SignInButton
extends Control

## Platform-specific sign-in button

signal sign_in_requested

enum Platform { APPLE, GOOGLE }

@export var platform: Platform = Platform.APPLE

@onready var button: Button = %Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	_update_display()


func setup(p_platform: Platform) -> void:
	platform = p_platform
	_update_display()


func _update_display() -> void:
	match platform:
		Platform.APPLE:
			button.text = " Sign in with Apple"
		Platform.GOOGLE:
			button.text = " Sign in with Google"


func _on_button_pressed() -> void:
	sign_in_requested.emit()
	# TODO: Actual platform auth integration
	# For now just show placeholder
	print("Sign in requested for platform: ", Platform.keys()[platform])
