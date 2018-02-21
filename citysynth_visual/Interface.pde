//INTERFACE TAB

//MouseDragged() is placeholder for Joystick

/*
  Turn on/off global booleans for controlling the video landscape
  Based upon four interface momentary buttons
  First time button pressed, highlight video and turn on (even if on)
  If highlighted, second time button pressed, turn video off.
  If not-highlighted, consider button push a 'first-time' press.
*/
void changeVideoHighlightBools(int vid) {
  
  //println("video " + vid + " highlighted");
  
  //use vid as index of boolean array to change
  if (isVideoHighlighted[vid-1]) {
    canShowVideo[vid-1] = !canShowVideo[vid-1]; //toggle video boolean
  } else {
    canShowVideo[vid-1] = true;
    isVideoHighlighted[vid-1] = true;
  }
  //set all other indices to false
  for (int i=1; i<=4; i++) {
    if (vid != i) {
      isVideoHighlighted[i-1] = false;
    }
  }
  if (canShowVideo[vid-1]) {
    //println("video " + vid + " on"); 
  } else {
    //println("video " + vid + " off"); 
  }
  
}

void joystickMove(int vid, int jX, int jY) {
  
  // what video is highlighted?
  vid=video; 
  //each video has its own ranges, but always should be between 0-127 min/max
  //normalise 0-1 and then set range
  //Y values should flip polarity
  
  //println(jX + ", " + jY);
  
  // placeholders to allow both audio and video controls with joystick function
  int origJX = jX;
  int origJY = jY; 
  
  switch(vid) {
    case 1:
      jX = int( ((float(jX)/float(joystickRange)) * 62) + 65);  // range 65-127                   
      jY = int( ((float(jY)/float(joystickRange)) * 15) + 36);  // range 36-51  
      //println(jX + ", " + jY);
      LPFwQ(jX,55,jY,56,0);                 // MIDI channel 1 (proc is 0) //1st track
      LPFwQ(jX,57,jY,58,0);                 // MIDI channel 1 (proc is 0) //2nd track
      break;
    case 2:
      // audio
      jX= int( (float(jX)/float(joystickRange)) * 127);         // range 0-127
      jY= int( (float(jY)/float(joystickRange)) * 127);         // range 0-127
      alchemyTransform(jX,41,jY,42,2);  // MIDI channel 3 (2 is proc) //3rd track
      break;
    case 3:
      //center should be full fidelty. extremes should be bit crushed 
      //jX= int( (abs((float(jX)/float(joystickRange))-1)) * 90); // range 90-0
      jX= int( (abs(((float(jX)/float(joystickRange))*2)-1)) * 90); // range 90-0-90
      jY= int( (abs((abs((((float(jY)/float(joystickRange)))*2)-1)-1)) * 70) + 16);   // range 16-86-16
      bitCrush(canBitcrush,jX,jY);      // bitcrush function
      
      //reset jX back to do our video transform
      jX = origJX;
      jY = origJY;
      jX= int( map(jX, 0, 400, 50, 150) );  // range 20-150
      //jY= int( map(jX, 0, 400, 20, 150) );
      thresholdOK = jX;
      //println("ok: " + thresholdOK);
      break;
    case 4:
      jX= int( (float(jX)/float(joystickRange)) * 180);        // pixel: x + (y*width);
      jY= int( abs((float(jY)/float(joystickRange))-1) * 120);
     
      
      focusPixel = jX + (jY*180);
      
      //this is redundant IF we also check before we set focusPixel!!!!
      if (focusPixel <= 990) {
        focusPixel = 990;  //maintain position. joystick will naturally move back to center 10890
      }
      if (focusPixel >= 20790) { //total is 21600
        focusPixel = 20790;  //maintain position.  10890 is center
      }
      //println(focusPixel);
      //reset jX back to do our transform
      jX = origJX;
      jY = origJY;
      jX= int( (float(jX)/float(joystickRange)) * 127);         // range 0-127
      jY= int( (float(jY)/float(joystickRange)) * 127);         // range 0-127
      alchemyTransform(jX,51,jY,52,5);  // MIDI channel 6 (proc is 5)
      break;
    
  }
}


/*
 * Return exact serial port of arduino as it constantly updates when you plug in different port.
 * ports is typically Serial.list()
 * matchPort is first part of the string you want to look for, e.g. "/dev/tty.usbmodem"
 *
 * @author Jon Bellona
 */
String findPort(String[] ports, String matchPort) {
  
  String thePort = "";
  
  //loop through list of available ports and try to find a match
  for (String p : ports) {
    String[] m = match(p, matchPort+"(.*)");  
    if (m != null) {
      thePort = matchPort + m[1];
    }
  }
  return thePort;
}