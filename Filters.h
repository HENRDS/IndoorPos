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
     * Mat input type - CV_8UC3
     * Mat output type - CV_8UC1
     * Can be done in place!
     */
    static uchar Grayscale(Vec3b &pixel);
    static void Grayscale(Mat* output, Mat* input);
    /**
     * Obtain the luminace component from an RGB color space
     * Luminance = 0.2989*RED + 0.5870*GREEN + 0.1140*BLUE
     * Mat input type - CV_8UC3
     * Mat output type - CV_8UC1
     * Can be done in place!
     */
    static uchar Luminance(Vec3b &pixel);
    static void Luminance(Mat* output, Mat* input);
    /**
     * Obtain the absolute difference between two grayscale pixels.
     * Mat type - CV_8UC1
     * Can be done in place!
     */
    static uchar AbsoluteDifference(uchar referencePixel, uchar pixel);
    static void AbsoluteDifference(Mat* output, Mat* frame_a, Mat* frame_b);
    /**
     * Set a pixel to either black or white, depending whether it is below or above a threshold.
     * Mat type - CV_8UC1
     * Can be done in place!
     */
    static uchar Threshold(uchar pixel, uchar threshold);
    static void Threshold(Mat* output, Mat* input, uchar threshold);
    /**
     * Apply a weighted moving average filter.
     */
    static uchar MovingAverage(uchar previousAverage, uchar currentPixel);
    /**
     *
     */
    static Mat GaussianBlur(Mat &frame, int radius);
    /**
     * Mat type - CV_8UC1
     * Can be done in place!
     */
    static void BinaryBlocks(Mat* output, Mat* input, int block_size, int threshold);
    /**
     *
     */
    static void HighlightMask(Mat *output, Mat *mask, bool keep_back);
    static void HighlightBlobMask(Mat* output, Mat* blob_input, Mat* luma_input);
    /**
     *
     */
    static void Closing(Mat* output, Mat* input, int size, int iterations);
    static void Opening(Mat* output, Mat* input, int size, int iterations);
    /**
     *
     */
    static void RGB(Mat* output, Mat* input);
    /*
     *
     */
    static void BlobDetector(Mat* output, Mat* input);
};


#endif //INDOORPOS_FILTERS_H
