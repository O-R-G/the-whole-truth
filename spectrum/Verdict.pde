/*
    verdict as string from time stamp
    based on Word class from kings
      
    O-R-G 
    for Lawrence Abu Hamdan, The Whole Truth
*/

class Verdict {

    int in, out;
    String txt;
    color c;
    int txt_length;
    float txt_width;
    StringDict colors;

    Verdict(int in_, int out_, String txt_, color c_) {
        in = in_;
        out = out_;
        txt = txt_;
        c = c_;
        txt_width = textWidth(this.txt);
        txt_length = txt.length();
        // spoken = false;
    }

    // needed? working?
    
    Boolean speaking() {
        float now = (float)current_time/1000;
        if ((in <= now) && (out >= now))
            return true;
        else
            return false;
    }

    Boolean spoken() {
        float now = (float)current_time/1000;
        if ((in <= now))
            return true;
        else
            return false;
    }

    void display(int _x, int _y) {
        fill(c);
        rect(0,0,width,height);
        if (c == color(0,0,0)) 
            fill(255);
        else
            fill(0);
        // text(txt,_x,_y,width/2,height/2);
        text(txt,20,0,width-40,height-40);
    }
}
