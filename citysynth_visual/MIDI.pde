// CITY SYNTH MIDI tab.
// FUNCTIONS related to MIDI messages sent to Logic


//VIDEO 2 & 4 use Alchemy
void alchemyTransform(float x, int Xcontrol, float y, int Ycontrol, int channel) {
  myBus.sendControllerChange(channel, Xcontrol, int(x)); //x of Alchemy Transform pad 0-127
  myBus.sendControllerChange(channel, Ycontrol, int(y)); //y of Alchemy Transform pad 0-127
}

//MIDI pitchbend
//pitch bend works without requiring controller assignment!
//so you have to encapsulate when to use (i.e. gate/conditions) inside Processing.
void pitchbend(int channel, int val) {
 
  //make sure channel is between 0-15 (proc index 0)
  channel = channel<0 ? 0 : channel; 
  channel = channel>15 ? 15 : channel;
  //now set channel to pitchbend channel range 224-239
  channel = channel+224;
  
  //make sure pitch bend is between 0 and 127
  val = val<0 ? 0 : val; 
  val = val>127 ? 127 : val;
  //construct custom MIDI message for pitch bend
  int status_byte = channel; //0xE0; // For instance let us send pitch bend (224 ch1)
  int first_byte = 0; // 14 bit number LSB
  int second_byte = val; // 14 bit number MSB 0x00 0x40 = no pitch bend
  myBus.sendMessage(status_byte, first_byte, second_byte); 
}

void bassEQ(float cutoff) {
  //cutoff is 0-1, alter to 20-127
  cutoff = (cutoff*107)+20;
  myBus.sendControllerChange(2, 60, int(cutoff));
}

// VIDEO 2&4. Bass and Special tracks.
// Arp uses its own note array
void changeNotes(int mode){
  int pitchIndex = 0;
  
  switch(mode) {
    case 1: //arpeggiator
      
      break;
    case 2: //Monster bass
      myBus.sendNoteOff(noteA); //ch3
      myBus.sendNoteOff(noteB); //ch4
      int[] pitchSetB = { 48, 50, 52, 55, 57, 60 };
      pitchIndex = int(random(0,6));
      pitch = pitchSetB[pitchIndex];
      //println ("bass pitch is: " + pitch);
      noteA = new Note(2, pitch, 100+int(random(0,27)));
      noteB = new Note(3, pitch, 100+int(random(0,27)));
      myBus.sendNoteOn(noteA);
      myBus.sendNoteOn(noteB);
      break;
    case 4: //Special
      break;
  } 
}

/*
 * Send note to 2nd instrument on MIDI ch 6
 * pitchIndex must be int between 0-11
 * notes are global so I can reference and turn them off
 */
void changeNotesVideo2(int pitchIndex){
  int pitch3 = 60;
  myBus.sendNoteOff(noteA); //ch3
  myBus.sendNoteOff(noteB); //ch4
  int[] pitchSetB = { 48, 50, 52, 55, 57, 60 };
  //pitchIndex = int(random(0,6));
  pitch = pitchSetB[pitchIndex];
  //println ("bass pitch is: " + pitch);
  noteA = new Note(2, pitch, 100+int(random(0,27)));
  noteB = new Note(3, pitch, 100+int(random(0,27)));
  myBus.sendNoteOn(noteA);
  myBus.sendNoteOn(noteB);
}

/*
 * Send note to 4th instrument on MIDI ch 6
 * pitchIndex must be int between 0-11
 * notes are global so I can reference and turn them off
 */
void changeNotesVideo4(int pitchIndex){
  //int pitchIndex = 0;
  int pitch6 = 60;
  myBus.sendNoteOff(ch6noteA); //ch6
  myBus.sendNoteOff(ch6noteB); //ch6
  int[] pitchSet6 = { 48, 50, 52, 55, 57, 60, 62, 64, 67, 69, 72, 74 };
  int offset6 = 12;
  
  //pitchIndex = int(random(0,11)); // random pitch index as placeholder.
  
  //println("pitchIndex is " + pitchIndex);
  pitch6 = pitchSet6[pitchIndex];
  //println ("special pitch is: " + str(int(pitch6+offset6)));
  ch6noteA = new Note(5, pitch6+offset6, 60+int(random(0,27)));
  //println ("special pitch 2 is: " + str(int(pitch6+offset6+12)));
  ch6noteB = new Note(5, pitch6+offset6+12, 20+int(random(0,27)));
  myBus.sendNoteOn(ch6noteA);
  myBus.sendNoteOn(ch6noteB);
  //println("notes for video 4 sent");
}

