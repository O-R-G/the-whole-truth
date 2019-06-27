/**
 * detector
 *
 * random walk through array of terms which correlate
 * to values in a lie detector software
 *
 * uses processing.sound for playback
 * uses processing.sound for Amplitude
 * uses Speech-to-text-normal
 *
 * O-R-G
 * for Lawrence Abu Hamdan, The Whole Truth
 */

import processing.sound.*;

SoundFile sample;
PFont mono;
String[] terms;

int counter;
int pointer;
int timer;  // how often to update in loops

public void setup() {
    size(640, 360);
    pixelDensity(displayDensity());
    println("displayDensity : " + displayDensity());
    background(255);

    // sample = new SoundFile(this, "the-whole-truth-90-seconds.wav");
    sample = new SoundFile(this, "the-whole-truth.wav");
    while (second() % 5 !=0) {
        // wait so that all three apps start audio at same time 
    }
    sample.play();
    sample.amp(0.0);     // force fake sync for now

    terms = new String[7];
    terms[0] = "Inaccuracy";
    terms[1] = "LIE";
    terms[2] = "Voice Manipulation / Avoidance / Emphasizing";
    terms[3] = "High Excitement";
    terms[4] = "Uncertainty";
    terms[5] = "Outsmart";
    terms[6] = "TRUE";
    printArray(terms);

    mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);

    counter = 0;
    pointer = 0;
    timer = 60;
}

public void draw() {
    background(0);
    if (counter % timer == 0) {
        pointer = random_walk(pointer);
    }
    draw_terms(pointer);
    show_current_pointer();
    counter++;
}

public void draw_terms(int currentterm) {
    int margin_left = 50;
    int margin_bottom = 20;
    int margin_top = 20;

    for (int i = 0; i < terms.length; i++){
        if (i == currentterm) {
            fill(255);
        } else {
            fill(255, 50);
        }
        text(terms[i], margin_left, (height-margin_top-margin_bottom)/terms.length * (i+1));
    }
}

private int random_walk(int pointer_old) {
    int increment = int(random(-2,2));
    int pointer_new = (pointer_old + increment) % terms.length;
    if (pointer_new < 0) 
        pointer_new = 0;
    println(pointer_new);
    return pointer_new;
}

private void show_current_pointer() {
    String point = nf(pointer, 4);
    fill(255);
    text(pointer,width-100,24);
}

