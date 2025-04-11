extends Node

const SOUND_EFFECTS = {
	"trash": "res://audio/sfx/trash.wav",
	"drop": "res://audio/sfx/drop.wav",
	"chop": "res://audio/sfx/chop.wav",
	"tapioca": "res://audio/sfx/tapioca.wav",
	"transform": "res://audio/sfx/transform.wav",
	"successfulOrder": "res://audio/sfx/successfulOrder.wav",
	"lostOrder": "res://audio/sfx/lostOrder.wav",
	"upgrade": "res://audio/sfx/upgrade.wav"
}

const BACKGROUND_MUSIC = "res://audio/Mixdown - 01 Start.mp3"

var pickup_player: AudioStreamPlayer
var action_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

func _ready():
	pickup_player = AudioStreamPlayer.new()
	action_player = AudioStreamPlayer.new()
	error_player = AudioStreamPlayer.new()
	bgm_player = AudioStreamPlayer.new()
	
	add_child(pickup_player)
	add_child(action_player)
	add_child(bgm_player)
	
	setup_audio_player(pickup_player)
	setup_audio_player(action_player)
	setup_background_music()

func setup_audio_player(player: AudioStreamPlayer):
	player.volume_db = 0
	player.bus = "SFX"

func setup_background_music():
	bgm_player.volume_db = -3  # Slightly quieter than sound effects
	bgm_player.bus = "Music"
	bgm_player.stream = load(BACKGROUND_MUSIC)
	bgm_player.stream.loop = true

func play_background_music():
	if not bgm_player.playing:
		bgm_player.play()

func stop_background_music():
	if bgm_player.playing:
		bgm_player.stop()

func play_sound(sound_name: String):
	var sound_path = SOUND_EFFECTS.get(sound_name)
	if sound_path:
		var audio_stream = load(sound_path)
		if audio_stream:
			match sound_name:
				"transform", "drop", "trash":
					pickup_player.stream = audio_stream
					pickup_player.play()
				"chop", "tapioca", "upgrade", "transform", "successfulOrder", "lostOrder":
					action_player.stream = audio_stream
					action_player.play()
