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
themidibus.*	The MIDI bus
ipcapture.*		IPCapture
gab.opencv.* 	OpenCV
controlP5.*		ControlP5

Arduino code requires externals
#include <Adafruit_DotStar.h>


In Processing, keys “h, j, k, l” simulate interface button presses that select between different video/audio feeds.
A single button press selects the video and turns on the respective audio track. A second button press of the same button mutes the audio. In this way, different combinations of button presses allows uses to mix and match video and audio tracks. Both Processing and Logic files need to be up and running for this behavior to occur.

The IP cameras we used were built by South Eugene Robotics Team and coded by Jackson. Code is available here if wanting to run camera feed via Raspberry Pi 3.
https://github.com/JacksonCoder/pystreamer-http


TO RUN
After install, connect Pi to internet using Ethernet jack. To get ip of the Raspberry Pi, please power up the Pi and open Terminal window on Pi.
$ sudo ifconfig

The IP should be on line "inet" (e.g. 128.223.127.127)
Use this IP for the Processing sketch "citysynth_visual"
Go to line 65 "http://224.0.0.251:5000/video_feed",

Replace 224.0.0.251 with the IP from the Raspberry Pi. 
Then Run the Processing sketch.  Hit 'h' on the keyboard to select camera 1 (referencing line of code we just changed) and start the visual.
The other videos on "j" "k" and "l" (videos 2, 3, 4 respectively) are generic IP cameras. To use other Pi cameras, follow the steps above and replace other lines in the urls array with "http://x.x.x.x:5000/video_feed"  This is the url that points to Jackson's Py streamer code on the Raspberry Pi.