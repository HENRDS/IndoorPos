//
// Created by rodrigo on 4/19/16.
//

#ifndef INDOORPOS_BACKGROUND_H
#define INDOORPOS_BACKGROUND_H

#include "opencv2/opencv.hpp"
#include "Performance.h"
class Background {
private:

    Mat* last_frames[3];
    double processTminus(int minus, OutputArray output);
    void calculateMask(InputOutputArray mask);
    inline void push_frame_back(const Mat &frame);


public:
    // Constructor
    Mat background_frame;
    Background(InputArray input);
    // Update background estimation
    void updateBackground(InputArray input, OutputArray background);
};

#endif //INDOORPOS_BACKGROUND_H
