import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import pitaru.sonia_v2_9.*;
import processing.video.*;

Movie movie;

float volume = 0.04;
float sampleVolume = 0.8;

final float RATE_MULTIPLIER = 100.227273;
final float FREQ_CONST = 0.28776978417 * 2;
float freq = 0;

int frame = 0;

Capture cam;

Point camp;

Minim minim;
AudioInput in;
AudioOutput out;
AudioPlayer song;
FFT fft;
Oscil wave;
Oscil mod;
Sample sample;
Sample recording;

float[] recBuffer;

void setup()
{
  camp = new Point(0,0);
  Sonia.start(this);
  
  size(1024, 768, P3D);
 
  // always start Minim first!
  minim = new Minim(this);
 
  // specify 512 for the length of the sample buffers
  // the default buffer size is 1024
  song = minim.loadFile("sample.wav", 1024);
  song.loop();
  song.mute();
  
  sample = new Sample("sample.wav");
  sample.repeat();
  sample.setVolume(sampleVolume);
  
  pitaru.sonia_v2_9.LiveInput.start();
  
  in = minim.getLineIn();
  out = minim.getLineOut();
  
  wave = new Oscil(440, 0.05f, Waves.SINE);
  
  //mod.patch(wave.amplitude);
  // wave.patch(out);
  
  
  // an FFT needs to know how 
  // long the audio buffers it will be analyzing are
  // and also needs to know 
  // the sample rate of the audio it is analyzing
  fft = new FFT(1024, in.sampleRate());
  
  
  cam = new Capture(this, width, height);
  cam.start();
  
  movie = new Movie(this, "chancevid.mov");
  movie.loop();
  movie.volume(volume);
}

