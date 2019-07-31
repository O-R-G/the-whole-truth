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
*/

/*
   Example to visualize sound frequencies from
   an audio file.
    
   Producing a file with audio and video in sync
   is tricky. It gets easily out of sync.
    
   One approach, used in this example, is:
   
   Pass 1. Analyze the sound in a Processing sketch 
           and output a text file including the FFT 
           analysis data.
   Pass 2. Load the data from pass 1 and use it to 
           output frames for a video file, including 
           the right frames to match the sound 
           precisely at any given time.
            
   Using this technique it does not matter how fast
   or slow your second program is, and you know that
   no frames will be dropped (as may happen when
   recording live).
   
   The difficulty of recording live graphics with
   sound is that the frame rate is not always stable.
   We may request 60 frames per second, but once in
   a while a frame is not ready on time. So the
   "speed of frames" (the frameRate) is not constant
   while frames are produced, but they are probably
   constant when played back. The "speed of audio",
   on the other hand, is often constant. If audio
   is constant but video is not, they get out of 
   sync.
*/

String SEP = "|";
float movieFPS = 30;                    // ** redundant **
float frameDuration = 1 / movieFPS;     // ** to fix **

String[] read_audio_from_txt() {

    // read from the txt file, line by line
    // requires existing BufferedReader reader
    // data[0] is always time in seconds (float)            

    String line;
    String[] data = new String[33];         // (= 33) fftSlices
                                            // ** should be dynamic **

    try {
        line = reader.readLine();
    }
    catch (IOException e) {
        e.printStackTrace();
        line = null;
    }
    if (line == null) {
        // Done reading the file.
        // Close the video file.
        // videoExport.endMovie();
        exit();
    } else
        data = split(line, SEP);
    
    return data;
}


















void render_audio_to_txt(String fileName) {

    // Minim based audio FFT to data text file conversion.
    // Non real-time, so you don't wait 5 minutes for a 5 minute song :)
    // You can look at the produced txt file in the data folder
    // after running this program to see how it looks like.

    PrintWriter output;

    Minim minim = new Minim(this);
    output = createWriter(dataPath(fileName + ".txt"));

    AudioSample track = minim.loadSample(fileName, 1024); // 1024 = buffersize

    int fftSize = 1024;
    float sampleRate = track.sampleRate();

    float[] fftSamplesL = new float[fftSize];
    float[] fftSamplesR = new float[fftSize];

    float[] samplesL = track.getChannel(AudioSample.LEFT);
    float[] samplesR = track.getChannel(AudioSample.RIGHT);  

    FFT fftL = new FFT(fftSize, sampleRate);
    FFT fftR = new FFT(fftSize, sampleRate);

    fftL.logAverages(22, 3);
    fftR.logAverages(22, 3);

    int totalChunks = (samplesL.length / fftSize) + 1;
    int fftSlices = fftL.avgSize();

    println("Number of bands : " + fftSlices);

    for (int ci = 0; ci < totalChunks; ++ci) {
        int chunkStartIndex = ci * fftSize;   
        int chunkSize = min( samplesL.length - chunkStartIndex, fftSize );

        System.arraycopy( samplesL, chunkStartIndex, fftSamplesL, 0, chunkSize);      
        System.arraycopy( samplesR, chunkStartIndex, fftSamplesR, 0, chunkSize);      
        if ( chunkSize < fftSize ) {
            java.util.Arrays.fill( fftSamplesL, chunkSize, fftSamplesL.length - 1, 0.0 );
            java.util.Arrays.fill( fftSamplesR, chunkSize, fftSamplesR.length - 1, 0.0 );
        }

        fftL.forward( fftSamplesL );
        fftR.forward( fftSamplesL );

        // The format of the saved txt file.
    // The file contains many rows. Each row looks like this:
    // T|L|R|L|R|L|R|... etc
    // where T is the time in seconds
    // Then we alternate left and right channel FFT values
    // The first L and R values in each row are low frequencies (bass)
    // and they go towards high frequency as we advance towards
    // the end of the line.
    StringBuilder msg = new StringBuilder(nf(chunkStartIndex/sampleRate, 0, 3).replace(',', '.'));
    for (int i=0; i<fftSlices; ++i) {
      msg.append(SEP + nf(fftL.getAvg(i), 0, 4).replace(',', '.'));
      // msg.append(SEP + nf(fftR.getAvg(i), 0, 4).replace(',', '.'));
    }
    output.println(msg.toString());
  }
  track.close();
  output.flush();
  output.close();
  println("Sound analysis done");
}








/*
// simple version, DOES NOT WORK
// as cannot find the correct time stamp! 
// how to determine from sample
void render_audio_to_txt(String file_name) {

    // uses already existing mimim fft object
    // perhaps pass it a minim AudioSample object
    // adjust to only write the .mix value not .left and .right
    // use existing sample to do fft so exact same expected values
    // Minim based audio FFT to data text file conversion.
    // Non real-time, so you don't wait 5 minutes for a 5 minute song :)
    // You can look at the produced txt file in the data folder
    // after running this program to see how it looks like.

    PrintWriter output;

    output = createWriter(dataPath(file_name + ".txt"));

    // using AudioPlayer sample and existing fft object
    // and globals from spectrogram.pde including columns and rows

    // now have columns, but to know how many samples overall

    for (int i = 0; i < columns; i++) {

        // this is writing the time value in first data column on line
        // actually specSize() i think or else sample size
        StringBuilder msg = new StringBuilder(nf(chunkStartIndex/sampleRate, 0, 3).replace(',', '.'));
        for (int j = 0; j < rows; j++) {

            // sgram[i][column] = (int)Math.round(Math.max(0,2*20*Math.log10(1000*fft.getBand(i))));

            msg.append(SEP + nf(fftL.getAvg(i), 0, 4).replace(',', '.'));
        }
        output.println(msg.toString());
        fft.forward(sample.mix);
  }
  track.close();
  output.flush();
  output.close();
  println("Sound analysis done");
}
*/






    /*
    // xtra draw() for render_one_frame()?
    // or maybe integrates into draw()

    // Our movie will have 30 frames per second.
    // Our FFT analysis probably produces 
    // 43 rows per second (44100 / fftSize) or 
    // 46.875 rows per second (48000 / fftSize).
    // We have two different data rates: 30fps vs 43rps.
    // How to deal with that? We render frames as
    // long as the movie time is less than the latest
    // data (sound) time. 
    // I added an offset of half frame duration, 
    // but I'm not sure if it's useful nor what 
    // would be the ideal value. Please experiment :)
    while (videoExport.getCurrentTime() < soundTime + frameDuration * 0.5) {
      background(0);
      noStroke();
      // Iterate over all our data points (different
      // audio frequencies. First bass, then hihats)
      for (int i=1; i<p.length; i++) {
        float value = float(p[i]);
        // do something with value (set positions,
        // sizes, colors, angles, etc)
        pushMatrix();
        translate(width/2, height/2);
        if(i%2 == 1) {
          // Left channel value
          fill(255, 50, 20);
          rotate(i * 0.05);
          translate(50, 0);
          rect(value * 5, -5, value * 4, 10);
        } else {
          // Right channel value
          fill(20, 100, 250);
          rotate(-i * 0.05);
          translate(50, 0);
          rect(value * 5, -5, value * 4, 10);
        }
        popMatrix();
      }
      videoExport.saveFrame();
    }
    */

