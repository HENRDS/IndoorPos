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

Mat * GrayscaleFilter (Mat &frame) {
    unsigned char *input = (unsigned char*)(frame.data);
    Mat * result = new Mat(frame.size(), CV_8UC1);
    unsigned char *out = (unsigned char*)(result->data);
    for(int j = 0;j < frame.rows;j++){
        for(int i = 0;i < frame.cols;i++){
            out[result->step * j+i] = (input[frame.step * j + i ]  + input[frame.step * j + i + 1] + input[frame.step * j + i + 2])/ 3;
            
        }
    }
//    
//    for (int i=0; i < frame.size().height; i++) {
//        for (int j = 0; j < frame.size().width; j++) {
//            result->at<uchar>(i, j) = avg(frame.at<Vec3b>(i, j));
//        }
//    }
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
    int cnt = cap.get(CV_CAP_PROP_FRAME_COUNT);
    String nm = "grayscaleVid.avi";
    VideoWriter fil (nm, VideoWriter::fourcc('M','P','E','G'), 30, Size(1080, 1920), 0);
    
    for (int i = 0; i < cnt; i++) {
        cap >> frame;
        Mat * im = GrayscaleFilter(frame);
        fil << *im;
    }

    
//    imwrite( "Image.jpg", frame);
//    Mat * im = grayscale(frame);
//    
//    imwrite( "Gray_Image.jpg", *im);
    
    return 0;
}


