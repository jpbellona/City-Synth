/* City Synth
 * 
 * @org Harmonic Laboratory
 * @code authors Jon Bellona, John Park
 * @interface Jeremy Schropp
 * @partners South Eugene Robotics Team (SERT); XS Media
 *
 */
 
/* 
 * Test Controls
// Keys 1, 2, 3, 4 change "video" or the musical mode... turns track on/off
// Keys 5, 6, 7, 8 toggle "video" music on/off
// Keys q, w, e, r change "video" for notes only... separating volume from notes
// 'b' adds bitcrusher to the drums (video 3)
// 'p' changes drum pattern (video 3)
// 'c' changes notes for patterns 1 and 2 and 4 (video 1, 2)
// click and drag in XY modulates pitch bend and alchemy params (video 2)
// 'f' press/release enables/disables master fader
// 'm' resets master fader
// may need to separate out turning notes off? arp is on for ch.1 so we keep on. 
//toggle on/off with vid select 
// CC messages used are 15, 31, 32, 33, 34, 36, 43, 45, 46
// Visual Sizes: Dominant X,Y,W,H: 20,20, 1550, 872
//                 3 smaller W,H: 318,178
//                 3 smaller top left corners: (1586,20), (1586, 365), (1586, 710)
// Workflow: go to ip cam site, inspect element of moving image, open url in new tab, copy/paste
// Good IP cam if we need to get one: https://www.amazon.com/dp/B01CPTC95M/ref=psdc_14241151_t1_B01CPT8WDK
*/


//MIDI
import themidibus.*; //Import the library
MidiBus myBus; // The MidiBus
//MIDI globals
int video = 1; //which video is currently active. ie. our mode
//add a note to add another layer of polyphony
int channel = 0; //0 is MIDI channel 1
int pitch = 60;
int velocity = 127;
Note noteA = new Note(channel, pitch, velocity);
Note noteB = new Note(channel, pitch, velocity);
Note ch6noteA = new Note(5, pitch, velocity);
Note ch6noteB = new Note(5, pitch, velocity);
boolean canBitcrush = true;
boolean canChangeMasterFader = true;
//toggles for videos on/off
boolean vid1Toggle = false;    //only used with QWERTY key tests
boolean vid2Toggle = false;
boolean vid3Toggle = false;
boolean vid4Toggle = false;
//Video 1 blob notes (8-voice polyphony)
int[] pitchSetA = { 48, 50, 55, 57, 58, 60, 62, 64, 67, 69, 72, 82 };
Note[] blobNotes = new Note[8];
Note noLatchBlob = new Note(channel, pitch, velocity);
//ControlChange change = new ControlChange(channel, number, velocity);

//IPCapture
import ipcapture.*;
IPCapture cam;
/* These urls are test urls. Insert your own IP cam addresses here as an array. 
 * You'll need at least four urls for full functionality and a dummy fifth for startup. 
*/
String [] urls = {  
  "http://224.0.0.251:5000/video_feed", 
  "http://213.193.89.202/axis-cgi/mjpg/video.cgi", 
  "http://201.166.63.44/axis-cgi/mjpg/video.cgi", 
  "http://213.193.89.202/axis-cgi/mjpg/video.cgi", 
  "http://213.193.89.202/axis-cgi/mjpg/video.cgi", 
  "http://199.66.196.234:8090/test.mjpg" }; 
  //"http://131.123.154.3/axis-cgi/mjpg/video.cgi",
int numPixels;
int[] previousFrame;

//SLITSCAN
float sway = 0.5;
int videoSliceX;
int drawPositionX = 960;
int slitSpeed = 6;
int fillCount = slitSpeed-1;
int r=0;
int g=0;
int b=0;
PGraphics holder;
int prevBassNote = 0;