//VIDEO 1 -- trigger up to 8 notes on MIDI channel 1 (track 2)
// this function uses QWERTY 'a' to set new array.
// for TRUE control coming from video see cv_functions tab
void blobNotes(int[] pitches) {
  // array of blobs is always len 8?
  
  // pitch set is always len 12
  //int[] pitchSetA = { 48, 50, 55, 57, 58, 60, 62, 64, 67, 69, 72, 82 };
  
  // turn notes off
  // by checking to see if blob is 0
  for (int i=0; i<pitches.length; i++) {
    if (pitches[i] == 0) {
      myBus.sendNoteOff(blobNotes[i]); //blob notes correspond to blobs
    }
  }
  // turn notes off on 2nd track
  if(pitches[0] == 0) {
    myBus.sendNoteOff(noLatchBlob); 
  }
  
  // send first blob to ch2
  if(pitches[0] != 0) {
    noLatchBlob = new Note(1, pitches[0], 100+int(random(0,27)));
    myBus.sendNoteOn(noLatchBlob);
  }
  
  // send available blobs to ch1
  for (int i=0; i<pitches.length; i++) {
    if (pitches[i] != 0) {
      blobNotes[i] = new Note(0, pitches[i], 100+int(random(0,27)));
      myBus.sendNoteOn(blobNotes[i]); //blob notes correspond to blobs
    }
  }
  
}

//VIDEO 3 -- select new random pattern from set
void selectNewDrumPattern() {
  //use a MIDI note (C-1 to G#1) to trigger a new sequence
  //myBus.sendNoteOff(noteA); //ch5
  int patternIndex = int(random(0,6));
  int[] pitchSet = { 36, 38, 40, 41, 42, 44 };
  int notePitch = pitchSet[patternIndex];
  //since Logic toggles playback of Ultrabeat pattern if same note, 
  //make sure we don't turn off by not repeating same pitch
  if (notePitch-24 != noteA.pitch()) {
    //println(noteA.pitch());
    noteA = new Note(4, notePitch-24, 100+int(random(0,27)));
    myBus.sendNoteOff(noteA); //ch5
    myBus.sendNoteOn(noteA);
  }
}

//JOYSTICK: Drums Effect
//joystick x controls sampling rate
//joystick y controls bit depth
//link to bitcrusher effect in logic (uses controller assignments)
void bitCrush(boolean isBitCrushOn, float x, float y) {
  
  if (isBitCrushOn) {
    //drums are on MIDI channel 5 (proc 4)
    myBus.sendControllerChange(4, 45, int(x)); //Frequency/Sampling
    myBus.sendControllerChange(4, 46, int(y)); //Amp/Bit Depth 
  } else {
    //turn off bit crusher effects 
    myBus.sendControllerChange(4, 45, 0);
    myBus.sendControllerChange(4, 46, 85);
  }
  //println("BitCrush Effect is " + canBitcrush);
  //canBitcrush = !isBitCrushOn; //flip and update global
}


//LOW PASS FILTER. 
// Frame Differencing: Video 3 (Drums)
void LPF(float freq, int controller, int channel) {
  myBus.sendControllerChange(channel, controller, int(freq));
}

//LOW PASS FILTER with Q
// Joystick Effect: Video 1 (Arp)
void LPFwQ(float freq, int FreqController, float Q, int QController, int channel) {
  myBus.sendControllerChange(channel, FreqController, int(freq)); //freq 0-127
  myBus.sendControllerChange(channel, QController, int(Q));       //Q    0-127
}

