//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"

Mat* Background::calculateMask() {
    //Generate a matrix of absolute differences between frame and old_frame
    Mat * abs_frame_oldframe = new Mat(frame->size(), CV_8UC1);
    for (int i=0; i < frame->size().height; i++) {
        for (int j = 0; j < frame->size().width; j++) {
            uchar frame_pixel = frame->at<uchar>(i,j);
            uchar old_frame_pixel = old_frame->at<uchar>(i,j);
            abs_frame_oldframe->at<uchar>(i,j) = (frame_pixel > old_frame_pixel) ? frame_pixel - old_frame_pixel
                                                                                 : old_frame_pixel - frame_pixel;
        }
    }

    //Generate a matrix of absolute differences between frame and older_frame
    Mat * abs_frame_olderframe = new Mat(frame->size(), CV_8UC1);
    for (int i=0; i < frame->size().height; i++) {
        for (int j = 0; j < frame->size().width; j++) {
            uchar frame_pixel = frame->at<uchar>(i,j);
            uchar older_frame_pixel = older_frame->at<uchar>(i,j);
            abs_frame_olderframe->at<uchar>(i,j) = (frame_pixel > older_frame_pixel) ? frame_pixel - older_frame_pixel
                                                                                     : older_frame_pixel - frame_pixel;
        }
    }

    //Get the mean value from the absolute differences between frame and old_frame
    long mean_abs_frame_oldframe = 0;
    for (int i=0; i < frame->size().height; i++) {
        for (int j = 0; j < frame->size().width; j++) {
            mean_abs_frame_oldframe += abs_frame_olderframe->at<uchar>(i,j);
        }
    }
    mean_abs_frame_oldframe /= frame->size().height * frame->size().width;

    //Get the variance from the absolute differences between frame and old_frame
    long variance_abs_frame_oldframe = 0;
    for (int i=0; i < frame->size().height; i++) {
        for (int j = 0; j < frame->size().width; j++) {
            mean_abs_frame_oldframe += abs_frame_olderframe->at<uchar>(i,j);
        }
    }

    return NULL;
}