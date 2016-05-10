//
// Created by rodrigo on 4/21/16.
//

#include "Support.h"

double Support::Mean(Mat &frame) {
    double mean = 0;
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            mean += frame.at<uchar>(i, j);
        }
    }
    if (mean != 0)
        mean /= frame.size().height * frame.size().width;
    return mean;
}

double Support::StandardDeviation(Mat &frame, double mean) {
    return sqrt(Variance(frame,mean));
}

double Support::Variance(Mat &frame, double mean) {
    double variance = 0;
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            variance += pow(frame.at<uchar>(i, j) - mean,2);
        }
    }
    if (variance != 0)
        variance /= frame.size().height * frame.size().width;
    return variance;
}