/*
    detector

    uses processing.sound for playback
    uses processing.sound for Amplitude
    uses Speech-to-text-normal

    load .csv to populate Verdict objects 
    marked in m, s, frames, verdict
    display verdicts at time with color

    O-R-G
    for Lawrence Abu Hamdan, The Whole Truth
*/

import processing.sound.*;

SoundFile sample;
PFont mono;
Table table;
Verdict[] verdicts;

int millis_start = 0;
int current_time = 0;               // position in soundfile (millis)
Boolean playing = false;

int pointer;    // current index in verdicts
int counter;    

public void setup() {
    size(640, 360);
    pixelDensity(displayDensity());
    println("displayDensity : " + displayDensity());
    background(255);

    load_csv();
    mono = createFont("fonts/Speech-to-text-normal.ttf", 48);
    textFont(mono);

    sample = new SoundFile(this, "the-whole-truth.wav");

    counter = 0;
    pointer = 0;
}

public void draw() {
    background(192);

    if (playing) {
        current_time = millis() - millis_start;
        if (playing && ((current_time) >= sample.duration() * 1000))
            stop_sample();
        if (current_time >= verdicts[pointer].in)
            verdicts[pointer].display(int(width/8),int(height/2));
        // lookahead
        // do this before or after display?
        // or could use verdict.spoken or verdict.speaking property
        if (current_time >= verdicts[(pointer + 1) % verdicts.length].in)
            pointer++;
        println(verdicts[pointer].in + " / " + current_time);
    }
    counter++;
}

void load_csv() {
    // load .csv to populate verdicts
    // table is a specific data struct with rows and columns
    // "header" indicates the file has header row. The size of the array 
    // is then determined by the number of rows in the table. 

    table = loadTable("verdicts.csv", "header");
    verdicts = new Verdict[table.getRowCount()];

    for (int i = 0; i < table.getRowCount(); i++) {
        TableRow row = table.getRow(i);    
        int m = row.getInt("m");
        int s = row.getInt("s");
        int frame = row.getInt("frame");
        int in = int((m * 60 + s + frame/30) * 1000);
        int out = in + 1000;
        // int in = 100;
        // int out = 100*10;
        String txt = row.getString("VERDICT");
        verdicts[i] = new Verdict(in,out,txt);

        println(verdicts[i].in + ":" + verdicts[i].out + " " + verdicts[i].txt);
    }
    println("** " + verdicts.length + " rows **");
}

/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.loop();      // so use .loop() instead
        sample.amp(0.0);     
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean stop_sample() {
    playing = false;
    // sample.stop();
    sample.pause();
    return true;
}

Boolean sync_sample() {
    while (second() % 5 !=0) {
        // wait
    }    
    play_sample();
    if (playing)
        return true;
    else 
        return false;
}

/*

    interaction

*/

void keyPressed() {
    switch(key) {
        case ' ':
            if (!playing)
                play_sample();
            else
                stop_sample();
            break;
        default:
            break;
    }
}

