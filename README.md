README

City Synth is a method for transforming IP camera feeds into a musical synthesizer.

@org Harmonic Laboratory
@authors Jon Bellona, John Park

City Synth runs using Processing (http://processing.org) and Logic Pro X. 
Additional project considerations include a physical interface using Arduino (code included).

Logic Pro X
Install requires update of Logic Prefs necessary for Video Synth Controller Assignments
https://documentation.apple.com/en/logicpro/controlsurfacessupport/index.html#chapter=2%26section=5%26tasks=true
	see dependencies folder for this com.apple.logic.pro.cs file 

Processing external libraries required to run the code
themidibus.*		The MIDI bus
ipcapture.*		IPCapture
gab.opencv.* 	OpenCV
controlP5.*		ControlP5

Arduino code requires externals
#include <Adafruit_DotStar.h>


In Processing, keys “h, j, k, l” simulate interface button presses that select between different video/audio feeds.
A single button press selects the video and turns on the respective audio track. A second button press of the same button mutes the audio. In this way, different combinations of button presses allows uses to mix and match video and audio tracks.

The IP cameras we used were built by South Eugene Robotics Team and coded by Jackson. Code is available here if wanting to run camera feed via Raspberry Pi 3.
https://github.com/JacksonCoder/pystreamer-http