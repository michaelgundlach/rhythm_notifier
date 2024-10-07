@tool
@icon("icon.svg")
class_name RhythmNotifier
extends Node
## A node that emits emits rhythmic signals synchronized with the beat of an [AudioStreamPlayer].
##
## [RhythmNotifier] lets you define custom signals that emit when a given beat in the audio stream
## is reached, or that emit every [code]N[/code] beats.  The signals are precisely synchronized 
## with the audio, accounting for output latency.  You can also run the [RhythmNotifier] without 
## playing audio, to generate rhythmic signals without music.
## 
## [br][br][color=yellow]Note:[/color] Beats are 0-indexed to make [RhythmNotifier] easier
## to use, while musicians are accustomed to counting from beat one.
##
## [br][br][b]Usage example:[/b]
## [codeblock]
## @onready var r: RhythmNotifier = $RhythmNotifier  # Set bpm and audio_stream_player in inspector
##
## # Play music and emit lots of signals
## func _play_some_music():
##     # Print on beat 4, 8, 12...
##     r.beats(4).connect(func(count): print("Hello from beat %d!" % (count * 4)))
##
##     # Print on beat 5, 8, 11...
##     r.beats(3, true, 2).connect(func(count): print("Hello from beat %d!" % 2+(count * 3)))
##
##     # Print anytime beat 8.5 is reached
##     r.beats(8.5, false).connect(func(_i): print("Hello from beat eight and a half!"))
##
##     r.audio_stream_player.play()  # Start signaling
##     r.audio_stream_player.seek(1.5)  # pausing/stopping/seeking all supported
##
##     # Stop playback on beat 20
##     r.beats(20, false).connect(func(_i): r.audio_stream_player.stop())
##
## # Play the music after 4 pickup beats
## func _play_with_leadin():
##     r.beats(4, false).connect(func(_i):
##         r.audio_stream_player.play()
##     , CONNECT_ONE_SHOT)
##
##     r.beat.connect(func(count):
##         if not r.audio_stream_player.playing:
##             print("Pickup beat %d" % count)
##         else:
##             print("Song beat %d" % count)
##
##     r.running = true  # Start signaling without playing the audio stream
##
## # Change the song tempo partway through
## func _change_tempos():
##     r.bpm = 60
##     r.beats(4).connect(func(count):
##         if r.bpm == 60 and count == 4:
##             print("Four seconds into the song, we speed up.")
##             r.bpm = 120
##         elif r.bpm == 120:
##             print("We are %.2f seconds into the song." % r.current_position)
##     )
##     r.audio_stream_player.play()
## [/codeblock]
##
## [b]Usage example:[/b] Printing the rhythm musicians say when counting measures [i]("ONE and 
## two and three and TWO and two and three and THREE and ...")[/i]
##
## [codeblock]
## var r = RhythmNotifier.new()
## get_tree().current_scene.add_child(r)
## r.running = true
## 
## # Say the measure number at the start of each measure
## r.beats(3).connect(func(count):
##     print("TIME %.2f, BEAT %2d  :    %d!" %
##         [r.current_position, r.current_beat, count])
## )
## # Say the other downbeats in the measure
## r.beat.connect(func(count):
##     if count % 3 != 0:
##         print("TIME %.2f, BEAT %2d  :       (%d)" % 
##             [r.current_position, count, (count % 3)+1])
## )
## # Say the upbeats in the measure
## r.beats(.5).connect(func(i):
##     if i % 2 != 0:
##         print("TIME %.2f, BEAT %4.1f:       (and)" %
##             [r.current_position, i/2.])
## )
##
## # Output:
## #     TIME 0.52, BEAT  0.5:       (and)
## #     TIME 1.00, BEAT  1  :       (2)
## #     TIME 1.52, BEAT  1.5:       (and)
## #     TIME 2.02, BEAT  2  :       (3)
## #     TIME 2.52, BEAT  2.5:       (and)
## #     TIME 3.02, BEAT  3  :    1!
## #     TIME 3.52, BEAT  3.5:       (and)
## #     TIME 4.02, BEAT  4  :       (2)
## #     TIME 4.52, BEAT  4.5:       (and)
## #     TIME 5.02, BEAT  5  :       (3)
## #     TIME 5.52, BEAT  5.5:       (and)
## #     TIME 6.02, BEAT  6  :    2!
## #     TIME 6.52, BEAT  6.5:       (and)
## #     TIME 7.02, BEAT  7  :       (2)
## #     TIME 7.52, BEAT  7.5:       (and)
## #     TIME 8.02, BEAT  8  :       (3)
## #     TIME 8.50, BEAT  8.5:       (and)
## #     TIME 9.00, BEAT  9  :    3!
## #     TIME 9.50, BEAT  9.5:       (and)
## # ...etc
## [/codeblock]
##
## [br][br]See [method beats] for more usage examples.


class _Rhythm:

	signal interval_changed(current_interval: int)

	var repeating: bool
	var beat_count: float
	var start_beat: float
	var last_frame_interval
	

	func _init(_repeating, _beat_count, _start_beat):
		repeating = _repeating
		beat_count = _beat_count
		start_beat = _start_beat
		

	const TOO_LATE = .1 # This long after interval starts, we are too late to emit
	# We pass secs_per_beat so user can change bpm any time
	func emit_if_needed(position: float, secs_per_beat: float) -> void:
		var interval_secs = beat_count * secs_per_beat
		var current_interval = int(floor((position - start_beat) / interval_secs))
		var secs_past_interval = fmod(position - start_beat, interval_secs)
		var valid_interval = current_interval > 0 and (repeating or current_interval == 1)
		var too_late = secs_past_interval >= TOO_LATE
		if not valid_interval or too_late:
			last_frame_interval = null
		elif last_frame_interval != current_interval:
			interval_changed.emit(current_interval)
			last_frame_interval = current_interval


