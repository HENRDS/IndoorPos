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
using namespace cv;

Mat backgroundFrame;
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

const double MOVING_AVERAGE_FILTER_ALPHA = 0.2;

/**
 * Convert a RGB pixel to grayscale by obtaining the average between its components.
 */
inline uchar GrayscaleFilter (Vec3b &pixel) {
    return (uchar)((pixel(0) + pixel(1) + pixel(2)) / 3);
}

Mat* GrayscaleFilter (Mat &frame) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = GrayscaleFilter(frame.at<Vec3b>(i, j));
        }
    }
    return result;
}

/**
 * Obtain the absolute difference between two grayscale pixels.
 */
inline uchar DifferenceFilter (uchar referencePixel, uchar pixel) {
    return (referencePixel > pixel) ? referencePixel - pixel : pixel - referencePixel;
}

Mat* DifferenceFilter(Mat &reference_frame, Mat &frame) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j=0; j < frame.size().width; j++) {
            result->at<uchar>(i,j) = DifferenceFilter(reference_frame.at<uchar>(i,j), frame.at<uchar>(i,j));
        }
    }
    return result;
}

/**
 * Set a pixel to either black or white, depending whether it is below or above a threshold.
 */
inline uchar ThresholdFilter (uchar pixel, uchar threshold) {
    return  (pixel > threshold) ? (uchar)255 : (uchar)0;
}

Mat* ThresholdFilter(Mat &frame, uchar threshold) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j=0; j < frame.size().width; j++) {
            result->at<uchar>(i,j) = ThresholdFilter(frame.at<uchar>(i,j), threshold);
        }
    }
    return result;
}

/**
 * Apply a weighted moving average filter.
 */
inline uchar MovingAverageFilter (uchar previousAverage, uchar currentPixel) {
    return MOVING_AVERAGE_FILTER_ALPHA*currentPixel + (1 - MOVING_AVERAGE_FILTER_ALPHA)*previousAverage;
}

/**
 *
 */
void GaussianBlurFilter(Mat * frame) {}

/**
 *
 */
void BoxBlurFilter() {}

/**
 *
 */
void process (Mat &frame, uchar threshold) {
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            Vec3b frame_pixel = frame.at<Vec3b>(i,j);
            uchar background_pixel = backgroundFrame.at<uchar>(i, j);
            //Obtain the grayscale version of the pixel in the current frame.
            uchar pixel_grayscale = GrayscaleFilter(frame_pixel);
            //Obtain the difference of the current frame and the background.
            uchar pixel_difference = DifferenceFilter(background_pixel, pixel_grayscale);
            uchar pixel_threshold = ThresholdFilter(pixel_difference, threshold);
            //Update the background with information from the current frame using a moving average filter.
            uchar updated_background_pixel = MovingAverageFilter(background_pixel, pixel_grayscale);
            backgroundFrame.at<uchar>(i, j) = updated_background_pixel;
            //Set the original RGB representation of the frame to grayscale by copying the grayscale value to each
            //component.
            frame.at<Vec3b>(i,j)(0) = pixel_grayscale;
            frame.at<Vec3b>(i,j)(1) = pixel_grayscale;
            frame.at<Vec3b>(i,j)(2) = pixel_grayscale;
            //Update the RED component to show the difference;
            frame.at<Vec3b>(i,j)(2) = pixel_threshold == (uchar)255 ? pixel_threshold : frame.at<Vec3b>(i,j)(2);
        }
    }
}

/**
 * 
 */
int main(int argc, char** argv) {
    //Load the video file from disk
    VideoCapture inputVideo("input.mp4");
    if (!inputVideo.isOpened())
        return -1;

    //Set the threshold used by the threshold filter based on the input arguments
    int threshold = 75;
    if (argc == 2 )
        threshold = atoi(argv[1]);

    //Set the first frame as the background frame and convert it to grayscale
    inputVideo >> backgroundFrame;
    backgroundFrame = *GrayscaleFilter(backgroundFrame);

//    Mat blured;
//    backgroundFrame.copyTo(Orig);
//    GaussianBlur(backgroundFrame, blured, Size(101,101), 50);
//    std::cout << cap.get(CV_CAP_PROP_FRAME_COUNT) << std::endl;
//    imwrite("xx.jpg", blured);
//    return 0;

    VideoWriter outputVideo ("grayscaleVid.avi", VideoWriter::fourcc('M','P','E','G'), 30,
                             Size(backgroundFrame.size().width,backgroundFrame.size().height), 1);

    int frame_count = inputVideo.get(CV_CAP_PROP_FRAME_COUNT);
    Mat current_frame;
    for (int i = 0; i < frame_count; i++) {
        inputVideo >> current_frame;
        process(current_frame, threshold);
        outputVideo << current_frame;
    }

    return 0;
}


