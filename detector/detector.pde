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

import com.hamoid.*;
import ddf.minim.*;
import ddf.minim.spi.*;
import ddf.minim.analysis.*;

VideoExport videoExport;
BufferedReader reader;
Minim minim;
AudioInput in;
AudioPlayer sample;
PFont mono;
Table table;
StringDict colors;
Verdict[] verdicts;

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int display_scale = 1;      // adjust to match size() [1,2,3]
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";
String file_name = "the-whole-truth-dev.wav";
String sketch_name = "detector";

float sample_rate = 48000;  // from the audio file
int buffer_size = 1024;     // must be a power of 2 [512,1024,2048]
                            // the larger the buffer, the more fft bands
                            // and the less accurate the time
                            // the smaller, the fewer bands (freq resolution)
                            // but the more accurate the time
int freeze_time = 0;        // current_time when freeze started
int video_fps = 30;
int audio_duration;
Boolean debug = true;       // display time debug
Boolean mute = false;       // no sound
Boolean sync = false;       // start audio w/sync_sample()
Boolean render = true;      // render audio to txt, read txt, output video
Boolean video = true;       // export video when rendering

public void setup() {
    size(640, 360);
    pixelDensity(displayDensity());
    background(0);
    noStroke();
    counter = 0;
    pointer = 0;

    set_colors();
    load_csv();
    counter = 0;
    pointer = 0;

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 48 * display_scale);
    textFont(mono);
    textAlign(CENTER, CENTER);

    if (render) {
        frameRate(1000);
        minim = new Minim(this);
        sample = minim.loadFile(data_path + file_name, buffer_size);
        audio_duration = sample.length();
        sample.close();
        minim.stop();
        String[] file_name_split = split(file_name, '.');
        String video_file_name = "out/" + file_name_split[0] + "-" + sketch_name + ".mp4";
        videoExport = new VideoExport(this);
        videoExport.setFrameRate(video_fps);
        videoExport.setAudioFileName(data_path + file_name);
        videoExport.setMovieFileName(video_file_name);
        videoExport.startMovie();
        playing = true;
    } else {
        frameRate(30);
        minim = new Minim(this);
        sample = minim.loadFile(data_path + file_name, buffer_size);
        if (sync)
            sync_sample();
        else
            play_sample();
    }
}

public void draw() {

    if (playing) {
        if (render) {
            // for non-realtime render, use videoExport 
            // as the master clock (current_time)
            // and dont play audio, which is added after
            // only requires audio_duration to end
            // movie will have 30 frames per second

            current_time = int(videoExport.getCurrentTime()*1000);
            println(current_time);
            if (current_time >= audio_duration) {
                println("End of audio, stopping video export.");
                videoExport.endMovie();
                exit();
            }
        } else 
            current_time = millis() - millis_start;
        freeze_fade();
        if (debug)
            show_current_time(width-100, 24);
        if (pointer >= verdicts.length)
            exit();
        if (video)
            videoExport.saveFrame();
    }
    counter++;
}

public void freeze_fade() {
    // globals current_time, freeze_time
    int fade_duration = 0;          // duration in millis
    int freeze_duration = 1000;     // duration in millis

    // exceptions, hard-coded
    if (freeze_time == 1083667) 
        freeze_duration = 1087267 - 1083667;
    if (freeze_time == 1092000) 
        freeze_duration = 1098500 - 1092000;

    // freeze
    if (current_time >= verdicts[pointer].in) {
        background(0);      
        verdicts[pointer].display(int(width/2),int(height/2));
        if (debug) {
            show_capture_time(width-100, 44);
            // timing_debug(10, 44);
        }
        freeze_time = current_time;
        pointer++;
    }
    // fade
    if ((current_time >= freeze_time + freeze_duration) &&
        (current_time <= freeze_time + freeze_duration + fade_duration)) {
        noStroke();
        fill(0);                    // speed via alpha
        // fill(0,10);                    // speed via alpha
        rect(0,0,width,height);
    }
}

/*

    display time

*/

private void show_current_millis() {
    fill(255);
    textAlign(LEFT);
    text(millis(),width-100,24);
    textAlign(CENTER, CENTER);
}

private void show_current_time(int x, int y) {
    fill(0);
    noStroke();
    rect(x-24,y-24,width,30);
    fill(255,0,0);
    textFont(mono, 16);
    textAlign(LEFT);
    text(get_time(current_time),x,y);
    textFont(mono);
    textAlign(CENTER, CENTER);
}

private void show_capture_time(int x, int y) {
    fill(0,0,255);
    textFont(mono, 16);
    textAlign(LEFT);
    text(get_time(current_time),x,y);
    textFont(mono);
    textAlign(CENTER, CENTER);
}

private String get_time(int current_time) {
    int milliseconds = current_time % 1000;
    int frames = round(map(milliseconds, 0, 1000, 0, 30));
    int seconds = (current_time / 1000) % 60;
    int minutes = (current_time / (1000 * 60)) % 60;
    return nf(minutes, 2) + ":" + nf(seconds, 2) + "." + nf(frames, 2);
}

private void timing_debug(int x, int y) {
    textFont(mono, 16);
    textAlign(LEFT);
    text(verdicts[pointer].txt,x,y);
    show_current_time(width-100, 24);
    saveFrame("out/debug-######.tif");
    textFont(mono);
    textAlign(CENTER, CENTER);
}

/*

    objects from .csv data

*/

void load_csv() {
    table = loadTable(data_path + "verdicts-dev.csv", "header");
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
    colors.set("* END OF FILE *", "0,0,0");
    return true;
}


/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.play();
        if (mute)
            sample.mute();
        else
            sample.unmute();
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean pause_sample() {
    playing = false;
    sample.pause();
    return true;
}

Boolean sync_sample() {
    while (second() % 30 !=0) {
        println(second() % 30);
    }
    play_sample();
    if (playing)
        return true;
    else
        return false;
}

public void stop() {
    // always dispose minim object
    sample.close();
    minim.stop();
    super.stop();
}
