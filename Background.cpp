//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"

Background::Background(Mat* input) {
    background_frame = new Mat();
    input->copyTo(*background_frame);

    for (int i = 0; i < 3; i++) {
        last_frames[i] = new Mat();
        input->copyTo(*last_frames[i]);
    }
}

void Background::calculateMask(Mat* output) {
    //Generate a matrix of absolute differences between frame in t and in (t-1)
    Mat* abs_frame_minus1 = new Mat(last_frames[0]->size(), CV_8UC1);
    Filters::AbsoluteDifference(abs_frame_minus1, last_frames[0], last_frames[1]);

    //Generate a matrix of absolute differences between frame in t and in (t-2)
    Mat* abs_frame_minus2 = new Mat(last_frames[0]->size(), CV_8UC1);
    Filters::AbsoluteDifference(abs_frame_minus2, last_frames[0], last_frames[2]);

    //Get the mean value from the absolute differences between frame in t and in (t-1)
    double mean_frame_minus1 = Support::Mean(abs_frame_minus1);

    //Get the mean value from the absolute differences between frame in t and in (t-2)
    double mean_frame_minus2 = Support::Mean(abs_frame_minus2);

    //Get the standard deviation of absolute differences between frame in t and in (t-1)
    double std_deviation_frame_minus1 = Support::StandardDeviation(abs_frame_minus1, mean_frame_minus1);

    //Get the standard deviation of absolute differences between frame in t and in (t-2)
    double std_deviation_frame_minus2 = Support::StandardDeviation(abs_frame_minus2, mean_frame_minus2);

    //Create a mask identifying pixels with movement based on their difference(mean + std deviation) from last frames
    for (int i = 0; i < last_frames[0]->size().height; i++) {
        for (int j = 0; j < last_frames[0]->size().width; j++) {
            if (abs_frame_minus1->at<uchar>(i,j) >= mean_frame_minus1 + std_deviation_frame_minus1)
            if (abs_frame_minus2->at<uchar>(i,j) >= mean_frame_minus2 + std_deviation_frame_minus2)
                output->at<uchar>(i,j) = 255;
            else
                output->at<uchar>(i,j) = 0;
        }
    }

    Filters::Closing(output, output, Settings::KERNEL_SIZE, Settings::BACK_ITERATIONS);

    //Generate the block version of the movement mask
    Filters::BinaryBlocks(output, output, Settings::BLOCK_SIZE, Settings::BLOCK_THRESHOLD);

    //Free resources
    abs_frame_minus1->release();
    abs_frame_minus2->release();
}

void Background::updateBackground(Mat* input) {
    //Update the pointers with the three last frames location
    last_frames[2] = last_frames[1];
    last_frames[1] = last_frames[0];
    last_frames[0] = new Mat();
    input->copyTo(*last_frames[0]);

    Mat* mask = new Mat(last_frames[0]->size(), CV_8UC1);
    calculateMask(mask);

    //Only update the background with pixels from the current frame, if the pixels are not considered part of a movement.
    for (int i = 0; i < last_frames[0]->size().height; i++) {
        for (int j = 0; j < last_frames[0]->size().width; j++) {
            if (mask->at<uchar>(i,j) == 0)
                background_frame->at<uchar>(i,j) = Filters::MovingAverage(background_frame->at<uchar>(i,j),
                                                                         last_frames[0]->at<uchar>(i,j));
        }
    }

    /*namedWindow("Display Image", WINDOW_AUTOSIZE );
    imshow("Display Image", *background_frame);
    waitKey(0);*/

    //Free resources
    mask->release();
    last_frames[2]->release(); //not used anymore in the next iteration of the function
}