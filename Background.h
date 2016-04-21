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
 public:
  // Frames used for background estimation
  Mat older_frame; //frame at instant t-2
  Mat old_frame; //frame at instant t-1
  Mat frame; //frame at instant t

  Background(Mat& frame);

  Mat *calculateMask();
  void updateBackground(Mat& frame);
};

#endif //INDOORPOS_BACKGROUND_H
