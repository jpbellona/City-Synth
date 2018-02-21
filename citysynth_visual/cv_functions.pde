
///////////////////////
// Display Functions
///////////////////////

void displayImages() {

  pushMatrix();
 // scale(0.5);
  //image(src, 0, 0);
  //image(preProcessedImage, src.width, 0);
  //image(processedImage, 0, src.height);
 // image(src, src.width, src.height);
 //println("SRC is: "+ src.width+", "+src.height);
  image(src, 20, 20, 1550, 872);
  // Visual Sizes: Dominant X,Y,W,H: 20,20, 1550, 872
//                 3 smaller W,H: 318,178
//                 3 smaller top left corners: (1586,20), (1586, 365), (1586, 710)

  popMatrix();

  stroke(255);
  fill(255);
  textSize(12);
 // text("Source", 10, 25); 
  //text("Pre-processed Image", src.width/2 + 10, 25); 
 // text("Processed Image", 10, src.height/2 + 25); 
  //text("Tracked Points", src.width/2 + 10, src.height/2 + 25);
}

void displayBlobs() {
int num=0;
  for (Blob b : blobList) {
    strokeWeight(1);
    if(blobList.size() >= 4 && num> blobList.size()-5){
    //if(num == 2 || num == 5 || num == 8) {
      b.display(1);
      //println("bloblist size: "+blobList.size());
      
    }
    else b.display(0);
    num++;
  }
}

void displayContours() {

  // Contours
  for (int i=0; i<contours.size(); i++) {

    Contour contour = contours.get(i);

    noFill();
    stroke(0, 255, 0);
    strokeWeight(3);
    contour.draw();
  }
}

