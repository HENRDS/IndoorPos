//
// Created by henry on 15/06/16.
//

#include "Performance.h"
#define _RARGS(x, y) (x*Settings::BLOCK_SIZE, y*Settings::BLOCK_SIZE, Settings::BLOCK_SIZE, Settings::BLOCK_SIZE);

void fastProcess(Ptr<Mat> frame)
{
    Ptr<Mat> iFrame(new Mat(frame->size(), CV_8UC1));
    // Grayscale
    cvtColor(*frame, *iFrame, CV_RGB2GRAY);
    // Background


}

inline uint FastAsFuck::countChanged(Mat* input) {
    uchar *p;
    uint acc = 0;
    for (int i = 0; i < input->rows; i++) {
        p = input->ptr<uchar>(i);
        for (int j = 0; j < input->cols; j++)
            acc += p[j] & 0x01;
    }
    return acc;
}


void process(Mat* roi){
    double x = FastAsFuck::countChanged(roi);
    uchar color = x > Settings::BLOCK_THRESHOLD ? (uchar)255 : (uchar)0;
    uchar * p;
    for (int i = 0; i < roi->rows; ++i) {
        p = roi->ptr<uchar>(i);
        for (int j = 0; j < roi->cols; ++j) {
            p[j] = color;
        }
    }
    delete roi;
}


void FastAsFuck::BinaryBlocks(Mat& frame) {
    // Cara como  eu odeio essas variaveis com nome gigante!!!!
    //Since the BLOCK_SIZE must be power of 2, it is possible to divide only by executing shifts
    int log2_block_size = (int) log2((double)Settings::BLOCK_SIZE);
    int vblocks = (frame.rows >> log2_block_size);
    int hblocks = (frame.cols >> log2_block_size);

    for (int i = 0; i < vblocks; i++) {
        for (int j = 0; j < hblocks; j++) {
            Rect r _RARGS(j, i);
            process(new Mat(frame, r));
        }
    }
}

void ParallelMatBlock::operator ()(const Range& range) const {
    uchar color = 0;///FastAsFuck::countChanged(mat, range) > 12 ? (uchar)255 : (uchar)0;
    uchar * pix;
    for (int i = range.start; i < range.end; i++) {
        pix = mat->ptr<uchar>(i);
        for (int j = range.start; j < range.end; j++) {
            pix[j] = color;
        }
    }
}
void mask()
{

}
 /*
  *
double Support::Variance(InputArray input, double mean) {
    double variance = 0;
    Mat m = input.getMat();
    for (int i = 0; i < m.rows; ++i) {
        uchar* pix = m.ptr(i);
        for (int j = 0; j < m.cols; ++j) {
            variance += pow(pix[j] - mean,2);
        }
    }
    if (variance != 0)
        variance /= input.size().area();
    return variance;
}

void  Support::_merge(InputArray input1, InputArray input2, OutputArray output) {
    Mat mat1 = input1.getMat(), mat2 = input2.getMat();
    Mat out(mat1.size(), CV_8U);
    uchar *p1, *p2;
//#pragma omp parallel for private(p1, p2)
    for (int i = 0; i < mat1.rows; ++i) {
        p1 = mat1.ptr<uchar>(i);
        p2 = mat2.ptr<uchar>(i);
        for (int j = 0; j < mat1.cols; ++j) {
            if ((p1[j] == 255) || (p2[j] == 255))
                out.at<uchar>(i, j) = 255;
            else
                out.at<uchar>(i, j) = 0;
        }
    }
    output.create(out.size(),CV_8U);
    out.copyTo(output);
}*/