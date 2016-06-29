//
// Created by rodrigo on 4/21/16.
//

#include "Support.h"

double Support::Mean(Mat* input) {
    double mean = 0;
    for (int i = 0; i < input->size().height; i++) {
        for (int j = 0; j < input->size().width; j++) {
            mean += input->at<uchar>(i, j);
        }
    }
    if (mean != 0)
        mean /= input->size().height * input->size().width;
    return mean;
}

double Support::StandardDeviation(Mat *input, double mean) {
    return sqrt(Variance(input,mean));
}

double Support::Variance(Mat* input, double mean) {
    double variance = 0;
    for (int i = 0; i < input->size().height; i++) {
        for (int j = 0; j < input->size().width; j++) {
            variance += pow(input->at<uchar>(i, j) - mean,2);
        }
    }
    if (variance != 0)
        variance /= input->size().height * input->size().width;
    return variance;
}