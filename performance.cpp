//
// Created by henry on 15/06/16.
//


#include "Performance.h"


void Block_Processor::process(Mat* roi){
    int x = countNonZero(*roi);
    uchar color = x > BLOCK_THRESH ? (uchar)255 : (uchar)0;
    uchar * p;
    for (int i = 0; i < roi->rows; ++i) {
        p = roi->ptr<uchar>(i);
        for (int j = 0; j < roi->cols; ++j) {
            p[j] = color;
        }
    }
    delete roi;
}


void Block_Processor::BinaryBlocks(Mat& frame) {
    //Since the BLOCK_SIZE must be power of 2, it is possible to divide only by executing shifts
    int log2_block_size = (int) log2((double)BLOCK_SIZE);
    int vblocks = (frame.rows >> log2_block_size);
    int hblocks = (frame.cols >> log2_block_size);

    for (int i = 0; i < vblocks; i++) {
        for (int j = 0; j < hblocks; j++) {
            Rect r __RECT_ARGS(j, i);
            process(new Mat(frame, r));
        }
    }
}
void morph(const _InputOutputArray &frame, int op, int iters) {
    morphologyEx(frame, frame, op,getStructuringElement(MORPH_RECT, Size(KERNEL_SIZE, KERNEL_SIZE)), Point(-1, -1), iters);
}