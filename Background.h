//
// Created by rodrigo on 4/19/16.
//

#ifndef INDOORPOS_BACKGROUND_H
#define INDOORPOS_BACKGROUND_H

#include "opencv2/opencv.hpp"
#include "Filters.h"
#include "Support.h"

using namespace cv;

class Background {
private:
    // Frames used for background estimation (t, t-1, t-2)
    Mat last_frames[3];
    // Create a mask showing the moving pixels in the frame t based on comparison with frames (t-1) and (t-2)
    Mat* calculateMask();
public:
    // Constructor
    Background(Mat& frame);
    // Update background estimation
    void updateBackground(Mat& frame);
    // Current estimated background
    Mat background_frame;
};

#endif //INDOORPOS_BACKGROUND_H