//CV Blob (video 1 arp notes)
//Based heavily on Shiffman's OpenCV example 'ImageFilteringWithBlobPersistence'
import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;
//import controlP5.*;
OpenCV opencv;
PImage src, preProcessedImage, processedImage, contoursImage;
ArrayList<Contour> contours;
ArrayList<Contour> newBlobContours;
ArrayList<Blob> blobList;
// Number of blobs detected over all time. Used to set IDs.
// Nighttime settings: Adaptive(true), Contrast: 1.51, At Block:128, AT Constant: 65,blur: 6, Min size: 12.
int blobCount = 0;
float contrast = 2.15;
int brightness = 0;
int threshold = 75;
boolean useAdaptiveThreshold = true; // use basic thresholding
int thresholdBlockSize = 489;
int thresholdConstant = 45;
int blobSizeThreshold = 20;
int blurSize = 4;
boolean showCP5 = false;
// Control vars
//ControlP5 cp5;
int buttonColor;
int buttonBgColor;


// Master Fader global (check for business hour each minute)
int sec = 0;
// Video 4 timer for sending notes
int startTime = 0;
int counterTime = 0;
boolean canSendVid4Note = true;
int prevVid4Note = 0;

// Joystick INTERFACE
///Basic momentary switch acting as a toggle with default to on upon first press.
boolean[] canShowVideo = { false, false, false, false };
boolean[] isVideoHighlighted = { false, false, false, false };
int joystickRange = 400;          // this should match the integer range of the Arduino code
int joyX = joystickRange/2;       // start at center
int joyY = joystickRange/2;
int[] vals = {joyX, joyY, 0};       // container for joyX, joyY, and video selection
int prevJoyX = joyX;              // container for checking if joystick moved
int prevJoyY = joyY;

//Serial info.
import processing.serial.*;
Serial myPort; 
String inString = "a";            // incoming text from Serial , test var
int interfaceLED = 1;
int prevInterfaceLED = 0;
boolean canUpdate = true;
boolean serialUpdate = false;

//text for users
PFont font;

// Still Pics for Interface
PImage slot0;
PImage slot1;
PImage slot2;
PImage slot3;
PImage dominant;
// R,G,B,Y
color [] primary = {color(255, 0, 0), color(0, 255, 0), color(2, 100, 230), color(234, 215, 0)};   //R,G,B,Y
PImage pic;
int projectorW = 1920;
int projectorH = 1080;

// Letter Presser
PGraphics little;
float xT = 0;
float x=0;
float yT = 0;
float y=0;
int focusPixel = 10890;
int pixelJump = 1; //jump by 5 pixels every time we move joystick in mode 4

//PImage black;
boolean invertColors = true;
// OK GO Effect
int      []cleanPlate;        // stores clean plate pixel info
int      []currentBlurred;    // stores current frame blurred
int      thresholdOK = 50;    // to eliminate noise, compare current against clean plate with this threshold
int      blurRadius = 2;      // to eliminate noise, blur a little
boolean  mirrorX = true;      // mirror camera horizontally            
float    hueShift = 0;        // current amount of hue shift
float    hueShiftSpeed = 0;   // speed at which to shuft hue

PImage coverR;
PImage coverG;
PImage coverB2;
PImage coverY;
PImage muted;

//installation ONLY. mute audio faders if no joystick or button interactivity after X seconds
StopWatchTimer sw; 
int audioTotalCountDown = 120000; // counting in milliseconds, 90000= 1 1/2 minutes
boolean restartAudioCountDown = false;

