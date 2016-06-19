//
// Created by henry on 16/06/16.
//

#ifndef INDOORPOS_PERFORMANCE_H
#define INDOORPOS_PERFORMANCE_H
#include "Settings.h"
#include "opencv2/opencv.hpp"
using namespace cv;
class FastAsFuck {
public:
    static inline uint countChanged(Mat* input);
    static void BinaryBlocks(Mat& frame);

};
class ParallelMatBlock : public ParallelLoopBody
{
private:
    Mat* mat;
public:
    ParallelMatBlock(Mat* mat, uchar color): mat(mat) { }

    void operator ()(const Range& range) const;
};
#endif //INDOORPOS_PERFORMANCE_H
