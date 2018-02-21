// CITY SYNTH IP tab.
// FUNCTIONS related to IP camera and visuals


// VIDEO 1 (ARP) blob tracking
void blobTracking() {
  // Load the new frame of our camera in to OpenCV
  opencv.loadImage(cam);
  src = opencv.getSnapshot();
  opencv.gray();
  opencv.contrast(contrast);
  preProcessedImage = opencv.getSnapshot();
  if (useAdaptiveThreshold) {
    // Block size must be odd and greater than 3
    if (thresholdBlockSize%2 == 0) thresholdBlockSize++;
    if (thresholdBlockSize < 3) thresholdBlockSize = 3;

    opencv.adaptiveThreshold(thresholdBlockSize, thresholdConstant);
  } else {
    opencv.threshold(threshold);
  }

  opencv.invert();
  opencv.dilate();
  opencv.erode();
  opencv.blur(blurSize);
  processedImage = opencv.getSnapshot();

  detectBlobs();
  contours = opencv.findContours(true, true);
  contoursImage = opencv.getSnapshot();

  // Draw
  pushMatrix();
  //translate(width-src.width, 0);
  displayImages();
  pushMatrix();
  displayBlobs();
  popMatrix(); 
  popMatrix();
}


// VIDEO 2 (BASS) slit scan
void drawSlitScan() {

  cam.read();
  cam.resize(width, height);  // *********  UPDATED ***********

  // Copy a column of pixels from the middle of the video 
  // To a location moving slowly across the canvas.
  cam.loadPixels();

  holder.beginDraw();  // **** NEW ****
  holder.loadPixels();
  sway = noise(frameCount /310.0);
  videoSliceX = int(sway*(cam.width-4)+2);
   int tempJoy = int(map(mouseY, 0, height, 0, 400));
 // println(tempJoy);
  r=0;
  g=0;
  b=0;
  for (int i=0; i<3; i++) {
    for (int y = 0; y < cam.height; y++) {
      int setPixelIndex = y*width + drawPositionX;
      int getPixelIndex = y*cam.width  + videoSliceX;
      holder.pixels[setPixelIndex] = cam.pixels[getPixelIndex];
      if(y>440 && y< 640 && i==0){
      r+= red(holder.pixels[setPixelIndex]);
      g+= green(holder.pixels[setPixelIndex]);
      b+= blue(holder.pixels[setPixelIndex]);
      }
    }
    drawPositionX-=1;
    if (drawPositionX < 1) {
      drawPositionX = width - 1;
    }

    holder.updatePixels();

    // Small indicator
    holder.stroke(255);
    holder.noFill();
    cam.updatePixels();
  }
  color avColor = color(r/200, g/200, b/200);
  int slitBassNote = int(brightness(avColor)/43);
  if (slitBassNote < 0) { slitBassNote = 0; }
  else if (slitBassNote > 5) { slitBassNote = 5; }
  if (slitBassNote != prevBassNote) {
    //println("SENDING TO MIDI: "+ slitBassNote); //
    //changeNotesVideo2(slitBassNote);
    changeNotesVideo2(int(random(0,6)));
  }
  prevBassNote = slitBassNote;
 
  // Little Pic
  holder.pushMatrix();
  holder.translate(40,-23);
  holder.image(cam, 10, holder.height-195, 332, 183);
  holder.line(10 + sway*332, holder.height-195, 10 + sway*332, holder.height-12);
  holder.rect(10, holder.height-195, 332, 183); // main white big box
  holder.rect(10+sway*332-10, holder.height-195+91-20, 20, 40); // little focus box
 //holder.rectMode(CENTER);
  holder.fill(avColor);
  holder.rect(362, holder.height-150, 90, 90);
 
  //holder.rectMode(CORNER);
  holder.textSize(16);
  holder.fill(255);
  holder.textAlign(CENTER, CENTER);
  holder.text("Av.Color", 362+45, holder.height-150 +45);
  holder.popMatrix();
  holder.endDraw();

  dominant = holder;
}

/*
 * Video 3 effect (OK GO)
 * 
 */
void frameDifference() {
  cam.read();
  cam.resize(width, height);
  cam.loadPixels();
  arrayCopy(cam.pixels, currentBlurred);
  fastblur(currentBlurred, width, height, blurRadius);
  holder.beginDraw();
  holder.loadPixels();
  for (int i = 0; i < width * height; i++) {
    int targetIndex;
    if (mirrorX) {
      int x = i % width;
      int y = floor(i / width);
      x = width - x - 1;
      targetIndex = y * width + x;
    } else {
      targetIndex = i;
    }
    int blurredColor = currentBlurred[i];
    int blurredR     = (blurredColor >> 16) & 0xFF;
    int blurredG     = (blurredColor >> 8) & 0xFF;
    int blurredB     = blurredColor & 0xFF;

    int bgColor      = cleanPlate[i];
    int bgR          = (bgColor >> 16) & 0xFF;
    int bgG          = (bgColor >> 8) & 0xFF;
    int bgB          = bgColor & 0xFF;

    boolean isBackground = (abs(blurredR - bgR) < thresholdOK) && (abs(blurredG - bgG) < thresholdOK) && (abs(blurredB - bgB) < thresholdOK);
    if (isBackground == false) holder.pixels[targetIndex] = cam.pixels[i];

    // if hue shift get HSB of current color and shift Hue
    if (hueShiftSpeed > 0) {
      colorMode(HSB, 1);
      color col = holder.pixels[targetIndex];
      float h = hue(col);
      float s = saturation(col);
      float b = brightness(col);
      holder.pixels[targetIndex] = color(h + hueShift, s, b);
      colorMode(RGB, 255);
    }
  }
  holder.updatePixels();
  holder.endDraw();
  //dominant = holder;
  //image(coverB2, 0, 0);
}