void setup() {
  fullScreen(P3D); //1920x1080 is default for this project. may see issues with other sizes
  
  dominant = createImage(1550, 872, RGB);
  holder = createGraphics(width, height, P3D);  // **** NEW   ***
  little = createGraphics(180, 120, P3D);        // **** VID 4 ***
  background(0);

  // *****  NEW OK GO STUFF ***
  cleanPlate      = new int[width * height];
  currentBlurred  = new int[width * height];
  coverR = loadImage("coverRed.png");
  coverG = loadImage("coverGreen.png");
  coverB2 = loadImage("coverBlue2.png");
  coverY = loadImage("coverYellow.png");
  muted = loadImage("muted.png");


  // ARDUINO SERIAL 
  printArray(Serial.list());
  // "/dev/tty.usbmodem1431"
  //Serial.list()[0]
  String port = findPort(Serial.list(), "/dev/tty.usbmodem");

  //COMMENT/UNCOMMENT if no Arduino
  //myPort = new Serial(this, port, 9600); //port, Serial.list()[8]
  //myPort.bufferUntil(10); //10 is an ASCII linefeed
  //myPort.write(114); ///114 is lower case 'r'

  //CV BLOB (Visual)
  opencv = new OpenCV(this, 960, 540);
  contours = new ArrayList<Contour>();
  blobList = new ArrayList<Blob>();     // Blobs list
  for (int i=0; i<8; i++) {
    blobNotes[i] = new Note(channel, pitch, velocity);
  }


  // MIDI
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  // Create new MIDIbus with no input and IAC Driver as output
  //                 Parent  In    Out
  //                   |     |      |
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
  myBus.sendTimestamps(false);

  // IP video
  cam = new IPCapture(this, urls[4], "", "");
  cam.start();
  //numPixels = cam.width * cam.height; // original size
  numPixels = projectorW*projectorH;    // new size

  previousFrame = new int[numPixels];
  loadPixels();
  // It is possible to change the MJPEG stream by calling stop()
  // on a running camera, and then start() it with the new
  // url, username and password. 
  // note: this process of changing running cameras is slow (JB)

  // SHOW text for videos turned OFF
  font = createFont("Montserrat-Bold", 32);
  textFont(font, 32);
  holder.textFont(font, 32);

  textAlign(CENTER);
  textSize(30);

  //timer
  startTime = millis();
  
  //mute audio countdown timer
  sw = new StopWatchTimer();
  sw.start();
  
  // load blank startup screen, only show when no video is highlighted, aka. startup
  slot0 = loadImage("start-screen.jpg");
}

