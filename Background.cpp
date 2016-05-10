//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"

Background::Background(Mat& _frame) {
    background_frame = _frame.clone();
    last_frames[0] = background_frame;
    last_frames[1] = background_frame;
    last_frames[2] = background_frame;
}

Mat *Background::calculateMask() {
    //Generate a matrix of absolute differences between frame in t and in (t-1)
    Mat *abs_frame_minus1 = Filters::Difference(last_frames[0], last_frames[1]);

    //Generate a matrix of absolute differences between frame in t and in (t-2)
    Mat *abs_frame_minus2 = Filters::Difference(last_frames[0], last_frames[2]);

    //Get the mean value from the absolute differences between frame in t and in (t-1)
    double mean_frame_minus1 = Support::Mean(*abs_frame_minus1);

    //Get the mean value from the absolute differences between frame in t and in (t-2)
    double mean_frame_minus2 = Support::Mean(*abs_frame_minus2);

    //Get the standard deviation of absolute differences between frame in t and in (t-1)
    double std_deviation_frame_minus1 = Support::StandardDeviation(*abs_frame_minus1, mean_frame_minus1);

    //Get the standard deviation of absolute differences between frame in t and in (t-2)
    double std_deviation_frame_minus2 = Support::StandardDeviation(*abs_frame_minus2, mean_frame_minus2);

    Mat *mask = new Mat(last_frames[0].size(), CV_8UC1);

    for (int i = 0; i < last_frames[0].size().height; i++) {
        for (int j = 0; j < last_frames[0].size().width; j++) {
            if (abs_frame_minus1->at<uchar>(i,j) >= mean_frame_minus1 + std_deviation_frame_minus1)
            if (abs_frame_minus2->at<uchar>(i,j) >= mean_frame_minus2 + std_deviation_frame_minus2)
                mask->at<uchar>(i,j) = 255;
            else
                mask->at<uchar>(i,j) = 0;
        }
    }

    Mat* mask_2 = Filters::BinaryBlocks(*mask, 8, 2);

    return mask_2;
}

void Background::updateBackground(Mat& _frame) {
    //Update the pointers with the three last frames location
    last_frames[2] = last_frames[1];
    last_frames[1] = last_frames[0];
    last_frames[0] = _frame.clone();

    Mat* mask = calculateMask();

    //Only update the background with pixels from the current frame, if the pixels are not considered part of a movement.
    for (int i = 0; i < last_frames[0].size().height; i++) {
        for (int j = 0; j < last_frames[0].size().width; j++) {
            if (mask->at<uchar>(i,j) == 0)
                background_frame.at<uchar>(i,j) = Filters::MovingAverage(background_frame.at<uchar>(i,j),
                                                                         last_frames[0].at<uchar>(i,j));
        }
    }
}