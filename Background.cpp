//
// Created by rodrigo on 4/19/16.
//

#include "Background.h"

Background::Background(InputArray input) {
    Mat _back = input.getMat();
    _back.copyTo(this->background_frame);
    for (int i = 0; i < BACKGROUND_BUFFER_SIZE; i++) {
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
void Background::calculateMask(OutputArray mask) {

    Mat out(last_frames[0]->size(), CV_8UC1,Scalar(255));

    for (int i = 1; i < BACKGROUND_BUFFER_SIZE; ++i) {
        Mat tMinOut;
        double thresh = processTminus(i, tMinOut);
        threshold(tMinOut, tMinOut, thresh, 255, THRESH_BINARY);
        bitwise_and(out, tMinOut, out);

    }
    morph(out, MORPH_CLOSE, CLOSE_ITERS);
    out.copyTo(mask);
    //Block_Processor::BinaryBlocks(iMat);
}

inline void Background::push_frame_back(const Mat &frame) {
    delete last_frames[BACKGROUND_BUFFER_SIZE-1];
    for (int i = BACKGROUND_BUFFER_SIZE-1; i > 0; i--)
        last_frames[i] = last_frames[i-1];
    last_frames[0] = new Mat(frame.size(), CV_8UC1);
    frame.copyTo(*last_frames[0]);
}
inline uchar avg(uchar input1, uchar input2, double alpha) {
    return (uchar)(input1*alpha + input2*(1-alpha));
}
void Background::updateBackground(InputArray input, OutputArray background) {
    Mat iMat = input.getMat();
    push_frame_back(iMat);
    Mat mask;
    calculateMask(mask);
    imwrite("mask.jpg", mask);
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