## Emitted once per beat, excluding beat 0.  The [param current_beat] parameter
## is the value of [member RhythmNotifier.current_beat].
## [br][br][color=yellow]Note:[/color] This once-per-beat signal is a convenience to 
## allow connecting in the inspector, and is equivalent to [code]beats(1.0)[/code]. For
## other signal frequencies, use [method beats].
signal beat(current_beat: int)

## Beats per minute.  Changing this value changes [member beat_length].
## [br][br]This value can be changed while [member running] is true.
@export var bpm: float = 60.0:
	set(val):
		if val == 0: return
		bpm = val
		notify_property_list_changed()

## Length of one beat in seconds.  Changing this value changes [member bpm].  It is usually more 
## precise to specify [member bpm] and let [member beat_length] be calculated automatically,
## because song tempos are often an integer bpm.
@export var beat_length: float = 1.0:
	get:
		return 60.0 / bpm
	set(val):
		if val == 0: return
		bpm = 60.0 / val

## Optional [AudioStreamPlayer] to synchronize signals with.  While [member audio_stream_player] is
## playing, [signal beat] and [method beats] signals will be emitted based on playback position.
## [br][br]See [member running] for emitting signals without an [AudioStreamPlayer].
@export var audio_stream_player: AudioStreamPlayer

## If [code]true[/code], [signal beat] and [method beats] signals are being emitted.  Can be set to
## [code]true[/code] to emit signals without playing a stream.  [member running] is always
## [code]true[/code] while [member audio_stream_player] is playing.
@export var running: bool:
	get: return _silent_running or _stream_is_playing()
	set(val):
		if val == running:
			return  # No change
		if _stream_is_playing():
			return  # Can't override
		_silent_running = val
		_position = 0.0

## The current beat, indexed from [code]0[/code].
var current_beat: int:
	get: return int(floor(_position / beat_length))
	
## The current position in seconds.  If [member audio_stream_player] is playing, this is the
## accurate number of seconds into the stream, and setting the value will seek to
## that position.  If the audio stream is not playing, this is the number of seconds
## that [member running] has been set to true, if any, and setting overrides the value.
var current_position: float:
	get: return _position
	set(val):
		if _stream_is_playing():
			audio_stream_player.seek(val)
		elif _silent_running:
			_position = val
var _position: float = 0.0
	
var _cached_output_latency: float:
	get:
		if Time.get_ticks_msec() >= _invalidate_cached_output_latency_by:
			# Cached because method is expensive per its docs
			_cached_output_latency = AudioServer.get_output_latency()
			_invalidate_cached_output_latency_by = Time.get_ticks_msec() + 1000
		return _cached_output_latency
var _invalidate_cached_output_latency_by := 0
var _silent_running: bool
var _rhythms: Array[_Rhythm] = []


func _ready():
	beats(1.0).connect(beat.emit)


# If not stopped, recalculate track position and emit any appropriate signals.
func _physics_process(delta):
	if _silent_running and _stream_is_playing():
		_silent_running = false
	if not running:
		return
	if _silent_running:
		_position += delta
	else:
		_position = audio_stream_player.get_playback_position()
		_position += AudioServer.get_time_since_last_mix() - _cached_output_latency
	if Engine.is_editor_hint():
		return
	for rhythm in _rhythms:
		rhythm.emit_if_needed(_position, beat_length)


## Returns a signal that emits when a specific beat is reached, or repeatedly every specified
## number of beats. [param start_beat] (defaults to [code]0.0[/code]) is the beat from which
## to begin counting. [param beat_count] is the number of beats after [param start_beat] on which
## to signal. If [param repeating] (defaults to [code]true[/code]), the signal is emitted
## every [param beat_count] beats after [param start_beat].
## [br][br]Callback should be of the form [code]fn(current_interval)[/code], where
## [param current_interval] is the number of [param beat_count]-length intervals 
## past [param start_beat].
##
## [br][br]Usage:
## [codeblock]
## # Signals on beat 1, 2, 3, etc.  Equivalent to beat.connect(...)
## beats(1.0).connect(func(beat): pass)
##
## # Signals on beat 4, 8, 12, etc
## beats(4).connect(func(four_beat_group): pass)  # Parameter value will be 1, 2, 3, etc.
## # Signals on beat 6.25, 10.25, 12.25, etc
## beats(4.25, true, 2).connect(func(four_beat_group): pass)  # Parameter value will be 1, 2, 3, etc.
##
## # Signals anytime playback reaches beat 8.5
## beats(8.5, false).connect(func(_i): pass)  # Parameter value will be 1
## # Signals anytime playback reaches beat 10
## beats(8, false, 2).connect(func(_i): pass)  # Parameter value will be 1
##
## # Signals once, on beat 8
## beats(8, false).connect(_func, CONNECT_ONE_SHOT)
## # Signals once, the first time a multiple of 4 beats after beat 2 is reached
## beats(4, true, 2).connect(_func, CONNECT_ONE_SHOT)
## [/codeblock]
func beats(beat_count: float, repeating := true, start_beat := 0.0) -> Signal:
	for rhythm in _rhythms:
		if (rhythm.beat_count == beat_count 
			and rhythm.repeating == repeating
			and rhythm.start_beat == start_beat):
			return rhythm.interval_changed
	var new_rhythm = _Rhythm.new(repeating, beat_count, start_beat)
	_rhythms.append(new_rhythm)
	return new_rhythm.interval_changed
	

func _stream_is_playing():
	return audio_stream_player != null and audio_stream_player.playing
