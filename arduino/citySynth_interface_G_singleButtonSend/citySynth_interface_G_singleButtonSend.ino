/*
 * City Synth interface 
 * 
 * Transmit four buttons as toggles and joystick XY.
 * Control neo-pixel lights (R,G,B,Y) according to each button.
 * Requires 'r' sent from host computer in order to send data packets
 * 
 * interface builder: Jeremy Schropp <schropp@harmoniclab.org>
 * interface builder: Nathan Asman <musicmanasman@gmail.com>
 * code author: Jon Bellona <bellona@harmoniclab.org>
 * code author: Nathan Asman <musicmanasman@gmail.com>
 */

 //TODO
 //- send highlighted button push as int to Serial (vid)
 //- integrate video on/off as secondary button push.

//GLOBAL VARS
int pinLowHigh = 6; //pin for joystick X
int joyX = 0;
int serialvalue;

//Button/LEDs pins
int pinButtons[] = {2, 3, 4, 5};     //R, G, B, Y
int pinButtonVals[] = {0, 0, 0, 0};  //R, G, B, Y
int pinButtonLEDs[] = {7, 8, 9, 10}; //R, G, B, Y
//Button Booleans
bool isVideoHighlighted[] = { true, false, false, false };
bool canShowVideo[] = { false, false, false, false };
int checkLowCounter = 0;
int oldButtonState[] = {LOW, LOW, LOW, LOW};
int newButtonState[] = {LOW, LOW, LOW, LOW};

//DOT STARS
#include <Adafruit_DotStar.h>
// Because conditional #includes don't work w/Arduino sketches...
#include <SPI.h>         // COMMENT OUT THIS LINE FOR GEMMA OR TRINKET
//#include <avr/power.h> // ENABLE THIS LINE FOR GEMMA OR TRINKET
#define NUMPIXELS 124 // Number of LEDs in strip
// (Arduino Uno = pin 11 for data, 13 for clock, other boards are different).
Adafruit_DotStar strip = Adafruit_DotStar(NUMPIXELS, DOTSTAR_BRG);
//RED pin13 .  //GREEN pin11 .  //WHITE gnd
int counter;
int dir = 1;

//JOYSTICK
int leftPin = 16;   //analog pin 2 -- yellow wire
int rightPin = 14;  //analog pin 0 -- black wire
int upPin = 17;     //analog pin 3 -- blue wire
int downPin = 15;   //analog pin 1 -- red wire
int leftVal = 0;
int rightVal = 0;
int upVal = 0;
int downVal = 0;
int joystickHigh = 399;
int joystickX = joystickHigh/2;
int joystickY = joystickHigh/2;

void setup() {
  Serial.begin(9600);

  //Turn Digital pins into Analog
  pinMode(leftPin, INPUT);
  pinMode(rightPin, INPUT);
  pinMode(upPin, INPUT);
  pinMode(downPin, INPUT);

  //Dot Stars init
  #if defined(__AVR_ATtiny85__) && (F_CPU == 16000000L)
    clock_prescale_set(clock_div_1); // Enable 16 MHz on Trinket
  #endif

  strip.begin(); // Initialize pins for output
  strip.show();  // Turn all LEDs off ASAP
}

void loop() {

  //Read button values from digital pins
  for (int i=0; i<=3; i++) {
    pinButtonVals[i] = digitalRead(pinButtons[i]);
    newButtonState[i] = pinButtonVals[i];           // *** NEW button state
  }
  //Joystick pins
  leftVal = digitalRead(leftPin);
  rightVal = digitalRead(rightPin);
  upVal = digitalRead(upPin);
  downVal = digitalRead(downPin);

  if (leftVal == HIGH){
    joystickX--;
  }

  if (rightVal == HIGH){
    joystickX++;
  }

  if (joystickX <= 0){
    joystickX = 0;
  }

  if (joystickX >= joystickHigh){
    joystickX = joystickHigh;
  }

  if (downVal == HIGH){
    joystickY--;
  }

  if (upVal == HIGH){
    joystickY++;
  }

  if (joystickY <= 0){
    joystickY = 0;
  }

  if (joystickY >= joystickHigh){
    joystickY = joystickHigh;
  }

  //Focus on respective LED highlight, update boolean array and button state
  for (int i=0; i<=3; i++) {
    if (pinButtonVals[i] == HIGH) {
      changeVideoHighlightBools(i); //update all LEDs
    }
  }
   
  //Toggle on/off LEDs
  for (int i=0; i<=3; i++) {
    if (isVideoHighlighted[i]) {
      digitalWrite(pinButtonLEDs[i], HIGH);
      dotStars(i);
    } else {
      digitalWrite(pinButtonLEDs[i], LOW);
    }
  }

  
  //only send if data is available.
  if (Serial.available() > 0) {
    serialvalue = Serial.read();
    
    //only send value with ask from host computer
    if (serialvalue == 'r') {

      //joystick
      Serial.print(joystickX); //joystickX
      Serial.print(" ");
      Serial.print(joystickY); //joystickY

      //send highlighted video button as int to Processing
      for (int i=0; i<=3; i++) {
        
        // Has the button gone high since we last read it?
        if (newButtonState[i] == HIGH && oldButtonState[i] == LOW) {

          //if (pinButtonVals[i] == HIGH) { //redundant check?
            Serial.print(" ");
            Serial.print(i+1);
          //} 

        } else {
          checkLowCounter++;
        }
      }

      //no highlighted video if all are false
      if (checkLowCounter == 4) {
        Serial.print(" ");
        Serial.print(0);
      }
      //reset check each loop
      checkLowCounter = 0;

      // Store the button's state so we can tell if it's changed next time round
      for (int i=0; i<=3; i++) {
        oldButtonState[i] = newButtonState[i];
      }
      
      Serial.println(""); //cr after two-packet data.
      delay(5);
    }
  }

  //Update DotStars (pulsing)
  counter = counter+dir;
  if (counter >= 200) {
    dir = -1;
  }
  if (counter <= 0){
    dir = 1;
  }
  strip.show();       // Refresh strip
  delay(3);           //slow down dot star refresh

  
}

// function to send the pin value followed by a "space". 
void sendValue (int x){              
  Serial.print(x);
  Serial.print(" ");
}


/*
 * Which button is highlighted? Alter button booleans 
 * vid index 0-3
 */
void changeVideoHighlightBools(int vid) {
  
 // Serial.println(vid);
  //use vid as index of boolean array to change
  if (isVideoHighlighted[vid]) {
    canShowVideo[vid] = !canShowVideo[vid]; //toggle video boolean
  } else {
    canShowVideo[vid] = true;
    isVideoHighlighted[vid] = true;
  }
  //set all other indices to false
  for (int i=0; i<=3; i++) {
    if (vid != i) {
      isVideoHighlighted[i] = false;
    }
  }
}

/*
 * Match DotStar color to LED color
 * Red, Green, Blue, Yellow
 * vid index is 0-3
 */
void dotStars(int vid) {
  
  if (vid == 0) {
    for(int i = 0; i < 124; i++){
      strip.setPixelColor(i, 0, 255-counter, 0); 
    }
  }
  else if (vid == 1) {
    for(int i = 0; i < 124; i++){
      strip.setPixelColor(i, 255-counter, 0, 0); 
    }
  }
  else if (vid == 2) {
    for(int i = 0; i < 124; i++){
      strip.setPixelColor(i, 0, 0, 255-counter); 
    }
  }
  else {
    for(int i = 0; i < 124; i++){
      strip.setPixelColor(i, 255-counter, 255-counter, 0); 
    }
  }
}
