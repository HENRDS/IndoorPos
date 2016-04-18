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

Mat avgFrame, Orig;
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
    uchar x;
    for (int i=0; i < frame.size().height; i++) {
        for (int j=0; j < frame.size().width; j++) {
            x = frame.at<uchar>(i,j); // saves 1 call to Mat::at<uchar>()
            result->at<uchar>(i,j) = x > threshold ? x : (uchar)0;
        }
    }
    return result;
}

// Blur
void gaussian_blur(Mat * frame) {
    
}

void box_blur() { }

Mat process (Mat &frame, uchar threshold) {
//    Mat * result = new Mat(frame.size(), CV_8UC1);
    Mat result;
    Orig.copyTo(result);
    uchar x, avgPix, r;
    char a;
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            // Grayscale
            x = avg(frame.at<Vec3b>(i, j));
            // accumulateWeighted
            avgPix = x * 0.2 + avgFrame.at<uchar>(i, j) * 0.8;
            avgFrame.at<uchar>(i, j) = avgPix;
            // diff
            a = (char)x - (char)avgPix;
            x = (uchar) a > 0 ? a : -a;
            //Threshold
            result.at<Vec3b>(i, j)[2] = x > threshold ? 255 : 0;
        }
    }
    return result;
}
/*
 * 
 */
int main(int argc, char** argv) {
    VideoCapture cap("vv.mpeg");
    int thresh = 5;
    if (argc == 1 )
        thresh = atoi(argv[0]);
    if (!cap.isOpened())
        return -1;
    
    Mat frame, blured;
    cap >> avgFrame;
    avgFrame.copyTo(Orig);
    avgFrame = *GrayscaleFilter(avgFrame);
//    GaussianBlur(avgFrame, blured, Size(101,101), 50);
//    std::cout << cap.get(CV_CAP_PROP_FRAME_COUNT) << std::endl;
//    imwrite("xx.jpg", blured);
//    return 0;
 
    int cnt = cap.get(CV_CAP_PROP_FRAME_COUNT);
    String nm = "grayscaleVid.avi";
    Mat im;
    VideoWriter fil (nm, VideoWriter::fourcc('M','P','E','G'), 30, Size(1080, 1920), 1);
    for (int i = 0; i < cnt; i++) {
        cap >> frame;        
        im = process(frame, thresh);
        fil << im;
    }

    
    
    return 0;
}


