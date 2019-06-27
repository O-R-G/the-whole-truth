/**
 * spectrum
 *
 * analyzes a stream of sound using a Fast Fourier Transform
 * to unpack constituent frequencies displayed as amplitudes
 * changing over time. number of FFT bands can be adjusted 
 * for finer/coarser resolution.
 *
 * based on FFTSpectrum example in processing.sound        
 * uses processing.sound for FFT analysis
 * uses Speech-to-text-normal        
 *
 * O-R-G
 * for Lawrence Abu Hamdan, The Whole Truth
 */

import processing.sound.*;

SoundFile sample;
FFT fft;
PFont mono;

// Define how many FFT bands to use (this needs to be a power of two)
int bands = 128;

// Define a smoothing factor which determines how much the spectrums of consecutive
// points in time should be combined to create a smoother visualisation of the spectrum.
// A smoothing factor of 1.0 means no smoothing (only the data from the newest analysis
// is rendered), decrease the factor down towards 0.0 to have the visualisation update
// more slowly, which is easier on the eye.
float smoothingFactor = 0.2;

// Create a vector to store the smoothed spectrum data
float[] sum = new float[bands];

int scale = 5;
float barWidth;

public void setup() {
    size(640, 360);
    background(255);

    barWidth = width/float(bands);

    // sample = new SoundFile(this, "the-whole-truth-90-seconds.wav");
    sample = new SoundFile(this, "the-whole-truth.wav");
    while (second() % 5 !=0) {
        // wait so that all three apps start audio at same time
    }
    sample.play();

    fft = new FFT(this, bands);
    fft.input(sample);

    mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {
    background(0);
    fill(255,0,0);
    noStroke();

    fft.analyze();

    for (int i = 0; i < bands; i++) {
        // adjust color between r and b
        fill(i*2,0,((bands-i)*2)-1);

        // Smooth the FFT spectrum data by smoothing factor
        sum[i] += (fft.spectrum[i] - sum[i]) * smoothingFactor;

        // Draw the rectangles, adjust their height using the scale factor
        rect(i*barWidth, height, barWidth, -sum[i]*height*scale);
    }
    show_current_millis();
}

private void show_current_millis() {
    fill(255);
    text(millis(),width-100,24);
}
