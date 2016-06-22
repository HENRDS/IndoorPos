//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"

Background::Background(InputArray input) {
    Mat _back = input.getMat();
    _back.copyTo(this->background_frame);
    for (int i = 0; i < 3; i++) {
        last_frames[i] = new Mat(_back.size(), CV_8UC1);
        _back.copyTo(*last_frames[i]);
    }
}
double Background::processTminus(int minus, const _OutputArray &output) {
    Mat *current = last_frames[0], *previous= last_frames[minus];
    Mat oMat(current->size(), CV_8UC1);
    absdiff(*current, *previous, oMat);
    Scalar _mean, _stdDev;
    meanStdDev(oMat, _mean, _stdDev);
    output.create(oMat.size(), CV_8UC1);
    oMat.copyTo(output);
    return _mean[0] + _stdDev[0];
}

void Background::calculateMask(InputOutputArray mask) {
    Mat iMat = mask.getMat();
    Mat tMinus1, tMinus2;
    double max1 = processTminus(1, tMinus1);
    double max2 = processTminus(2, tMinus2);
    uchar *p1, *p2;
    for (int i = 0; i < last_frames[0]->rows; i++) {
        p1= tMinus1.ptr<uchar>(i);
        p2= tMinus2.ptr<uchar>(i);
        for (int j = 0; j < last_frames[0]->cols; j++) {
            if ((p1[j] >= max1 ) && (p2[j] >= max2 ))
                iMat.at<uchar>(i,j) = 255;
            else
                iMat.at<uchar>(i,j) = 0;
        }
    }


    morph(iMat, MORPH_DILATE, 8);
    Block_Processor::BinaryBlocks(iMat);
}

inline void Background::push_frame_back(const Mat &frame) {
    delete last_frames[2];
    last_frames[2] = last_frames[1];
    last_frames[1] = last_frames[0];
    last_frames[0] = new Mat(frame.size(), CV_8UC1);
    frame.copyTo(*last_frames[0]);
}
uchar avg(uchar input1, uchar input2, double alpha) {
    return (uchar)(input1*alpha + input2*(1-alpha));
}
void Background::updateBackground(InputArray input, OutputArray background) {
    //Update the pointers with the three last frames location
    Mat iMat = input.getMat();
    push_frame_back(iMat);

    Mat mask(last_frames[0]->size(), CV_8UC1);
    calculateMask(mask);
    //Only update the background with pixels from the current frame, if the pixels are not considered part of a movement.
    uchar *p, *b;
    for (int i = 0; i < last_frames[0]->rows; i++) {
        p= mask.ptr<uchar>(i);
        b = background_frame.ptr<uchar>(i);
        for (int j = 0; j < last_frames[0]->cols; j++) {
            if (!p[j])
                b[j]= avg(b[j], last_frames[0]->at<uchar>(i,j), 0.2);
        }
    }
    background_frame.copyTo(background);
}