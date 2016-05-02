//
// Created by rodrigo on 4/19/16.
//

#ifndef INDOORPOS_FILTERS_H
#define INDOORPOS_FILTERS_H

#include "opencv2/opencv.hpp"
using namespace cv;

class Filters {
public:
    /**
     * Convert a RGB pixel to grayscale by obtaining the average between its components.
     */
    static uchar grayscale(Vec3b &pixel);
    static Mat* Grayscale (Mat &frame);
    /**
     * Obtain the luminace component from an RGB color space
     * Luminance = 0.2989*RED + 0.5870*GREEN + 0.1140*BLUE
     */
    static uchar Luminance (Vec3b &pixel);
    static Mat* Luminance (Mat &frame);
    /**
     * Obtain the absolute difference between two grayscale pixels.
     */
    static uchar Difference (uchar referencePixel, uchar pixel);
    static Mat* Difference(Mat &reference_frame, Mat &frame);
    /**
     * Set a pixel to either black or white, depending whether it is below or above a threshold.
     */
    static uchar Threshold (uchar pixel, uchar threshold);
    static Mat* Threshold(Mat &frame, uchar threshold);
    /**
     * Apply a weighted moving average filter.
     */
    static uchar MovingAverage (uchar previousAverage, uchar currentPixel);
};


#endif //INDOORPOS_FILTERS_H
