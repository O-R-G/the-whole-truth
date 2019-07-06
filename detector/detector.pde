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

// should be passed to Verdict
// add sound control and timing control from kings
// for now using raw millis()
int current_time = 0;               // position in soundfile (millisec)

// dev
int counter;
int pointer;

public void setup() {
    size(640, 360);
    pixelDensity(displayDensity());
    println("displayDensity : " + displayDensity());
    background(255);

    load_csv();

    sample = new SoundFile(this, "the-whole-truth.wav");
    // add sound control and timing control from kings
    while (second() % 5 !=0) {
        // wait so that all three apps start audio at same time 
    }    
    sample.play();
    // sample.amp(0.0);     // force fake sync for now

    mono = createFont("fonts/Speech-to-text-normal.ttf", 48);
    textFont(mono);

    // dev
    counter = 0;
    pointer = 0;
}

public void draw() {
    background(192);

/*
    current_time=millis();      // this is lazy, see kings.pde

    if (verdicts[pointer].spoken()) {
        verdicts[pointer].display(int(width/8),int(height/2));
    }
*/

    verdicts[pointer].display(int(width/8),int(height/2));
    if (counter % 30 == 0) {
        if (pointer < 134) {
            pointer++;
        } else {
            pointer--;
        }
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
}


