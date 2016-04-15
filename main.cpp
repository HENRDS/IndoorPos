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

inline uchar avg (Vec3b & vec) {
    return (vec.col(0) + vec.col(1) + vec.col(2)) / 3;
}

Mat * grayscale (Mat &frame) {
    int tp = frame.type();
    Mat * result = new Mat(frame.size(), CV_8UC1);
    for (int i=0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result.at<uchar>(i, j) = avg(frame.at<Vec3b>(i, j));
        }
    }
}

void process (Mat * frame) {
    
}
/*
 * 
 */
int main(int argc, char** argv) {
    VideoCapture cap("vv.mpeg");
    
    if (!cap.isOpened())
        return -1;
    
    Mat frame;
    cap >> frame;
    
    return 0;
}


