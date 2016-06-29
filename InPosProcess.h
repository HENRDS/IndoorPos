//
// Created by henry on 21/06/16.
//

#ifndef INDOORPOS_INPOSPROCESS_H
#define INDOORPOS_INPOSPROCESS_H
#include "opencv2/opencv.hpp"
#include "Background.h"
class InPosProcess {
private:


    VideoCapture* video;
    Background* background;

    void process(OutputArray output);
    void _retrieve(OutputArray frame);
    int _detectBlobs(InputArray input, InputOutputArray output);
#ifdef VERBOSE_
    void _putTextOnOutput(InputOutputArray image, int people_cntif, int elapsed_secs);
#endif
    void _markEdges(InputOutputArray image);


public:
    InPosProcess(String &filename);
    bool getFrame(OutputArray image);
};


#endif //INDOORPOS_INPOSPROCESS_H
