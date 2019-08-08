/*
    render

    process an audio file, performing analysis (fft or amplitude)
    then write out to a plain txt file '|' separate values 
    also includes a function to read txt file line by line

    based on VideoExport library example withAudioViz
    https://funprogramming.org/VideoExport-for-Processing/
    uses minim sound library for playback and analysis
    uses Speech-to-text-normal

    O-R-G
    for Lawrence Abu Hamdan, The Whole Truth

    --

    producing a file with audio and video in sync
    is tricky. it gets easily out of sync. one approach, 
    used here is:
   
    pass 1. analyze the sound in a Processing sketch 
            and output a text file including the FFT 
            analysis data.
    pass 2. load the data from pass 1 and use it to 
            output frames for a video file, including 
            the right frames to match the sound 
            precisely at any given time.

    using this technique it does not matter how fast
    or slow your second program is, and you know that
    no frames will be dropped (as may happen when
    recording live).
   
    the difficulty of recording live graphics with
    sound is that the frame rate is not always stable.
    We may request 60 frames per second, but once in
    a while a frame is not ready on time. So the
    "speed of frames" (the frameRate) is not constant
    while frames are produced, but they are probably
    constant when played back. the "speed of audio",
    on the other hand, is often constant. If audio
    is constant but video is not, they get out of 
    sync.
*/

String SEP = "|";
float movieFPS = 30;                    // ** redundant **
float frameDuration = 1 / movieFPS;     // ** to fix **

int render_audio_fft_to_txt(String file_name, int buffer_size) {

    // minim based audio FFT to data text file conversion.
    // non real-time, so you don't wait 5 minutes for a 5 minute song
    // you can look at the produced txt file in the data folder
    // after running this program to see how it looks like.
    // file contains many rows, each row looks like this:
    // T|B|B|B|B|B|B|... etc
    // where T is the time in seconds
    // and B is amplitude of that frequency band
    // first values in each row are low frequencies (bass)
    // and they go towards high frequency as we advance towards
    // the end of the line.

    println("FFT started (please wait) ...");

    PrintWriter output;
    Minim minim = new Minim(this);

    output = createWriter(dataPath(file_name + ".txt"));
    AudioSample sample = minim.loadSample(file_name, buffer_size); 
    int fft_size = buffer_size;
    float sample_rate = sample.sampleRate();
    float[] fft_samples = new float[fft_size];
    float[] samples = sample.getChannel(AudioSample.LEFT);
    FFT fft = new FFT(fft_size, sample_rate);
    fft.window(FFT.HAMMING);    // tapered time window avoids 'splatter'
    int total_chunks = (samples.length / fft_size) + 1;
    int bands = fft.specSize();      

    // manually sift through samples, one buffer at a time
    for (int j = 0; j < total_chunks; j++) {
        int chunk_start_index = j * fft_size;   
        int chunk_size = min(samples.length - chunk_start_index, fft_size );
        System.arraycopy(samples, chunk_start_index, fft_samples, 0, chunk_size);      
        if (chunk_size < fft_size)
            java.util.Arrays.fill(fft_samples, chunk_size, fft_samples.length - 1, 0.0);
        fft.forward(fft_samples);
        StringBuilder msg = new StringBuilder(nf(chunk_start_index/sample_rate, 0, 3).replace(',', '.'));
        for (int i = 0; i < bands; i++)
            msg.append(SEP + nf(fft.getBand(i), 0, 4).replace(',', '.'));
        output.println(msg.toString());
    }
    sample.close();
    minim.stop();
    output.flush();
    output.close();
    println(bands + " bands");
    println("FFT done.");
    return bands;   
}

int render_audio_amplitude_to_txt(String file_name, int buffer_size, Boolean rms) {

    // minim based audio amplitude to data text file conversion.
    // non real-time, so you don't wait 5 minutes for a 5 minute song 
    // you can look at the produced txt file in the data folder
    // after running this program to see how it looks like.
    // file contains many rows, each row looks like this:
    // T|A|
    // where T is the time in seconds
    // and A is amplitude 

    println("Amplitude started (please wait) ...");

    PrintWriter output;
    Minim minim = new Minim(this);

    output = createWriter(dataPath(file_name + ".txt"));
    AudioSample sample = minim.loadSample(file_name, buffer_size); 
    float sample_rate = sample.sampleRate();
    float[] samples = sample.getChannel(AudioSample.LEFT);
    float[] amplitude_samples = new float[buffer_size];
    int total_chunks = (samples.length / buffer_size) + 1;
    println("sample.bufferSize : " + sample.bufferSize());
    println("samples.length : " + samples.length);
    println("total_chunks : " + total_chunks);

    // manually sift through samples, one buffer at a time

    // 1. iterate through buffers
    for (int j = 0; j < total_chunks; j++) {
        int chunk_start_index = j * buffer_size;   
        int chunk_size = min(samples.length - chunk_start_index, buffer_size);
        System.arraycopy(samples, chunk_start_index, amplitude_samples, 0, chunk_size);      
        if (chunk_size < buffer_size)
            java.util.Arrays.fill(amplitude_samples, chunk_size, amplitude_samples.length - 1, 0.0);
        StringBuilder msg = new StringBuilder(nf(chunk_start_index/sample_rate, 0, 3).replace(',', '.'));
        float mean_square = 0.0;

        // 2. iterate through samples in buffer 
        if (rms) {
            // one option is producing one value, rms (per sample) 
            for (int i = 0; i < buffer_size; i++) {    
                // need to calculate root mean square over all of these and then write one value
                // https://en.wikipedia.org/wiki/Root_mean_square
                // each time square current value and add to total
                // then take square root of all 1024 (buffer_size) sample values
                // to get a level() for one buffer            
                mean_square += sq(amplitude_samples[i]);
            }
            mean_square /= buffer_size;
            float root_mean_square = sqrt(mean_square);
            msg.append(SEP + nf(root_mean_square, 0, 4).replace(',', '.'));
            output.println(msg.toString());
        } else {
            // write all sample values (buffer_size)
            for (int i = 0; i < buffer_size; i++)
                msg.append(SEP + nf(amplitude_samples[i], 0, 4).replace(',', '.'));
            output.println(msg.toString());
        }
    }
    sample.close();
    minim.stop();
    output.flush();
    output.close();
    println(total_chunks + " samples");
    println("Amplitude done.");
    return total_chunks;   // ie, number of samples
}

String[] read_audio_from_txt(int columns, Boolean video) {

    // read from the txt file, line by line
    // requires existing BufferedReader reader
    // data[0] is always time in seconds (float)            

    String line;
    String[] data = new String[columns];
    try {
        line = reader.readLine();
    }
    catch (IOException e) {
        e.printStackTrace();
        line = null;
    }
    if (line == null) {
        // done reading the file.
        // close the video file.
        if (video) 
            videoExport.endMovie();
        exit();
    } else
        data = split(line, SEP);

    return data;
}
