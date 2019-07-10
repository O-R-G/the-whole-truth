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
StringDict colors;
Verdict[] verdicts;

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int display_scale = 2;      // adjust to match size() 
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";

public void setup() {
    // size(640, 360);
    size(1280, 720);
    // size(1920, 1080);
    pixelDensity(displayDensity());
    background(0);
    noStroke();

    set_colors();
    load_csv();
    counter = 0;
    pointer = 0;

    sample = new SoundFile(this, data_path + "the-whole-truth.wav");
    sync_sample();

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 48 * display_scale);
    textFont(mono);
    textAlign(CENTER, CENTER);

    println("displayDensity : " + displayDensity());
    println("** ready **");
}

public void draw() {
    background(0);

    if (playing) {
        current_time = millis() - millis_start;
        if (playing && ((current_time) >= sample.duration() * 1000))
            stop_sample();
        if (current_time >= verdicts[pointer].in)
            verdicts[pointer].display(int(width/2),int(height/2));
        if (current_time >= verdicts[(pointer + 1) % verdicts.length].in)
            pointer++;
        println(verdicts[pointer].in + " / " + current_time);
    }
    counter++;
}

/*

    objects from .csv data

*/

void load_csv() {
    table = loadTable(data_path + "verdicts.csv", "header");
    verdicts = new Verdict[table.getRowCount()];

    for (int i = 0; i < table.getRowCount(); i++) {
        TableRow row = table.getRow(i);    
        int m = row.getInt("m");
        int s = row.getInt("s");
        int frame = row.getInt("frame");
        float f = float(frame)/30;
        int in = round((m * 60 + s + f) * 1000);
        int out = in + 1000;
        String txt = row.getString("VERDICT");
        String c_str = colors.get(txt);
        int[] c_ = int(split(c_str,","));
        color c = color(c_[0], c_[1], c_[2]);
        if (c_str == null) {
            println(txt + ", " + c_str);
            c = color(192,192,192);
        }
        verdicts[i] = new Verdict(in,out,txt,c);

        println(verdicts[i].in + ":" + verdicts[i].out + " " + verdicts[i].txt);
    }
    println(verdicts.length + " rows");
}

Boolean set_colors() {
    // match .csv rows based on verdict txt
    colors = new StringDict();
    colors.set("TRUTH", "255,255,255");
    colors.set("SUBJECT EMPHATIC", "247,203,202");
    colors.set("SUBJECT MANIPULATING VOICE", "235,85,248");
    colors.set("AVOIDANCE", "140,140,140");
    colors.set("SUBJECT ATTEMPTING OUTSMART", "150,50,200");
    colors.set("SUBJECT IS NOT SURE", "255,253,205");
    colors.set("INACCURACY", "140,136,39");
    colors.set("LIE", "0,0,0");
    return true;
}

/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.loop();      
        sample.amp(1.0);
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean stop_sample() {
    playing = false;
    sample.stop();
    return true;
}

Boolean sync_sample() {
    while (second() % 10 !=0) {
        println(second() % 10);
    }
    play_sample();        
    sample.amp(0.0);
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

