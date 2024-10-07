# To run this example:
#
# Create a new scene with a Node named Example at its root.
#   Add a Music AudioStreamPlayer child named Music.
#     Set its Stream property to an MP3 you have handy.
#   Add a RhythmNotifier child.
#     Set its Audio Stream Player property to $Music.
#     Set its BPM property to the beats per minute of your MP3 (take a guess).
# Attach this script to $Example.
# Run the scene and watch the Output window.

extends Node

func _ready():
	# Print every 4 beats
	$RhythmNotifier.beats(4).connect(func(count):
		print("TAMBOURINE NOISE NUMBER %d !" % count)
	)
	# On beat 12.25, seek to beat 2
	$RhythmNotifier.beats(12.25, false).connect(func(_count):
		$Music.seek($RhythmNotifier.beat_length * 2.0)
	)
	
	$Music.play()















func __ready():
	DebugConsole.add_command_setvar("testbool", set_bool, self, DebugCommand.ParameterType.Bool, 
		"should work with on/off as well as true/false", get_bool)
	pass # Replace with function body.

func set_bool(val: bool):
	_bool_value = val
func get_bool():
	return _bool_value
var _bool_value: bool
