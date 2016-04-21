//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"
#include <iostream>

Background::Background(Mat& frame) {
  updateBackground(frame);
}

Mat *Background::calculateMask() {
  //Generate a matrix of absolute differences between frame and old_frame
  Mat *abs_frame_oldframe = Filters::Difference(frame, old_frame);

  //Generate a matrix of absolute differences between frame and older_frame
  Mat *abs_frame_olderframe = Filters::Difference(frame, older_frame);

  //Get the mean value from the absolute differences between frame and old_frame
  double mean_frame_oldframe = Support::Mean(*abs_frame_oldframe);

  //Get the mean value from the absolute differences between frame and older_frame
  double mean_frame_olderframe = Support::Mean(*abs_frame_olderframe);

  //Get the standard deviation of absolute differences between frame and old_frame
  double std_deviation_frame_oldframe = Support::StandardDeviation(*abs_frame_oldframe, mean_frame_oldframe);

  //Get the standard deviation of absolute differences between frame and older_frame
  double std_deviation_frame_olderframe = Support::StandardDeviation(*abs_frame_olderframe, mean_frame_olderframe);

  Mat *mask = new Mat(frame.size(), CV_8UC1);

  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      if (abs_frame_oldframe->at<uchar>(i, j) >= mean_frame_oldframe + std_deviation_frame_oldframe)
        if (abs_frame_olderframe->at<uchar>(i,j) >= mean_frame_olderframe + std_deviation_frame_olderframe)
          mask->at<uchar>(i,j) = 255;
      else
          mask->at<uchar>(i,j) = 0;
    }
  }

  namedWindow("Display Image", WINDOW_AUTOSIZE );

  imshow("Display Image", *mask);

  waitKey(0);

  return NULL;
}

void Background::updateBackground(Mat& _frame) {
  if (older_frame.data == NULL)
    older_frame = _frame.clone();
  else
    older_frame = old_frame;

  if (old_frame.data == NULL)
    old_frame = _frame.clone();
  else
    old_frame = frame;

  frame = _frame.clone();
}