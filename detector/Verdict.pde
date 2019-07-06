/*
    verdict as string from time stamp
    based on Word class from kings
      
    O-R-G 
    for Lawrence Abu Hamdan, The Whole Truth
*/

class Verdict {

    String txt;
    int length;
    int in, out;  
    float width;
    Boolean spoken;

/*
    StringDict colors = new StringDict();
    colors.set("TRUTH", "240,240,240");            
    colors.set("SUBJECT EMPHATIC", "255,0,0");
    colors.set("SUBJECT MANIPULATING VOICE", "255,100,20");
    colors.set("AVOIDANCE", "0,180,200");
    colors.set("ATTEMPTING OUTSMART", "150,50,200");
    colors.set("SUBJECT IS NOT SURE", "50,150,0");
    colors.set("INACCURACY", "230,80,100");
    colors.set("LIE", "0,0,0");
    String color;
*/

    Verdict(int in_, int out_, String txt_) {
        in = in_;
        out = out_;
        txt = txt_;
        width = textWidth(this.txt);
        length = txt.length();
        spoken = false;
    }

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

    // String color(StringDict colors) {
    // String color(String txt) {
    /*
    String color() {
        String rgb_str = colors.get(txt);
        int[] rgb = split(rgb_str,",");
        return rgb;
    }
    */

    void display(int _x, int _y) {
        // int rgb = this.color();
        // fill(rgb[0],rgb[1],rgb[2]);
        // fill(100,100,100);
        // rect(0,0,height,width);
        fill(0);
        text(txt,_x,_y);
    }
}
