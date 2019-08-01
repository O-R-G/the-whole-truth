/**
 * waveform
 *
 * analyzes a stream of raw sound to plot waveform
 * as continuous set of amplitude values {-1,1} over time.
 * time displayed can be adjusted.
 *
 * based on AudioWaveform example in processing.sound
 * uses processing.sound for Amplitude analysis
 * uses processing.sound for Waveform analysis
 * uses Speech-to-text-normal
 *
 * O-R-G
 * for Lawrence Abu Hamdan, The Whole Truth
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
FFT fft;
PFont mono;

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int display_scale = 2;      // adjust to match size()
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";
String file_name = "the-whole-truth-dev.wav";

float sample_rate = 48000;  // from the audio file
int buffer_size = 1024;     // must be a power of 2 [512,1024,2048]
                            // the larger the buffer, the more fft bands
                            // and the less accurate the time
                            // the smaller, the fewer bands (freq resolution)
                            // but the more accurate the time
int samples = 102;          // how much of waveform to display
int video_fps = 30;
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

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);

    if (render) {
        // frameRate(1000);
        // int samples_stub = render_audio_amplitude_to_txt(data_path + file_name, buffer_size);
        // reader = createReader(data_path + file_name + ".txt");
        videoExport = new VideoExport(this);
        videoExport.setFrameRate(video_fps);
        videoExport.setAudioFileName(data_path + file_name);
        videoExport.setMovieFileName("out/" + file_name + ".mp4");
        videoExport.startMovie();
        // temp ** fix **
        // playing = true;
    // } else {
    }
        frameRate(30);
        minim = new Minim(this);
        sample = minim.loadFile(data_path + file_name, buffer_size);
        if (sync)
            sync_sample();
        else
            play_sample();
    // }
}

public void draw() {
    background(0);
    stroke(0, 255, 0);
    strokeWeight(2);
    noFill();

    if (playing) {
        /*
        if (render) {
            // movie will have 30 frames per second.
            // FFT analysis probably produces
            // 43 rows per second (44100 / fftSize) or
            // 46.875 rows per second (48000 / fftSize).
            // we have two different data rates: 30fps vs 43rps.
            // how to deal with that? We render frames as
            // long as the movie time is less than the latest
            // data (sound) time.

            // solution is to make sure current_time comes from the
            // video export, and then checks against the fft time stamps
            // to move the fft forward, reference the correct one.
            // videoExport is the master, determines current_time
            // fft forward by reading next line from buffered reader
            // which holds the fft data. also reads from txt file
            // in update_spectrogram() but since in both places
            // String data[] is local then these are independent
            // pointers to current line in the file.

            if (current_time > fft_time) {
                String data[] = read_audio_from_txt(bands, video);
                fft_time = int(float(data[0]) * 1000);
            }
            current_time = int(videoExport.getCurrentTime()*1000);
            // println(current_time + " : " + fft_time);
            println(current_time);
            videoExport.saveFrame();
        } else {
            current_time = millis() - millis_start;
        }
        */

        current_time = millis() - millis_start;

        beginShape();
        for(int i = 0; i < samples; i++){
            vertex(
                map(i, 0, samples, 0, width),
                map(sample.left.get(i), -1, 1, 0, height)
            );
        }
        endShape();
        if (debug)
            show_current_time(width-100, 24);

        // ** fix ** temp before proper render is finished in render.pde
        // exit mechanism should be in the reading file
        if (current_time >= sample.length()) {
            videoExport.endMovie();
            exit();
        } else 
            videoExport.saveFrame();
    }
    counter++;
}


/*

    display time

*/

private void show_current_millis() {
    fill(255);
    text(millis(),width-100,24);
}

private void show_current_time(int x, int y) {
    fill(0);
    noStroke();
    rectMode(CORNERS);
    rect(x-24,y-24,width,30);       // rectMode(CORNERS)
    fill(255/3,255,255);
    text(get_time(current_time),x,y);
}

private void show_capture_time(int x, int y) {
    fill(0,0,255);
    text(get_time(current_time),x,y);
}

private String get_time(int current_time) {
    int milliseconds = current_time % 1000;
    int frames = round(map(milliseconds, 0, 1000, 0, 30));
    int seconds = (current_time / 1000) % 60;
    int minutes = (current_time / (1000 * 60)) % 60;
    return nf(minutes, 2) + ":" + nf(seconds, 2) + "." + nf(frames, 2);
}

private void timing_debug(int x, int y) {
    show_current_time(width-100, 24);
    saveFrame("out/debug-######.tif");
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

void exit() {
    stop();
}

void stop() {
    // always dispose minim object
    sample.pause();
    minim.stop();
    super.stop();
}
