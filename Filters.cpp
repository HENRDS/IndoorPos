//
// Created by rodrigo on 4/19/16.
//

#include "Filters.h"

inline uchar Filters::Grayscale(Vec3b &pixel) {
  return (uchar) ((pixel(0) + pixel(1) + pixel(2)) / 3);
}

Mat *Filters::Grayscale(Mat &frame) {
  Mat *result = new Mat(frame.size(), CV_8UC1);
  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      result->at<uchar>(i, j) = Filters::Grayscale(frame.at<Vec3b>(i, j));
    }
  }
  return result;
}

inline uchar Filters::Luminance(Vec3b &pixel) {
  return (uchar) (0.2989 * pixel(2) + 0.5870 * pixel(1) + 0.1140 * pixel(0));
}

Mat *Filters::Luminance(Mat &frame) {
  Mat *result = new Mat(frame.size(), CV_8UC1);
  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      result->at<uchar>(i, j) = Filters::Luminance(frame.at<Vec3b>(i, j));
    }
  }
  return result;
}

inline uchar Filters::Difference(uchar referencePixel, uchar pixel) {
  return (referencePixel > pixel) ? referencePixel - pixel : pixel - referencePixel;
}

Mat *Filters::Difference(Mat &reference_frame, Mat &frame) {
  Mat *result = new Mat(frame.size(), CV_8UC1);
  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      result->at<uchar>(i, j) = Filters::Difference(reference_frame.at<uchar>(i, j), frame.at<uchar>(i, j));
    }
  }
  return result;
}

inline uchar Filters::Threshold(uchar pixel, uchar threshold) {
  return (pixel > threshold) ? (uchar) 255 : (uchar) 0;
}

Mat *Filters::Threshold(Mat &frame, uchar threshold) {
  Mat *result = new Mat(frame.size(), CV_8UC1);
  for (int i = 0; i < frame.size().height; i++) {
    for (int j = 0; j < frame.size().width; j++) {
      result->at<uchar>(i, j) = Filters::Threshold(frame.at<uchar>(i, j), threshold);
    }
  }
  return result;
}

const double MOVING_AVERAGE_FILTER_ALPHA = 0.2;
uchar Filters::MovingAverage(uchar previousAverage, uchar currentPixel) {
  return MOVING_AVERAGE_FILTER_ALPHA * currentPixel + (1 - MOVING_AVERAGE_FILTER_ALPHA) * previousAverage;
}

//inline uchar avg (uchar * vec) {
//    return (*vec + *(vec+1) + *(vec+2)) / 3;
//}
//
//Mat * grayscale (Mat &frame) {
//    Mat * result = new Mat(frame.size(), CV_8UC1);
//    std::cout << frame.rows << "x" << frame.cols << std::endl;
//    for (int i=0; i < frame.rows; i++) {
//        uchar * res= result->ptr(i);
//        uchar * frptr = frame.ptr(i);
//        for (int j = 0; j < frame.cols; j++) {
//            if ((i  >  1920) || (j > 1080))
//                std::cout << "EOI" << std::endl;
//            *res = avg(frptr+(3*i));
//            std::cout << *res << std::endl;
//        }
//    }
//    return result;
//}

/**
 *
 */
void GaussianBlurFilter(Mat *frame) { }

/**
 *
 */
void BoxBlurFilter() { }