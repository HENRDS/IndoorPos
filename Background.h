//
// Created by rodrigo on 4/19/16.
//

#ifndef INDOORPOS_BACKGROUND_H
#define INDOORPOS_BACKGROUND_H

#include "opencv2/opencv.hpp"
#include "Performance.h"

class Background {
private:

    Mat* last_frames[BACKGROUND_BUFFER_SIZE];


    double processTminus(int minus, OutputArray output);
    void calculateMask(OutputArray mask);
    inline void push_frame_back(const Mat &frame);


public:
    // Constructor
    Mat background_frame;
    Background(InputArray input);
    // Update background estimation
    void updateBackground(InputArray input, OutputArray background);
};

#endif //INDOORPOS_BACKGROUND_H
