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

int[][] sgram;              // all spectrogram data
int columns = 300;          // spectrogram width in pixels
int rows = 600;             // spectrogram height in pixels
                            // also the number of bands in FFT
float sampleRate = 48000;   // from the audio file
int bufferSize = 1024;      // must be a power of 2
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";
int column;
int counter;

void setup() {
    size(300, 600, FX2D);          
    colorMode(HSB);

    sgram = new int[rows][columns];

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
 
    minim = new Minim(this);
    sample = minim.loadFile(data_path + "the-whole-truth.wav", bufferSize);
    fft = new FFT(sample.bufferSize(), sampleRate);
    fft.window(FFT.HAMMING);      // tapered time window avoids 'splatter'
    sample.play();

    counter = 0;
}
 
void draw() {
    background(0);
    stroke(255);

    fft.forward(sample.mix);    
    update_spectrogram();      
    // draw_axis();
    // if (counter % 300 < 50) 
        draw_spectrogram();
    counter++;
} 

Boolean update_spectrogram() {

    /*
        updates sgram[][] ring-filled array, updates one column at a time
        get magnitude for each each frequency band in FFT
        then 2*20*Math.log10(1000*fft.getBand(i))) to convert magnitude -> decibels
        (magnitude is distance from 0 in either direction,
        amplitude includes direction, so can be positive or negative)
        updates one column (all rows) because spectrogram is like 
        spectrum rotated 90 degrees counterclockwise and then 90 degrees in z
        fft.specSize() returns number of bands (same as rows)

        waveform (amp/time)
            _
        _  / \__
         \/

        spectrum (amp/freq)
        
        .| .|
        ||.|||..
        
        spetrogram (amp/freq/time)
        
        .*+-**-.
        --.+.-+.
        ..x.**.+
        .+....-.
        
    */

    for (int i = 0; i < rows; i++)
        sgram[i][column] = (int)Math.round(Math.max(0,2*20*Math.log10(1000*fft.getBand(i))));
    column++;
    if (column == columns) 
        column = 0; 
    return true;
}

Boolean draw_spectrogram() {

    // draw sgram[column][] to sgram[columns][]
    // then draw sgram[0][] to sgram[column][]

    for (int i = 0; i < columns-column; i++) {
        for (int j = 0; j < rows; j++) {
            stroke(sgram[j][i+column],255,255);
            point(i,height-j);
        }
    }
    for (int i = 0; i < column; i++) {
        for (int j = 0; j < rows; j++) {
            stroke(sgram[j][i],255,255);
            point(i+columns-column,height-j);
        }
    }
    return true;
}

void draw_axis() {

    int x = columns + 2;     // to right of spectrogram display
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
    // always dispose minim object
    sample.pause();
    minim.stop();
    super.stop();
}