void displayContoursBoundingBoxes() {

  for (int i=0; i<contours.size(); i++) {

    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (//(contour.area() > 0.9 * src.width * src.height) ||
      (r.width < blobSizeThreshold || r.height < blobSizeThreshold) && (r.width > 50 && r.height > 50))
      continue;

    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
}

////////////////////
// Blob Detection
////////////////////

void detectBlobs() {

  // Contours detected in this frame
  // Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true, true);

  newBlobContours = getBlobsFromContours(contours);

  //println(contours.length);

  // Check if the detected blobs already exist are new or some has disappeared. 

  // SCENARIO 1 
  // blobList is empty
  if (blobList.isEmpty()) {
    // Just make a Blob object for every face Rectangle
    for (int i = 0; i < newBlobContours.size(); i++) {
      //println("+++ New blob detected with ID: " + blobCount);
      blobList.add(new Blob(this, blobCount, newBlobContours.get(i)));
      blobCount++;
    }

    // SCENARIO 2 
    // We have fewer Blob objects than face Rectangles found from OpenCV in this frame
  } else if (blobList.size() <= newBlobContours.size()) {
    boolean[] used = new boolean[newBlobContours.size()];
    // Match existing Blob objects with a Rectangle
    for (Blob b : blobList) {
      // Find the new blob newBlobContours.get(index) that is closest to blob b
      // set used[index] to true so that it can't be used twice
      float record = 50000;
      int index = -1;
      for (int i = 0; i < newBlobContours.size(); i++) {
        float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
        //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
        if (d < record && !used[i]) {
          record = d;
          index = i;
        }
      }
      // Update Blob object location
      used[index] = true;
      b.update(newBlobContours.get(index));
    }
    // Add any unused blobs
    for (int i = 0; i < newBlobContours.size(); i++) {
      if (!used[i]) {
       // println("+++ New blob detected with ID: " + blobCount);
        blobList.add(new Blob(this, blobCount, newBlobContours.get(i)));
        //blobList.add(new Blob(blobCount, blobs[i].x, blobs[i].y, blobs[i].width, blobs[i].height));
        blobCount++;
      }
    }

    // SCENARIO 3 
    // We have more Blob objects than blob Rectangles found from OpenCV in this frame
  } else {
    // All Blob objects start out as available
    for (Blob b : blobList) {
      b.available = true;
    } 
    // Match Rectangle with a Blob object
    for (int i = 0; i < newBlobContours.size(); i++) {
      // Find blob object closest to the newBlobContours.get(i) Contour
      // set available to false
      float record = 50000;
      int index = -1;
      for (int j = 0; j < blobList.size(); j++) {
        Blob b = blobList.get(j);
        float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
        //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
        if (d < record && b.available) {
          record = d;
          index = j;
        }
      }
      // Update Blob object location
      Blob b = blobList.get(index);
      b.available = false;
      b.update(newBlobContours.get(i));
    } 
    // Start to kill any left over Blob objects
    for (Blob b : blobList) {
      if (b.available) {
        b.countDown();
        if (b.dead()) {
          b.delete = true;
        }
      }
    }
  }

  // Delete any blob that should be deleted
  for (int i = blobList.size()-1; i >= 0; i--) {
    Blob b = blobList.get(i);
    if (b.delete) {
      blobList.remove(i);
    }
  }
}

ArrayList<Contour> getBlobsFromContours(ArrayList<Contour> newContours) {

  ArrayList<Contour> newBlobs = new ArrayList<Contour>();

  // Which of these contours are blobs?
  for (int i=0; i<newContours.size(); i++) {

    Contour contour = newContours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (//(contour.area() > 0.9 * src.width * src.height) ||
      (r.width < blobSizeThreshold || r.height < blobSizeThreshold))
      continue;
    newBlobs.add(contour);
  }
  return newBlobs;
}




/**
 * Blob Class
 *
 * Based on this example by Daniel Shiffman:
 * http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
 * @author: Jordi Tost (@jorditost)
 * University of Applied Sciences Potsdam, 2014
 */

class Blob {
  
  private PApplet parent;
  
  // Contour
  public Contour contour;
    public boolean available;
    public boolean delete;
    private int initTimer = 5; //127;
  public int timer;
  
  // Unique ID for each blob
  int id;
  int pitchCh1;
  Note blobCh1;
  int pitchCh2;
  Note blobCh2;
  
  // Make me
  Blob(PApplet parent, int id, Contour c) {
    this.parent = parent;
    this.id = id;
    this.contour = new Contour(parent, c.pointMat);
    
    available = true;
    delete = false;
    
    timer = initTimer;
    
    pitchCh1 = 60;
    pitchCh2 = 60;
    blobCh1  = new Note(0, pitchCh1, 127);
    blobCh2  = new Note(1, pitchCh2, 127);
  }
  
  // Show me
  void display(int chosen) {
    Rectangle r = contour.getBoundingBox();
    int doRed = chosen;
    float opacity = map(timer, 0, initTimer, 0, 127);
    if(doRed == 1) {
     fill(255,0,0,opacity);
     // create blob notes... x = ch1, y = ch2
     pitchCh1 = 11*r.x/960;
     pitchCh2 = 11*r.y/540;
     if(frameCount %10 == 0){
     Note blobCh1  = new Note(0, pitchSetA[pitchCh1], 100+int(random(0,27)));
     Note blobCh2  = new Note(1, pitchSetA[pitchCh2], 100+int(random(0,27)));
     myBus.sendNoteOn(blobCh1); //blob notes correspond to blobs
     myBus.sendNoteOn(blobCh2); //blob notes correspond to blobs
     }
     //println("Sample to midi: "+11*r.x/960+","+11*r.y/540);
     //x and y position as note, note on, when dead, note off.
     
    }
    else fill(0,0,255,opacity);
    stroke(255);
    strokeWeight(.5);
    pushMatrix();
    translate(20,20);
    scale(1.61,1.61);
   // scale(2);
    if(r.width < 150) rect(r.x, r.y, r.width, r.height);  // ****  RECTS ****
    fill(255,2*opacity); 
    textSize(12);
    text(""+id, r.x+10, r.y+30);
    popMatrix();
  }

  // Give me a new contour for this blob (shape, points, location, size)
  // Oooh, it would be nice to lerp here!
  void update(Contour newC) { 
    contour = new Contour(parent, newC.pointMat);
    timer = initTimer;
  }

  // Count me down, I am gone
  void countDown() {    
    timer--;
  }

  // I am deed, delete me
  boolean dead() {
    if (timer < 0) { 
      myBus.sendNoteOff(blobCh1);
      myBus.sendNoteOff(blobCh2);
      return true;
    }
    return false;
  }
  
  //int getPitchCh1() {
  //  return pitchCh1; 
  //}
  //int getPitchCh2() {
  //  return pitchCh2; 
  //}
  
  public Rectangle getBoundingBox() {
    return contour.getBoundingBox();
  }
}

//////////////////////////
// CONTROL P5 Functions
//////////////////////////

//void initControls() {
//  cp5.setAutoDraw(showCP5); 
//  // Slider for contrast
//  cp5.addSlider("contrast")
//    .setLabel("contrast")
//    .setPosition(20, 50)
//    .setRange(0.0, 6.0)
//    ;

//  // Slider for threshold
//  cp5.addSlider("threshold")
//    .setLabel("threshold")
//    .setPosition(20, 110)
//    .setRange(0, 255)
//    ;

//  // Toggle to activae adaptive threshold
//  cp5.addToggle("toggleAdaptiveThreshold")
//    .setLabel("use adaptive threshold")
//    .setSize(10, 10)
//    .setPosition(20, 144)
//    .setValue(true);
//    ;

//  // Slider for adaptive threshold block size
//  cp5.addSlider("thresholdBlockSize")
//    .setLabel("a.t. block size")
//    .setPosition(20, 180)
//    .setRange(1, 700)
//    ;

//  // Slider for adaptive threshold constant
//  cp5.addSlider("thresholdConstant")
//    .setLabel("a.t. constant")
//    .setPosition(20, 200)
//    .setRange(-100, 100)
//    ;

//  // Slider for blur size
//  cp5.addSlider("blurSize")
//    .setLabel("blur size")
//    .setPosition(20, 260)
//    .setRange(1, 20)
//    ;

//  // Slider for minimum blob size
//  cp5.addSlider("blobSizeThreshold")
//    .setLabel("min blob size")
//    .setPosition(20, 290)
//    .setRange(0, 60)
//    ;

//  // Store the default background color, we gonna need it later
//  buttonColor = cp5.getController("contrast").getColor().getForeground();
//  buttonBgColor = cp5.getController("contrast").getColor().getBackground();
//}

//void toggleAdaptiveThreshold(boolean theFlag) {

//  useAdaptiveThreshold = theFlag;

//  if (useAdaptiveThreshold) {

//    // Lock basic threshold
//    setLock(cp5.getController("threshold"), true);

//    // Unlock adaptive threshold
//    setLock(cp5.getController("thresholdBlockSize"), false);
//    setLock(cp5.getController("thresholdConstant"), false);
//  } else {

//    // Unlock basic threshold
//    setLock(cp5.getController("threshold"), false);

//    // Lock adaptive threshold
//    setLock(cp5.getController("thresholdBlockSize"), true);
//    setLock(cp5.getController("thresholdConstant"), true);
//  }
//}

//void setLock(Controller theController, boolean theValue) {

//  theController.setLock(theValue);

//  if (theValue) {
//    theController.setColorBackground(color(150, 150));
//    theController.setColorForeground(color(100, 100));
//  } else {
//    theController.setColorBackground(color(buttonBgColor));
//    theController.setColorForeground(color(buttonColor));
//  }
//}