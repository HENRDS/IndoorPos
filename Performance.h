//
// Created by henry on 16/06/16.
//

#ifndef INDOORPOS_PERFORMANCE_H
#define INDOORPOS_PERFORMANCE_H
#include <stdlib.h>
#include <ctime>
#include "opencv2/opencv.hpp"
#include "Settings.h"
using namespace cv;
using namespace std;
class Block_Processor {
private:
    static void process(Mat* roi);
public:
    static void BinaryBlocks(Mat& frame);
};

void morph(const _InputOutputArray &frame, int op, int iters);
#endif //INDOORPOS_PERFORMANCE_H