/*
  Based upon interface video booleans, alter sound focus
  has specific MIDI control change messages for each video
  MIDI channel is always 2 (proc is 1)
*/
void changeSoundHighlightControls(int vid) {
  int controllerNum = 30+vid; //video 1 (31), 2 (32), 3 (33), 4 (34)
  //println("video is: " + vid);
  //println("controller is: " + controllerNum);
  
  int maxVol = 90; // 90 is 0dB. 64 is -6dB
  if (vid == 1) { maxVol = 60; } //arp -7dB
  if (vid == 2) { maxVol = 60; } //bass -7dB
  if (vid == 3) { maxVol = 91; } //drums
  
  
  //Is video showing? toggle the controller
  if (canShowVideo[vid-1]) {
    myBus.sendControllerChange(1, controllerNum, maxVol); //90 is 0dB
  } else {
    myBus.sendControllerChange(1, controllerNum, 0);
    //println("controller mute");
  }
  
  //initialize sound when video is selected (so we have a sound when selecting the video)
  switch(vid) {
    case 1:
      trackBlobs(); //placeholder
      break;
    case 2:
      changeNotesVideo2(int(random(0,6))); // upon highlight, trigger random note until we get data
      //changeNotes(video); //need to do more 
      break;
    case 3:
      selectNewDrumPattern(); //start new drum pattern
      break;
    case 4:
      focusPixel = 10890; //reset focusPixel to the middle upon restart of this image
      changeNotesVideo4(int(random(0,11))); // upon highlight, trigger random note until we get data
      break;
  }
  
}

//PLACEHOLDER for Blob tracking
//'A' to turn notes off.
void trackBlobs() {
  //create blobs and determine their pitch!
  // pitch set is always len 12
  int[] pitchSetA1 = { 48, 50, 55, 57, 58, 60, 62, 64, 67, 69, 72, 82 };
  int[] blobs = { 0, 0, 0, 0, 0, 0, 0, 0};
  int blob = 0;
  for (int i=0; i<8; i++) {
    blob = int(random(0,3));
    if (blob > 0) {
      blob = pitchSetA1[int(random(0,12))];
    } else {
      blob = 0; 
    }
    //init blob array
    blobs[i] = blob;
    //print(blobs[i] + ", ");
  }
  //println();
  blobNotes(blobs); //change notes based upon blobs 
}


//TIMER: Business Hours
void changeMasterFader(int faderVal) {
  //only change when global allows it
  if (canChangeMasterFader) {
    myBus.sendControllerChange(0, 36, faderVal);
  }
}

//TIMER: audio stopwatch
/*
 * Check for non-activity on user interface and mute audio if non-activity after N seconds.
 * requires setting global counters from "vals" that is our data from the Arduino (see SerialEvent() in main tab)
 */
void checkAudioStopWatch() {
  
  //println(sw.getElapsedTime());
  
  if (restartAudioCountDown) {
    sw.stop();
    restartAudioCountDown = false;
    //println("activity! restarted timer");
    sw.start();
  } else if (sw.getElapsedTime() > audioTotalCountDown) {
    //mute audio faders and restart clock!
    sw.stop();
    for (int i=0; i<4; i++) {
      canShowVideo[i] = false; 
      int controllerNum = 31+i; //video 1 (31), 2 (32), 3 (33), 4 (34)
      myBus.sendControllerChange(1, controllerNum, 0);
    }
    println("sound muted, no activity after " + audioTotalCountDown/1000 + " seconds!");
    sw.start();
  }
  
}

/*
 * Stopwatch Timer
 */
class StopWatchTimer {
  int startTime = 0, stopTime = 0;
  boolean running = false;  
  
    void start() {
        startTime = millis();
        running = true;
    }
    void stop() {
        stopTime = millis();
        running = false;
    }
    int getElapsedTime() {
        int elapsed;
        if (running) {
             elapsed = (millis() - startTime);
        }
        else {
            elapsed = (stopTime - startTime);
        }
        return elapsed;
    }
    int second(){
      return (getElapsedTime() / 1000) % 60;
    }
    int minute() {
      return (getElapsedTime() / (1000*60)) % 60;
    }
    int hour() {
      return (getElapsedTime() / (1000*60*60)) % 24;
    }
}