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
#include <iostream>
using namespace cv;

Mat backgroundFrame, blured;

/**
 *
 */
void process (Mat &frame, uchar threshold) {
    Vec3b *frame_pixel = 0;
    uchar *background_pixel = 0;
    uchar zero = 0;
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            frame_pixel = &frame.at<Vec3b>(i,j);
            background_pixel = &backgroundFrame.at<uchar>(i, j);
            //Obtain the grayscale version of the pixel in the current frame.
            uchar pixel_grayscale = Filters::Luminance(*frame_pixel);
            //Obtain the difference of the current frame and the background.
            uchar pixel_difference = Filters::Difference(*background_pixel, pixel_grayscale);
            uchar pixel_threshold = Filters::Threshold(pixel_difference, threshold);
            //Update the background with information from the current frame using a moving average filter.
            (*background_pixel) = Filters::MovingAverage(*background_pixel, pixel_grayscale);
            //Set the original RGB representation of the frame to grayscale by copying the grayscale value to each
            //component.
            if (pixel_threshold == (uchar)255 ) {
                (*frame_pixel)(0) = 255;
                (*frame_pixel)(1) = 255;
                (*frame_pixel)(2) = 255;
            } else {
                (*frame_pixel)(0) = 0;
                (*frame_pixel)(1) = 0;
                (*frame_pixel)(2) = 0;
            }
//            (*frame_pixel)(0) = pixel_grayscale;
//            (*frame_pixel)(1) = pixel_grayscale;
//            (*frame_pixel)(2) = pixel_threshold == (uchar)255 ? pixel_threshold : pixel_grayscale;
        }
    }
}


void fillBlock (Mat *frame, int x, int y, int h, int w, int thresh) {
    int acc = 0;
    for (int i = 0; i < h; ++i) {
        for (int j = 0; j < w; ++j) {
            acc += (frame->at<Vec3b>(y+i, x+j)(0) == 255 ? 1 : 0);
        }
    }
    uchar color = (uchar)((acc > thresh) ? 255 : 0);
    Vec3b *pix = 0;
    for (int i = 0; i < h; ++i) {
        for (int j = 0; j < w; ++j) {
            pix = &(frame->at<Vec3b>(y+i, x+j));
            (*pix)(0)= color;
            (*pix)(1)= color;
            (*pix)(2)= color;
        }
    }
}

void block(Mat *frame, int h, int w, int thresh) {
    int vB = (h >> 3), hB = (w >> 3);

    for (int i = 0; i < vB; ++i) {
        for (int j = 0; j < hB; ++j) {
            fillBlock(frame, j*8, i*8, 8, 8, thresh);
        }
    }
}

inline int min (const int a, const int b) { return a < b ? a : b; }
inline int max (const int a, const int b) { return a > b ? a : b; }
const double PI = 3.14159265359;

Mat gaussianBlur(Mat &frame, int radius) {
    Mat *res = new Mat(frame.size(), CV_8UC1);
    double rs = ceil(radius * 2.57);
    int width = frame.size().width, height = frame.size().height;
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            double val = 0, wsum = 0;
            for (int k = i - rs; k < i + rs + 1; ++k) {
                for (int l = j - rs; l < j + rs + 1; ++l) {
                    int x = min(width - 1, max(0, l));
                    int y = min(height - 1, max(0, k));
                    int dsq = (l - j) * (l - j) + (k - i) * (k - i);
                    double ex = exp( -dsq / (2 * radius * radius) );
                    double pix2sq = (PI * 2 * radius * radius);
                    double weight = ex / pix2sq;
                    val += frame.at<uchar>(y , x) * weight;
                    wsum += weight;
                }
            }
            double z = val / wsum;
            if (z > 255)
                res->at<uchar>(i , j) = 255;
            else
                res->at<uchar>(i , j) = (uchar)z;
        }
    }
    return *res;
}


/**
 * 
 */
int main(int argc, char** argv) {
    String inputFile = "input.mp4", outputFile = "grayscaleVid.avi";
    //Set the threshold used by the threshold filter based on the input arguments
    int threshold = 75;
    /* Args:
     * 1 - Threshold
     * 2 - input file
     * 3 - output file*/
    switch (argc)
    {
        case 4: outputFile = argv[3];
        case 3: inputFile = argv[2];
        case 2: threshold = atoi(argv[1]); break;
    };

    //Load the video file from disk
    VideoCapture inputVideo(inputFile);
    if (!inputVideo.isOpened()) {
        return -1;
    }


    //Set the first frame as the background frame and convert it to grayscale
    inputVideo >> backgroundFrame;
    backgroundFrame = *Filters::Luminance(backgroundFrame);
    VideoWriter outputVideo (outputFile, VideoWriter::fourcc('M','P','E','G'), 30,
                             Size(backgroundFrame.size().width,backgroundFrame.size().height), 1);

    int frame_count = (int)inputVideo.get(CV_CAP_PROP_FRAME_COUNT);
    Mat current_frame;
    std::cout << "Starting... " << frame_count << " frames to go"<< std::endl;
    for (int i = 0; i < frame_count; i++) {
        inputVideo >> current_frame;
        process(current_frame, threshold);
        block(&current_frame, current_frame.size().height, current_frame.size().width, 16);
        outputVideo << current_frame;
    }

    return 0;
}


