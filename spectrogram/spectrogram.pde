/**
 * LiveSpectrogram
 * Takes successive FFTs and renders them onto the screen as grayscale, scrolling left.
 *
 * Dan Ellis dpwe@ee.columbia.edu 2010-01-15
 */
 
import ddf.minim.analysis.*;
import ddf.minim.*;
 
Minim minim;
AudioInput in;
AudioPlayer sample;
FFT fft;

PFont mono;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";

int colmax = 300;       // spectrogram size in pixels
int rowmax = 600;       // rowmax is also the number of bands in FFT
                        // this should be more transparent (!) in variable names
                        // are rows and cols backwards in array and otherwise?
                        // fft.specSize() returns number of bands (same as rowsize)
                        // but this must be called after the fft object is created

// float sampleRate = 22050;
// int bufferSize = 1024;  // must be power of 2

float sampleRate = 48000;
int bufferSize = 1024;  // must be power of 2
// int bufferSize = 2048;  // must be power of 2
// int bufferSize = 512;  // must be power of 2

int[][] sgram = new int[rowmax][colmax];
int col;
int leftedge;

int counter;

void setup() {
    // size(300, 600);                // slow
    // size(300, 600, P2D);              // faster
    // size(300, 600, P3D);           // faster
    size(300, 600, FX2D);          // fastest, little quirky
    colorMode(HSB);
  
    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
 
    minim = new Minim(this);

    /*
    in = minim.getLineIn(Minim.MONO, bufferSize, sampleRate);
    fft = new FFT(in.bufferSize(), in.sampleRate());
    */

    sample = minim.loadFile(data_path + "the-whole-truth.wav", bufferSize);
    // fft = new FFT(sample.bufferSize(), sample.sampleRate());
    fft = new FFT(sample.bufferSize(), sampleRate);
    fft.window(FFT.HAMMING);      // tapered time window avoids 'splatter'

    // sample.loop();
    sample.play();
    counter = 0;
}
 
void draw() {
    background(0);
    stroke(255);
    // fft.forward(in.mix);    // forward FFT on samples in buffer
    fft.forward(sample.mix);    // forward FFT on samples in buffer

    update_spectrogram();      
    // if (counter % 300 < 50) 
        draw_spectrogram();      
    // draw_axis();

    counter++;
} 

Boolean update_spectrogram() {

    // updates sgram[][] (int[][])
    // ring-filled array which updates one col at a time
    // get magnitude for each each frequency band in FFT
    // then 2*20*Math.log10(1000*fft.getBand(i))) to convert magnitude -> decibels
    // (magnitude is distance from 0 in either direction)
    // (amplitude includes direction, so can be positive or negative)
    // updates one col (all rows) because spectrogram is like 
    // spectrum rotated 90 degrees counterclockwise and then 90 degrees in z
    // fft.specSize() returns number of bands (same as rowsize)

    for (int i = 0; i < rowmax /* fft.specSize() */; i++)
        sgram[i][col] = (int)Math.round(Math.max(0,2*20*Math.log10(1000*fft.getBand(i))));
    col++;
    if (col == colmax) 
        col = 0; 
    // seems leftedge & col are always equal, need both?
    // cols run from right to left, [0-colmax]
    // also looks like col starts with value 1, not 0 and that is why there is 
    // a blip at left of window
    leftedge++; 
    if (leftedge == colmax)
        leftedge = 0; 

    // debug
    println("col      " + col);
    println("leftedge " + leftedge);
    if (col != leftedge)
        println("*****************");

    return true;
}

Boolean draw_spectrogram() {

    // leftedge is the column in the ring-filled array that is drawn at the extreme left
    // start from there, and draw to the end of the array
    for (int i = 0; i < colmax-leftedge; i++) {
        for (int j = 0; j < rowmax; j++) {
            stroke(sgram[j][i+leftedge],255,255);
            point(i,height-j);
        }
    }
    // rest of the image as the beginning of the array (up to leftedge)
    for (int i = 0; i < leftedge; i++) {
        for (int j = 0; j < rowmax; j++) {
            stroke(sgram[j][i],255,255);
            point(i+colmax-leftedge,height-j);
        }
    }
    return true;
}

void draw_axis() {
    // frequency axis (y)
    int x = colmax + 2;     // to right of spectrogram display
    stroke(255);
    line(x,0,x,height);     // vertical line
    textAlign(LEFT,CENTER);
    for (float freq = 0.0; freq < in.sampleRate()/2; freq += 500.0) {
        int y = height - fft.freqToIndex(freq); // which bin holds this frequency
        line(x,y,x+3,y);    // tick mark
        text(Math.round(freq)+" Hz", x+5, y); // add text label
    }
}

void exit() {
    stop();
}

void stop() {
    // dispose minim object
    // in.close();
    sample.pause();
    minim.stop();
    super.stop();
}