void draw() {

  //COMMENT/UNCOMMENT if no Arduino interface connected
  //myPort.write(114); ///114 is lower case 'r'  //handshake serial port to receive data from Arduino


  //boolean is located inside serialEvent()
  //MUST check to see if camera is available to slow down the user activity. 
  // wait for camera before allowing a user to update
  if (cam.isAvailable()) {
    if (serialUpdate) {
      //only update if we have a real video number
      if ((interfaceLED >= 1) && (interfaceLED <= 4)) {
        video = interfaceLED;
        if (video == 3) { saveCleanPlate(); }
        flushHolder();
        changeVideoHighlightBools(video);    // see IP tab for function
        changeSoundHighlightControls(video); // requires video bools to be set first, MIDI tab
        changeIPVidControls(video);          // see IP tab for function
      }
      serialUpdate = !serialUpdate;
    }
  }

  // IP Video
  // check to see if video is highlighted in order to display effect.
  if (cam.isAvailable()) {

    background(0);
    strokeWeight(8);
    noFill();
    cam.read();
    
    // only display startup screen if no video is highlighted, aka. on initialize
    if ( (!isVideoHighlighted[0]) && (!isVideoHighlighted[1]) && (!isVideoHighlighted[2]) && (!isVideoHighlighted[3]) ){
      image(slot0, 0, 0);
    }

    // VIDEO 1
    if (isVideoHighlighted[0]) {
      cam.resize(960, 540);
      blobTracking();                 // video 1 effect
      drawVideoBorders(0);            // draw red video border
      if (!canShowVideo[0]) {
        fill(250);
        textSize(12);
        image(muted, 1290,810);
      }
    } else {
      if (!canShowVideo[0]) {
        fill(250);
        textSize(12);
      }
    }

    // VIDEO 2
    if (isVideoHighlighted[1]) {
      cam.resize(318, 178);
      drawSlitScan();                 // video 2 effect only
      drawVideoBorders(1);            // draw green video border
      if (!canShowVideo[1]) {
        fill(250);
        textSize(12);
        image(muted, 1290,810);
      }
    } else {
      if (!canShowVideo[1]) {
        fill(250);
        textSize(12);
      }
    }

    // VIDEO 3
    if (isVideoHighlighted[2]) {
      frameDifference();              // video 3 effect
      image(holder, 20, 20, 1500, 872);  
      drawVideoBorders(2);            // draw blue video border
      if (!canShowVideo[2]) {
        fill(250);
        textSize(12);
        image(muted, 1290,810);
      }
    } else {
      if (!canShowVideo[2]) {
        fill(250);
        textSize(12);
      }
    }
    if (isVideoHighlighted[3]) {
      //println("run video 4");
      makeLetters();                  // video 4 effect
      drawVideoBorders(3);            // draw yellow video border
      if (!canShowVideo[3]) {
        fill(250);
        textSize(12);
        image(muted, 1290,810);
      }
    } else {
      if (!canShowVideo[3]) {
        fill(250);
        textSize(12);
      }
    }
  }

  //Check time and alter volume based upon business hours
  sec = second();
  if (sec >= 57) {
    checkTime(); //only check once a minute to cut down on data
  }
  //Update counter
  int passedTime = millis() - startTime;
  if (passedTime > counterTime) {
    canSendVid4Note = true;
    startTime = millis(); // Save the current time to restart the timer!
  }

  //check audio stopwatch, after X seconds of non-activity, mute audio, then reset timer.
  checkAudioStopWatch();

  strokeWeight(.5);
  stroke(#A600FA);
  noFill();
}

/*
 * Draw a primary color around main window for highlighted video
 * requires video number (which video is selected/highlighted?)
 */
void drawVideoBorders(int vid) {
  //strokeWeight(8);
  noFill();

  switch(vid) {
  case 0:  // -----------------------  BLOBS  -------------------
    //stroke(primary[0]);  // RED
    //image(dominant, 20, 20, 1550, 872);
    image(coverR, 0, 0);
    break;
  case 1:   //  -----------------------  SLITSCAN -------------------
    //stroke(primary[1]);  // GREEN
    image(dominant, 20, 20, 1550, 872);
    image(coverG, 0, 0);
    break;
  case 2: //  ------------------------------  OK GO / FrameDiff -----------
    noFill();
    stroke(primary[2]);  // BLUE
   // image(dominant, 20, 20, 1550, 872);
    image(coverB2, 0, 0);
    break;
  case 3: // ----------------------------   LETTER PUSHER ---------------
    //stroke(primary[3]);  // YELLOW
    image(dominant, 20, 20, 1550, 872);
    image(coverY, 0, 0);
    break;
  }
}


//Serial read -- how we get info from our interface
void serialEvent(Serial p) { 
  
  //first two values are joystick. third value (may or may not exist) is button push
  vals = int(splitTokens(p.readString())); //may need p.readStringUntil('\n');
  //printArray(vals);
  if (vals.length == 3) { //redundant, as we are always sending button as value (array.len of 3).
    if (vals[2] != 0) {
      printArray(vals);
      interfaceLED = vals[2]; //ignore ALL zeros
      serialUpdate = true;
      restartAudioCountDown = true;
    }
  }

  joyX = vals[0];
  joyY = vals[1];
  
  //check for moving joystick
  //running function from inside here may not be possible. 
  //may need to just set vars and then run check inside draw()
  if ((joyX != prevJoyX) || (joyY != prevJoyY)) {
    //update vars and control Logic
    joystickMove(video, joyX, joyY);
    //update
    prevJoyX = joyX;
    prevJoyY = joyY;
  } 
} 


void keyPressed() {

  //if (key == 's') {
  //  save("saveOut.jpg");
  //}
  if (key == 'z') {
    cam.dispose();
  }

  //VIDEO BUTTON PLACEHOLDER KEYS
  if (key == 'h') {
    video = 1;
    flushHolder();
    changeVideoHighlightBools(video);
    changeSoundHighlightControls(video); //requires video bools to be set first
    changeIPVidControls(video);
  }
  if (key == 'j') {
    video = 2;
    flushHolder();
    changeVideoHighlightBools(video);
    changeSoundHighlightControls(video);
    changeIPVidControls(video);
  }
  if (key == 'k') {
    video = 3;
    saveCleanPlate();
    flushHolder();
    changeVideoHighlightBools(video);
    changeSoundHighlightControls(video);
    changeIPVidControls(video);
  }
  if (key == 'l') {
    video = 4;
    flushHolder();
    changeVideoHighlightBools(video);
    changeSoundHighlightControls(video);
    //println("sound controls for 4 altered");
    changeIPVidControls(video); //no 4th video feed so don't add yet
  }


  if (key == 'c' || key == 'C') {
    changeNotes(video); //change notes based upon video mode
  }
  if (key == 'v' || key == 'V') {
    changeNotesVideo4(int(random(0, 11))); //change notes based upon video mode
  }
  if (key == 'a') {
    //create blobs and determine their pitch!
    // pitch set is always len 12
    int[] pitchSetA1 = { 48, 50, 55, 57, 58, 60, 62, 64, 67, 69, 72, 82 };
    int[] blobs = { 0, 0, 0, 0, 0, 0, 0, 0};
    int blob = 0;
    for (int i=0; i<8; i++) {
      blob = int(random(0, 3));
      if (blob > 0) {
        blob = pitchSetA1[int(random(0, 12))];
      } else {
        blob = 0;
      }
      //init blob array
      blobs[i] = blob;
      print(blobs[i] + ", ");
    }
    println();
    blobNotes(blobs); //change notes based upon blobs
  }
  if (key == 'A') {
    //turn notes off
    int[] blobsOff = { 0, 0, 0, 0, 0, 0, 0, 0 }; 
    blobNotes(blobsOff);
  }
  if (key == 'b' || key == 'B') {
    //bitCrush(canBitcrush,width/2, height/2);
    println("BitCrush Effect is " + canBitcrush);
    canBitcrush = !canBitcrush; //flip and update global
  }

  if (key == 'd' || key == 'D') {
    float randFrameDiff = (( random(width) / width ) * 63) + 64; //range 64-127
    println(randFrameDiff);
    LPF(randFrameDiff, 47, 4); //enact low-pass filter on controller 47, channel 4
  }

  if (key == 'p' || key == 'P') {
    selectNewDrumPattern(); //video mode 3
  }
  if (key == 'f' || key == 'F') {
    canChangeMasterFader = true;  //enable master fader
    changeMasterFader(70);        //reset master fader
  }
  if (key == 'm' || key == 'M') {
    canChangeMasterFader = true;  //enable master fader
    changeMasterFader(90);        //reset master fader
    canChangeMasterFader = false; //disable master fader
  }

  if (key == 'n') {
    joyX++;
    if (joyX>=127) {
      joyX=127;
    }
    if ((joyX != prevJoyX) || (joyY != prevJoyY)) {
      //update vars and control Logic
      joystickMove(video, joyX, joyY);
      //update
      prevJoyX = joyX;
      prevJoyY = joyY;
      //println(joyX + ", " + joyY);
    }
  }
  if (key == 'b') {
    joyX--;
    if (joyX<=0) {
      joyX=0;
    }
    if ((joyX != prevJoyX) || (joyY != prevJoyY)) {
      //update vars and control Logic
      joystickMove(video, joyX, joyY);
      //update
      prevJoyX = joyX;
      prevJoyY = joyY;
      //println(joyX + ", " + joyY);
    }
  }
  if (key == 'm') {
    joyY++;
    if (joyY>=127) {
      joyY=127;
    }
    if ((joyY != prevJoyY) || (joyX != prevJoyX)) {
      //update vars and control Logic
      joystickMove(video, joyX, joyY);
      //update
      prevJoyX = joyX;
      prevJoyY = joyY;
      //println(joyX + ", " + joyY);
    }
  }
}

void keyReleased() {
  if (key == 'f' || key == 'F') {
    canChangeMasterFader = false; //disable master fader
  }
}

//JOYSTICK, uncomment to simulate joystick behavior with mouse
// using mouse, simulate joystick. will always return to Center (width/2) (height/2)
/*void mouseDragged() {

  //mouseX center=0, left=1, right=1
  //simulates joystick X...
  //float joyX = abs(( float((mouseX/2)) / float((width/2)) ) - 0.5) * 2;
  float joyXdrag = abs(( float((mouseX/2)) / float((width/2)) ) - 0.5) * 2;
  //mouseX center=0, top=1, bottom=1
  //simulates joystick Y...
  //float joyY = abs(( float((mouseY/2)) / float((height/2)) ) - 0.5) * 2;
  float joyYdrag = abs(( float((mouseY/2)) / float((height/2)) ) - 0.5) * 2;

  //which video is selected will determine which effect
  //case/switch
  int vid=video;

  switch(vid) {
  case 1: //eq filter for arp                             L   C   R
    joyYdrag=(joyYdrag*15)+36;                // sampling range (036-064-036)
    joyXdrag=abs((joyXdrag-1)*50)+77;         // sampling range (063-127-063)
    //println(joyXdrag + ", " + joyYdrag);
    LPFwQ(joyXdrag, 55, joyYdrag, 56, 0);         // MIDI channel 1 (proc is 0) //1st track
    LPFwQ(joyXdrag, 57, joyYdrag, 58, 0);         // MIDI channel 1 (proc is 0) //2nd track
    break;
  case 2: //alchemy x/y for bass               L      C      R
    joyX=joyX*127;                    // range 00-127-00-127-00
    joyY=abs(joyY-1)*127;             // range 00-127-00-127-00
    alchemyTransform(joyX, 41, joyY, 42, 2);  //valX, MIDI controller, valY, MIDI controller, MIDI channel 3 (2 is proc)
    //pitchbend(2, int(pmouseY));           //MIDI channel 3 (proc is 2)
    break;
  case 3: //bitcrusher for drums                         L  C  R
    joyX=joyX*90;                     //sampling range  (90-00-90)
    joyY=(abs(joyY-1)*70)+16;         //bit depth range (00-86-00)
    bitCrush(canBitcrush, joyX, joyY);  //bitcrush function
    break;
  case 4: //alchemy x/y for special            L      C      R
    joyX=joyX*127;                    // range 00-127-00-127-00
    joyY=abs(joyY-1)*127;             // range 00-127-00-127-00
    alchemyTransform(joyX, 51, joyY, 52, 5); //MIDI channel 6 (proc is 5)
    break;
  }

  //mouseX center=0, left=1, right=1
  //simulates joystick X...
  //println(  abs(( float((mouseX/2)) / float((width/2)) ) - 0.5) * 2 );

  //OLD alchemy morph code
  //int val = int((( float(mouseY) / float(height)) - 1) * -1 * 127) ; //int( ((mouseY / height) * 100) );
  ////channel 1, 15 = Transform Pad X
  ////channel 1, 43 = Transform Pay Y
  //myBus.sendControllerChange(0, 43, int(val));
  //val = int(( float(mouseX) / float(width)) * 127);
  //myBus.sendControllerChange(0, 15, int(val));

  //OLD pitchbend code
  //pitch bend works without requiring controller assignment!
  //so you have to encapsulate when to use (i.e. gate/conditions) inside Processing.
  //val = int((( float(mouseY) / float(height)) - 1) * -1 * 127);
  //val = val<0 ? 0 : val; //make sure pitch bend is between 0 and 127
  //val = val>127 ? 127 : val;
  ////Or for something different we could send a custom Midi message ...
  //int status_byte = 226; //0xE0; // For instance let us send pitch bend (224 ch1)
  ////224 is channel 1
  //int first_byte = 0; // 14 bit number LSB
  // int second_byte = val; // 14 bit number MSB 0x00 0x40 = no pitch bend
  // myBus.sendMessage(status_byte, first_byte, second_byte);
}*/



void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

// check for business hours and alter master fader
void checkTime() {
  int hour = hour();
  //println("hour is: " + hour);

  // business hours 9-5, hours are 0-23
  if ((hour > 7) && (hour < 17)) {
    canChangeMasterFader = true;
    changeMasterFader(70);        //turn down the master fader during business, 8-5
  } else if ((hour >= 17) || (hour < 2)) {
    canChangeMasterFader = true;
    changeMasterFader(77);        //turn up the master fader after business, 5p-2a
  } else {
    canChangeMasterFader = true;
    changeMasterFader(10);        //turn off the master fader 2a-8a
    //function for visual confirmation that installation is off for the night?
  }

  //70 is -4.4 dB, 90 is 0dB (never higher than this)
}