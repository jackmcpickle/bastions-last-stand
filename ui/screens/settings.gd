extends Control

## Settings screen with audio and account options

const VolumeSliderScene = preload("res://ui/components/volume_slider.tscn")
const SignInButtonScene = preload("res://ui/components/sign_in_button.tscn")

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var audio_section: VBoxContainer = %AudioSection
@onready var account_section: VBoxContainer = %AccountSection
@onready var account_status_label: Label = %AccountStatusLabel
@onready var back_button: Button = %BackButton

var _music_slider = null
var _sfx_slider = null
var _apple_button = null
var _google_button = null

var _previous_scene: String = "res://ui/screens/splash_screen.tscn"


func _ready() -> void:
	_apply_theme()
	_setup_audio_controls()
	_setup_account_controls()
	back_button.pressed.connect(_on_back_pressed)


func _apply_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.95, 0.92, 0.87, 1)
			title_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
		SceneManager.Faction.DARK:
			background.color = Color(0.1, 0.08, 0.12, 1)
			title_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
		_:
			# Neutral gray before faction selected
			background.color = Color(0.15, 0.15, 0.18, 1)
			title_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.75, 1))


func _setup_audio_controls() -> void:
	# Music slider
	_music_slider = VolumeSliderScene.instantiate()
	audio_section.add_child(_music_slider)
	_music_slider.setup("Music", SceneManager.music_volume, SceneManager.music_muted)
	_music_slider.volume_changed.connect(_on_music_volume_changed)
	_music_slider.mute_toggled.connect(_on_music_mute_toggled)

	# SFX slider
	_sfx_slider = VolumeSliderScene.instantiate()
	audio_section.add_child(_sfx_slider)
	_sfx_slider.setup("Effects", SceneManager.sfx_volume, SceneManager.sfx_muted)
	_sfx_slider.volume_changed.connect(_on_sfx_volume_changed)
	_sfx_slider.mute_toggled.connect(_on_sfx_mute_toggled)


func _setup_account_controls() -> void:
	# Account status
	account_status_label.text = "Not signed in"

	# Platform buttons
	var buttons_container := HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)

	_apple_button = SignInButtonScene.instantiate()
	buttons_container.add_child(_apple_button)
	_apple_button.setup(SignInButton.Platform.APPLE)
	_apple_button.sign_in_requested.connect(_on_apple_sign_in)

	_google_button = SignInButtonScene.instantiate()
	buttons_container.add_child(_google_button)
	_google_button.setup(SignInButton.Platform.GOOGLE)
	_google_button.sign_in_requested.connect(_on_google_sign_in)

	account_section.add_child(buttons_container)


func _on_music_volume_changed(value: float) -> void:
	SceneManager.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	SceneManager.set_sfx_volume(value)


func _on_music_mute_toggled(_muted: bool) -> void:
	SceneManager.toggle_music_mute()


func _on_sfx_mute_toggled(_muted: bool) -> void:
	SceneManager.toggle_sfx_mute()


func _on_apple_sign_in() -> void:
	# TODO: Implement Apple Sign-In
	account_status_label.text = "Apple Sign-In not implemented"


func _on_google_sign_in() -> void:
	# TODO: Implement Google Sign-In
	account_status_label.text = "Google Sign-In not implemented"


func _on_back_pressed() -> void:
	SceneManager.change_scene(_previous_scene)


func set_previous_scene(scene_path: String) -> void:
	_previous_scene = scene_path