// save clean plate
void saveCleanPlate() {
  cam.read();
  cam.loadPixels();
  arraycopy(cam.pixels, cleanPlate);
  fastblur(cleanPlate, width, height, blurRadius);
  //background(255);
}

/*
 * Video 4 effects (3D array of letters as camera pixels
 * @author John Park
 */
void makeLetters() {
  hint(DISABLE_DEPTH_TEST);

  x -= (x-xT)*.04;
  y -= (y-yT)*.04;
  // Send every second, only send if 10% difference from last note
  // send 0-11;
  little.beginDraw();
  little.background(0);
  little.image(cam, 0, 0, 180, 120);
  little.endDraw();

  holder.beginDraw();
  if(invertColors == false) holder.background(0);
  else holder.background(255);
  //holder.fill(brightness(pic.pixels[i])/5.0 + 200, 0, 255);

  little.loadPixels();
  holder.translate(width/2+x, height/2+y, 0);
 // holder.rotateY(radians((noise(frameCount / 40.0)-.5)*25));
  holder.rotateY(radians( (joyX - 200)/5) );
  holder.translate(0,0,joyY-200);
  for (int i=0; i<little.pixels.length; i++) {

    int x= (i%little.width)-little.width/2;
    int y= (i/little.width) - little.height/2;
    holder.textSize(brightness(little.pixels[i])/10.0 + 3);
    holder.pushMatrix();
    holder.translate(0, 0, brightness(little.pixels[i])*1.4);
    
    if(invertColors == false) {
      holder.fill(brightness(little.pixels[i])/5.0 + 200, 255);
      holder.textSize(brightness(little.pixels[i])/10.0 + 3);
    }
    else{
     
     holder.fill(255-(brightness(little.pixels[i])/5.0 + 200), 255);
      holder.textSize(brightness(little.pixels[i])/10.0 + 3);
    }
    
    if (i == focusPixel) { //def. 10890
      //println("inside pixel");
      //turns true every second
      
      int p6index = int(((brightness(little.pixels[i])*12) / 255));
      if (canSendVid4Note) {
        if (p6index != prevVid4Note) {
          //println(p6index);
          changeNotesVideo4(p6index);
        }
        canSendVid4Note = !canSendVid4Note;
      }
      prevVid4Note = p6index;
      holder.fill(255, 0, 0);
      holder.textSize(40);
    } 
    
    
    
    if (brightness(little.pixels[i]) > 230) text("e", x*4*1.4, y*4*1.4);
    else if (brightness(little.pixels[i]) > 200 && brightness(little.pixels[i]) <= 230) holder.text("n", x*4*1.4, y*4*1.4);
    else if (brightness(little.pixels[i]) > 160 && brightness(little.pixels[i]) <= 200) holder.text("e", x*4*1.4, y*4*1.4);
    else if (brightness(little.pixels[i]) > 105 && brightness(little.pixels[i]) <= 160) holder.text("g", x*4*1.4, y*4*1.4);
    else if (brightness(little.pixels[i]) > 80 && brightness(little.pixels[i]) <= 105) holder.text("u", x*4*1.4, y*4*1.4);
    else if (brightness(little.pixels[i]) > 40 && brightness(little.pixels[i]) <= 80) holder.text("e", x*4*1.4, y*4*1.4);
    holder.popMatrix();
  }
  //holder.updatePixels();
  holder.endDraw();
  dominant = holder;
  //println("TOTAL: "+little.pixels.length);
  //once a second send Z value of red pixel (0-11 value)
  //only send if changed its 0-11 value.
} 

void flushHolder() {
  holder.beginDraw();
  holder.loadPixels();
  for (int i=0; i<holder.pixels.length; i++) {
    holder.pixels[i] = 0x000000;
  }
  holder.updatePixels();
  holder.endDraw();
}


//would we have FOUR videos rolling at once? (quadrants?)
void changeIPVidControls(int vid) {
  //IP video
  // must check to see if Available first before calling STOP. otherwise processing will hang
  if (cam.isAvailable()) {
    //cant stop a camera if it's not available. this hangs processing.
    //if one camera goes down we can still use other three
    cam.stop();  //THIS fails with SERT camera feed if no check. ???? we do get 503 HTTP error
    //println("camera stopped");
    delay(100);
  } 
    //else {
    //  cam.dispose(); //this breaks us
    //}
    
  cam = new IPCapture(this, urls[vid-1], "", "");
  //cam.start();
  //try {
    cam.start();
    delay(100);
  //} catch (RuntimeException e) {
  //  e.printStackTrace();
  //  println("error caught");
  //}
  
  //println("loaded new camera");
 // cam.resize(1550, 872);
 cam.resize(width, height);
  //println("camera started");
 // numPixels = cam.width * cam.height; //add check here to skip cam.stop if we changeVID controls?
  numPixels = width * height; //add check here to skip cam.stop if we changeVID controls?
  previousFrame = new int[numPixels]; 
}