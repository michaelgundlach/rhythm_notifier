# RhythmNotifier

A Godot 4 addon for syncing game events and sound effects with the beat of the music.

![Hey](/screenshots/example.png)

This addon provides the *RhythmNotifier* class, which is a node that emits
rhythmic signals synchronized with the beat of an AudioStreamPlayer.  The
signals are precisely synchronized with the audio, accounting for output
latency.  

RhythmNotifier lets you define custom signals that emit when a given beat in
the audio stream is reached, or that emit every `N` beats.  You can
also run the RhythmNotifier without playing audio, to generate rhythmic signals
without music.

**Note:** Beats are 0-indexed to make RhythmNotifier easier to use, while
musicians are accustomed to counting from beat one.

## Usage

1. Add a RhythmNotifier node to your scene.  Then in its Inspector,
   * Drag an AudioStreamPlayer onto the Audio Stream Player property. 
   * Set the BPM property to the beats per minute of the audio that will be played.
1. Use the `$RhythmNotifier.beats()` method to create a custom signal to
   connect to.  The signal can emit on a specific beat, or every `N` beats.

### Tips

* You can put the RhythmNotifier anywhere in your scene, including as a child of its AudioStreamPlayer.

* You can set the `.audio_stream_player` property in code to integrate with your own sound management system, instead of an
  AudioStreamPlayer in the scene.

* You can set the `running` property to emit signals without starting the
  AudioStreamPlayer.  This may be useful for lead-in beats before music starts
  in rhythm games, or if you don't need any music (in which case
  `.audio_stream_player` may be left null.)
 
* A convenience `beat` signal is available in the Node tab to connect visually, which emits every beat.

## Installation

Install from the Godot Asset Library, or copy the `addons/rhythm_notifier` folder into an `addons` folder in your project.
The **RhythmNotifier** node will then be available when you Add Node in a scene.

## Usage example

```gdscript
# Set r.bpm and r.audio_stream_player in inspector
@onready var r: RhythmNotifier = $RhythmNotifier  

# The beats method signature is:
#
#   func beats(beat_count: float, repeating := true, start_beat := 0.0) -> Signal
#
# We'll use this below to create repeating signals that emit every `beat_count`
# beats after `start_beat`, and non-repeating signals that emit when we reach
# `beat_count` beats after `start_beat`.

# Play music and emit lots of signals
func _play_some_music():
    # Print on beat 4, 8, 12...
    r.beats(4).connect(func(count): print("Hello from beat %d!" % (count * 4)))

    # Print on beat 5, 8, 11...
    r.beats(3, true, 2).connect(func(count): print("Hello from beat %d!" % 2+(count * 3)))

    # Print anytime beat 8.5 is reached
    r.beats(8.5, false).connect(func(_i): print("Hello from beat eight and a half!"))

    r.audio_stream_player.play()  # Start signaling
    r.audio_stream_player.seek(1.5)  # pausing/stopping/seeking all supported

    # Stop playback on beat 20
    r.beats(20, false).connect(func(_i): r.audio_stream_player.stop())

# Play the music after 4 pickup beats
func _play_with_leadin():
    r.beats(4, false).connect(func(_i):
        r.audio_stream_player.play()
    , CONNECT_ONE_SHOT)

    r.beat.connect(func(count):
        if not r.audio_stream_player.playing:
            print("Pickup beat %d" % count)
        else:
            print("Song beat %d" % count)

    r.running = true  # Start signaling without playing the audio stream

# Change the song tempo partway through
func _change_tempos():
    r.bpm = 60
    r.beats(4).connect(func(count):
        if r.bpm == 60 and count == 4:
            print("Four seconds into the song, we speed up.")
            r.bpm = 120
        elif r.bpm == 120:
            print("We are %.2f seconds into the song." % r.current_position)
    )
    r.audio_stream_player.play()
```

## Usage example

Printing the rhythm musicians say when counting measures *("ONE and two and three and TWO and two and three and THREE and ...")*

```gdscript
var r = RhythmNotifier.new()
get_tree().current_scene.add_child(r)
r.running = true

# Say the measure number at the start of each measure
r.beats(3).connect(func(count):
    print("TIME %.2f, BEAT %2d  :    %d!" %
        [r.current_position, r.current_beat, count])
)
# Say the other downbeats in the measure
r.beat.connect(func(count):
    if count % 3 != 0:
        print("TIME %.2f, BEAT %2d  :       (%d)" % 
            [r.current_position, count, (count % 3)+1])
)
# Say the upbeats in the measure
r.beats(.5).connect(func(i):
    if i % 2 != 0:
        print("TIME %.2f, BEAT %4.1f:       (and)" %
            [r.current_position, i/2.])
)

# Output:
#     TIME 0.52, BEAT  0.5:       (and)
#     TIME 1.00, BEAT  1  :       (2)
#     TIME 1.52, BEAT  1.5:       (and)
#     TIME 2.02, BEAT  2  :       (3)
#     TIME 2.52, BEAT  2.5:       (and)
#     TIME 3.02, BEAT  3  :    1!
#     TIME 3.52, BEAT  3.5:       (and)
#     TIME 4.02, BEAT  4  :       (2)
#     TIME 4.52, BEAT  4.5:       (and)
#     TIME 5.02, BEAT  5  :       (3)
#     TIME 5.52, BEAT  5.5:       (and)
#     TIME 6.02, BEAT  6  :    2!
#     TIME 6.52, BEAT  6.5:       (and)
#     TIME 7.02, BEAT  7  :       (2)
#     TIME 7.52, BEAT  7.5:       (and)
#     TIME 8.02, BEAT  8  :       (3)
#     TIME 8.50, BEAT  8.5:       (and)
#     TIME 9.00, BEAT  9  :    3!
#     TIME 9.50, BEAT  9.5:       (and)
# ...etc
```
