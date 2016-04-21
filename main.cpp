/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/* 
 * File:   main.cpp
 * Author: henry
 *
 * Created on April 13, 2016, 2:42 PM
 */

#include "opencv2/opencv.hpp"
#include "Filters.h"
#include "Background.h"
using namespace cv;

/**
 *
 */
void process(Mat &frame, uchar threshold, Background* background) {

  //Obtain the luma version of the current frame
  Mat luma_frame = *Filters::Luminance(frame);
  //Update the background based on information from the current frame
  background->updateBackground(luma_frame);

  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      uchar luma_pixel = luma_frame.at<uchar>(i, j);
      uchar background_pixel = background->background_frame.at<uchar>(i, j);
      //Obtain the difference of the current frame and the background.
      uchar pixel_difference = Filters::Difference(background_pixel, luma_pixel);
      uchar pixel_threshold = Filters::Threshold(pixel_difference, threshold);
      //Set the original RGB representation of the frame to grayscale by copying the grayscale value to each
      //component.
      frame.at<Vec3b>(i, j)(0) = pixel_threshold == (uchar) 255 ? (uchar)0 : luma_pixel;
      frame.at<Vec3b>(i, j)(1) = pixel_threshold == (uchar) 255 ? (uchar)0 : luma_pixel;
      frame.at<Vec3b>(i, j)(2) = pixel_threshold == (uchar) 255 ? (uchar)255 : luma_pixel;
    }
  }
}

/**
 * 
 */
int main(int argc, char **argv) {
  //Load the video file from disk
  VideoCapture inputVideo("input.mp4");
  if (!inputVideo.isOpened())
    return -1;

  //Set the threshold used by the threshold filter based on the input arguments
  int threshold = 75;
  if (argc == 2)
    threshold = atoi(argv[1]);

  //Set the first frame as the background frame and convert it to grayscale
  Mat background_frame;
  inputVideo >> background_frame;
  background_frame = *Filters::Luminance(background_frame);
  Background *background = new Background(background_frame);

  VideoWriter outputVideo("grayscaleVid.avi", VideoWriter::fourcc('M', 'P', 'E', 'G'), 30,
                          Size(background_frame.size().width, background_frame.size().height), 1);

  int frame_count = inputVideo.get(CV_CAP_PROP_FRAME_COUNT);
  Mat current_frame;
  for (int i = 0; i < frame_count - 1; i++) {
    inputVideo >> current_frame;
    process(current_frame, threshold, background);
    outputVideo << current_frame;
  }

  return 0;
}


