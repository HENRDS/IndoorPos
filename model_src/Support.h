//
// Created by rodrigo on 4/21/16.
//

#ifndef INDOORPOS_SUPPORT_H
#define INDOORPOS_SUPPORT_H

#include "opencv2/opencv.hpp"
#include "Filters.h"
using namespace cv;

class Support {
public:
    /**
     *
     */
    static double Mean(Mat* input);
    /**
     *
     */
    static double StandardDeviation(Mat* frame, double mean);
    /**
     *
     */
    static double Variance(Mat* input, double mean);
};


#endif //INDOORPOS_SUPPORT_H
