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
#define SEE_BACK_
using namespace cv;

//Set the threshold used by the threshold filter based on the input arguments
int pixel_threshold_value = 75;
// Block size MUST be some n where n = 2^k
int block_size = 8;

/**
 *
 */
void process(Mat &frame, Background* background) {
    //Obtain the luma version of the current frame
    Mat luma_frame = *Filters::Luminance(frame);
    //Update the background based on information from the current frame
    background->updateBackground(luma_frame);
    //Obtain the difference of the current frame and the background.
    Mat difference_frame = *Filters::Difference(luma_frame, background->background_frame);
    Mat threshold_frame = *Filters::Threshold(difference_frame, pixel_threshold_value);
    Mat block_movements_frame = *Filters::BinaryBlocks(threshold_frame, block_size, 2);

    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            uchar luma_pixel =  luma_frame.at<uchar>(i,j);
            uchar tresh_pixel = block_movements_frame.at<uchar>(i, j);
            //Set the original RGB representation of the frame to grayscale by copying the grayscale value to each
            //component.
#ifdef SEE_BACK_
            frame.at<Vec3b>(i, j)(0) = tresh_pixel == (uchar) 255 ? (uchar)0 : luma_pixel;
            frame.at<Vec3b>(i, j)(1) = tresh_pixel == (uchar) 255 ? (uchar)0 : luma_pixel;
            frame.at<Vec3b>(i, j)(2) = tresh_pixel == (uchar) 255 ? (uchar)255 : luma_pixel;
#else
            frame.at<Vec3b>(i, j)(0) = tresh_pixel == (uchar) 255 ? (uchar)0 : 0;
            frame.at<Vec3b>(i, j)(1) = tresh_pixel == (uchar) 255 ? (uchar)0 : 0;
            frame.at<Vec3b>(i, j)(2) = tresh_pixel == (uchar) 255 ? (uchar)255 : 0;
#endif
        }
    }
}

void processPixel(Vec3b *pixel, uchar *background)
{
    //Obtain the grayscale version of the pixel in the current frame.
    uchar pixel_grayscale = Filters::Luminance(*pixel);
    //Obtain the difference of the current frame and the background.
    uchar pixel_difference = Filters::Difference(*background, pixel_grayscale);
    uchar pixel_threshold = Filters::Threshold(pixel_difference, pixel_threshold_value);
    //Update the background with information from the current frame using a moving average filter.
    (*background) = Filters::MovingAverage(*background, pixel_grayscale);
    //Set the original RGB representation of the frame to grayscale by copying the grayscale value to each
    //component.
#ifdef SEE_BACK_
    (*pixel)(0) = pixel_grayscale;
    (*pixel)(1) = pixel_grayscale;
    (*pixel)(2) = pixel_threshold == (uchar)255 ? pixel_threshold : pixel_grayscale;
#else
    if (pixel_threshold == (uchar)255 ) {
        (*pixel)(0) = 255;
        (*pixel)(1) = 255;
        (*pixel)(2) = 255;
    } else {
        (*pixel)(0) = 0;
        (*pixel)(1) = 0;
        (*pixel)(2) = 0;
    }
#endif
}


void processBlock(Mat *frame, int x, int y, int sz, int thresh) {
    int acc = 0;
    Vec3b *pix = 0;
    uchar *back = 0;
    for (int i = 0; i < sz; ++i) {
        for (int j = 0; j < sz; ++j) {
            pix = &frame->at<Vec3b>(y+i, x+j);
            back = 0; //&backgroundFrame.at<uchar>(y+i, x+j);
            processPixel(pix, back);
            acc += ((*pix)(2) == 255 ? 1 : 0);
        }
    }
    uchar color = (uchar)((acc > thresh) ? 255 : 0);

    for (int i = 0; i < sz; ++i) {
        for (int j = 0; j < sz; ++j) {
            pix = &(frame->at<Vec3b>(y+i, x+j));
#ifndef SEE_BACK_
            (*pix)(0)= color;
            (*pix)(1)= color;
#endif
            (*pix)(2)= color;
        }
    }
}

void block(Mat *frame, int h, int w, int thresh) {
    int shift = (int) log2((double)block_size);
    int vB = (h >> shift), hB = (w >> shift);

    for (int i = 0; i < vB; ++i) {
        for (int j = 0; j < hB; ++j) {
            processBlock(frame, j * block_size, i * block_size, block_size, thresh);
        }
    }
}

/**
 *
 */
int main(int argc, char** argv) {
    String input_file = "input.mp4", output_file = "grayscaleVid.avi";
    /* Args:
     * 1 - Threshold
     * 2 - input file
     * 3 - output file*/
    switch (argc)
    {
        case 4: output_file = argv[3];
        case 3: input_file = argv[2];
        case 2: pixel_threshold_value = atoi(argv[1]); break;
    };

    //Load the video file from disk
    VideoCapture input_video(input_file);
    if (!input_video.isOpened()) {
        return -1;
    }

    //Set the first frame as the background frame and convert it to grayscale
    Mat background_frame;
    input_video >> background_frame;
    background_frame = *Filters::Luminance(background_frame);
    Background *background = new Background(background_frame);
    VideoWriter output_video (output_file, VideoWriter::fourcc('M','P','E','G'), 30,
                              Size(background_frame.size().width,background_frame.size().height), 1);

    int frame_count = (int)input_video.get(CV_CAP_PROP_FRAME_COUNT);
    Mat current_frame;
    std::cout << "Starting... " << frame_count << " frames to go"<< std::endl;
    for (int i = 0; i < frame_count - 1; i++) {
        if (i % 3 == 0) {
            input_video >> current_frame;
            process(current_frame, background);
            //block(current_frame, 10, background);
        }
        output_video << current_frame;
    }
    return 0;
}


