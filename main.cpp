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

Mat * grayscale (Mat &frame) {
    
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