class Point {
  public int x;
  public int y;
  Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
void draw() {
  
  if(cam.available()) {
    cam.read();
  }
  
  drawwave();
  // Point p = getPointFromLevel(level);
  setcamera(camp.x, camp.y);
  
  if(random(1) > 0.9) drawNoisyMovieWithColors(cam, 4, 4);
  else if(random(1) > 0.87) drawNoisyMovie(cam, 4, 4);
  
  if(random(1) > 0.9) image(movie, 0, 0);
  frame++;
  
  // translate(p.x, p.y, 0);
  // sphere(28);
  // ellipse(p.x, p.y, 40, 40);
}

void keyPressed() {
  if(key == CODED && keyCode == UP) {
    volume += 0.01;
    if(volume > 1.0) volume = 1.0;
    movie.volume(volume);
    println(volume);
  } else if(key == CODED && keyCode == DOWN) {
    volume -= 0.01;
    if(volume < 0.0) volume = 0.0;
    movie.volume(volume);
    println(volume);
  } else if(key == 'w') {
    sampleVolume += 0.01;
    if(sampleVolume > 1.0) sampleVolume = 1.0;
    sample.setVolume(sampleVolume);
  } else if(key == 's') {
    sampleVolume -= 0.01;
    if(sampleVolume < 0) sampleVolume = 0;
    sample.setVolume(sampleVolume);
  }
  else if(key == '7') {
    camp = new Point(1, 1);
  } else if(key == '8') {
    camp = new Point(width/2, 1);
  } else if(key == '9') {
    camp = new Point(width, 1);
  } else if(key == '6') {
    camp = new Point(width, height/2);
  } else if(key == '5') {
    camp = new Point(width/2, height/2);
  } else if(key == '4') {
    camp = new Point(1, height/2);
  } else if(key == '1') {
    camp = new Point(1, height);
  } else if(key == '2') {
    camp = new Point(width/2, height);
  } else {
    camp = new Point(width, height);
  }
}

Point findbright(Capture cam) {
  int brow = 0;
  int bcol = 0;
  float b = 0;
  cam.loadPixels();
  for(int row = 0; row < height; row++) {
    for(int col = 0; col < width; col++) {
      float thisb = brightness(cam.pixels[row * width + col]);
      if(thisb > b) {
        brow = row;
        bcol = col;
        b = thisb;
      }
    }
  }
  cam.updatePixels();
  return new Point(bcol,brow);
}

void setcamera(int x, int y) {
  if(x == 0) x = 1;
  if(y == 0) y = 1;
  
  int relx;
  if(x < width/2 - 40) relx = -width;
  else if(x > width/2 + 40) relx = width;
  else relx = width/2;
  int rely;
  if(y < height/2 - 40) rely = -height;
  else if(y > height/2 + 40) rely = height/2 + height;
  else rely = height/2;
  
    camera(relx - (frame) + 200, rely, 1000,
           width/2, height/2, 0,
           0, 1, 0);
    
}

Point getPointFromLevel(float level) {
  int d = int(level/0.55555555);
  
  if(d < 1) {
    return new Point(1, 1);
  } else if(d < 2) {
    return new Point(width/2, 1);
  } else if(d < 3) {
    return new Point(width, 1);
  } else if(d < 4) {
    return new Point(width, height/2);
  } else if(d < 5) {
    return new Point(width/2, height/2);
  } else if(d < 6) {
    return new Point(1, height/2);
  } else if(d < 7) {
    return new Point(1, height);
  } else if(d < 8) {
    return new Point(width/2, height);
  } else {
    return new Point(width, height);
  }
}

void movieEvent(Movie m) {
  m.read();
}

void drawwave() {
  background(0);
  fill(255);
  
  float amp;
  float highestamp = 4.0;
  
  float level = pitaru.sonia_v2_9.LiveInput.getLevel();
  fft.forward(in.left);
  for(int i = 0; i < 1760; i++) {
    amp = fft.getFreq(i);
    if(amp > highestamp){
      highestamp = amp;
      freq = i;
    }
  }
  
  text("Frequency: " + freq, 200, 200);
  text("Max: " + highestamp, 200, 300);
  text("Level: " + level, 200, 400);
  
  // wave.setFrequency(freq/4);
 
  // sample.setVolume(level + 0.3);
 
  // float newRate = level * 2 * 88200;
  float newRate = freq/2000 * 88200;
  if(newRate < 22050) newRate = 22050;
  else if(88200 < newRate) newRate = 88200;
  sample.setRate(newRate);
 
  boolean randomcolor = random(1) > 0.7;
  
  if(!randomcolor) stroke(255, 255, 255, 200);
  // draw the spectrum as a series of vertical lines
  // I multiple the value of getBand by 4 
  // so that we can see the lines better
  for(int i = 0; i < fft.specSize(); i++) {
    for(int j = 0; j < 100; j++) {
      if(randomcolor) stroke(random(255), random(255), random(255));
      line(i, height, j * 4, i, height - random(fft.getBand(i)*(height/16)), j * 4);
    }
  }
  stroke(255);
}

void drawNoisyMovie(Movie movie, int rowinc, int colinc) {
  movie.loadPixels();
  loadPixels();
  for(int row = 0; row < height && row < movie.height; row+=rowinc) {
    for(int col = 0; col < width && col < movie.width; col+=colinc) {
      float movieb = brightness(movie.pixels[row * movie.width + col]);
      pixels[row * width + col] = color(random(movieb - 10, movieb + 10));
    }
  }
  movie.updatePixels();
  updatePixels();
}

void drawNoisyMovie(Capture movie, int rowinc, int colinc) {
  movie.loadPixels();
  loadPixels();
  for(int row = 0; row < height && row < movie.height; row+=rowinc) {
    for(int col = 0; col < width && col < movie.width; col+=colinc) {
      float movieb = brightness(movie.pixels[row * movie.width + col]);
      pixels[row * width + col] = color(random(movieb - 10, movieb + 10));
    }
  }
  movie.updatePixels();
  updatePixels();
}

void drawNoisyMovieWithColors(Movie movie, int rowinc, int colinc) {
  movie.loadPixels();
  loadPixels();
  for(int row = 0; row < height && row < movie.height; row++) {
    for(int col = 0; col < width && col < movie.width; col++) {
      if(col % colinc != 0 || row % rowinc != 0) {
        pixels[row * width + col] = color(random(255), random(255), random(255));
      } else {
        float movieb = brightness(movie.pixels[row * movie.width + col]);
        pixels[row * width + col] = color(random(movieb - 10, movieb + 10));
      }
    }
  }
  movie.updatePixels();
  updatePixels();
}

void drawNoisyMovieWithColors(Capture movie, int rowinc, int colinc) {
  movie.loadPixels();
  loadPixels();
  for(int row = 0; row < height && row < movie.height; row++) {
    for(int col = 0; col < width && col < movie.width; col++) {
      if(col % colinc != 0 || row % rowinc != 0) {
        pixels[row * width + col] = color(random(255), random(255), random(255));
      } else {
        float movieb = brightness(movie.pixels[row * movie.width + col]);
        pixels[row * width + col] = color(random(movieb - 10, movieb + 10));
      }
    }
  }
  movie.updatePixels();
  updatePixels();
}
