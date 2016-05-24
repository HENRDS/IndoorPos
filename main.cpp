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
#include "Settings.h"

using namespace cv;

// Set up the detector with default parameters.
SimpleBlobDetector detector;

/**
 *
 */
void process(Mat* frame, Background* background) {
    //Obtain the luma version of the current frame
    Mat* filter_frame = new Mat(frame->size(), CV_8UC1);
    Filters::Luminance(filter_frame, frame);

    //Update the background based on information from the current frame
    background->updateBackground(filter_frame);

    //Obtain the difference of the current frame and the background.
    Filters::AbsoluteDifference(filter_frame, filter_frame, background->background_frame);

    //Keep only the differences above the threshold value
    Filters::Threshold(filter_frame, filter_frame, Settings::DIFFERENCE_THRESHOLD);

    //Use a closing filter so that moving regions get filled (remove non-movement pixels from inside)
    Filters::Closing(filter_frame, filter_frame, Settings::KERNEL_SIZE);

    // Detect blobs.
/*  std::vector<KeyPoint> keypoints;
    detector.detect(*closing_frame, keypoints);
    Mat * keypoints_frame = new Mat(frame->size(), CV_8UC1);
    drawKeypoints(*closing_frame, keypoints, *keypoints_frame, Scalar(255,0,0), DrawMatchesFlags::DRAW_RICH_KEYPOINTS );*/

    Filters::BinaryBlocks(filter_frame, filter_frame, Settings::BLOCK_SIZE, Settings::BLOCK_THRESHOLD);

    Filters::HighlightMask(frame, filter_frame, Settings::SEE_BACK);

    //Free resources
    filter_frame->release();
}

void processPixel(Vec3b *pixel, uchar *background)
{
    //Obtain the grayscale version of the pixel in the current frame.
    uchar pixel_grayscale = Filters::Luminance(*pixel);
    //Obtain the difference of the current frame and the background.
    uchar pixel_difference = Filters::AbsoluteDifference(*background, pixel_grayscale);
    uchar pixel_threshold = Filters::Threshold(pixel_difference, Settings::DIFFERENCE_THRESHOLD);
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
    int shift = (int) log2((double)Settings::BLOCK_SIZE);
    int vB = (h >> shift), hB = (w >> shift);

    for (int i = 0; i < vB; ++i) {
        for (int j = 0; j < hB; ++j) {
            processBlock(frame, j * Settings::BLOCK_SIZE, i * Settings::BLOCK_SIZE, Settings::BLOCK_SIZE, thresh);
        }
    }
}

/**
 *
 */
int main(int argc, char** argv) {
    String input_file = "input_2.mp4", output_file = "output.avi", background_file = "background.avi";

    /* Args:
     * 1 - Threshold
     * 2 - input file
     * 3 - output file*/
    switch (argc)
    {
        case 4: output_file = argv[3];
        case 3: input_file = argv[2];
        //case 2: Settings::difference_threshold = atoi(argv[1]); break;
    };

    //Load the video file from disk
    VideoCapture input_video(input_file);
    if (!input_video.isOpened()) {
        return -1;
    }

    //Set the first frame as the background frame and convert it to luma
    Mat* first_frame = new Mat();
    input_video.read(*first_frame);
    Mat* background_frame = new Mat(first_frame->size(), CV_8UC1);
    Filters::Luminance(background_frame, first_frame);
    first_frame->release();

    Background* background = new Background(background_frame);
    VideoWriter output_video(output_file, VideoWriter::fourcc('M','P','E','G'), 30,
                              Size(background_frame->size().width,background_frame->size().height), 1);
    VideoWriter background_video(background_file, VideoWriter::fourcc('M','P','E','G'), 30,
                                 Size(background_frame->size().width,background_frame->size().height), 0);

    int frame_count = (int)input_video.get(CV_CAP_PROP_FRAME_COUNT);
    Mat* current_frame = new Mat();
    std::cout << "Starting... " << frame_count << " frames to go"<< std::endl;
    for (int i = 0; i < frame_count - 1; i++) {
        if (i % 3 == 0) {
            input_video.read(*current_frame);
            process(current_frame, background);
            //block(current_frame, 10, background);
        }
        background_video << *(background->background_frame);
        output_video << *current_frame;
    }

    return 0;
}


