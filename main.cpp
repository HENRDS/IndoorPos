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
#include <iostream>

using namespace cv;

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
inline uchar avg (Vec3b & vec) {
    return (vec(0) + vec(1) + vec(2)) / 3;
}

Mat* GrayscaleFilter (Mat &frame) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = avg(frame.at<Vec3b>(i, j));
        }
    }
    return result;
}

Mat* DifferenceFilter(Mat &reference_frame, Mat &frame) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j=0; j < frame.size().width; j++) {
            result->at<uchar>(i,j) = frame.at<uchar>(i,j) - reference_frame.at<uchar>(i,j);
        }
    }
    return result;
}

Mat* ThresholdFilter(Mat &frame, uchar threshold) {
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j=0; j < frame.size().width; j++) {
            result->at<uchar>(i,j) = frame.at<uchar>(i,j) > threshold ? frame.at<uchar>(i,j) : (uchar)0;
        }
    }
    return result;
}



// Blur
void gaussian_blur(Mat * frame) {
    
}

void box_blur() { }

void process (Mat &frame) {
    Mat * gray = GrayscaleFilter(frame);
    
}
/*
 * 
 */
int main(int argc, char** argv) {
    VideoCapture cap("vv.mpeg");
    
    if (!cap.isOpened())
        return -1;
    
    Mat frame;
    for (int i = 0; i < 10; i++) {
        cap >> frame;
    }

    
    imwrite( "Image.jpg", frame);
    Mat * im = GrayscaleFilter(frame);
    
    imwrite( "Gray_Image.jpg", *im);
    
    return 0;
}


