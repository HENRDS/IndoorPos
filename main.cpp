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
#include <opencv2/highgui/highgui.hpp>
#include "Performance.h"
#include "Filters.h"
#include "Background.h"
#include "Settings.h"
#include "Support.h"
#include <stdio.h>

#define FUCK(text) std::cout << text << std::endl

using namespace cv;
using namespace std;
Background *background;

inline void morph(InputArray input, OutputArray output, int type) {
    morphologyEx(input, output, type, getStructuringElement(MORPH_RECT, Size(Settings::KERNEL_SIZE, Settings::KERNEL_SIZE)),
                 Point(-1, -1), Settings::MOV_ITERATIONS);
}

Mat* _frames[3];
inline void update_buffers(InputArray input) {

    delete _frames[2];
    _frames[2] = _frames[1];
    _frames[1] = _frames[0];
    _frames[0] = new Mat();
    input.getMat().copyTo(*_frames[0]);
}

void processTminus(InputArray input1, InputArray input2, OutputArray  output) {
    Mat delta;//(input1.size(), CV_8UC1);
    absdiff(input1, input2, delta);
    double _mean = mean(delta)[0];
    double stdDev = Support::StandardDeviation(&delta, _mean);
    threshold(delta,delta, _mean + stdDev, 255, THRESH_BINARY);
    output.create(delta.size(),CV_8U);
    delta.copyTo(output);
}
inline void accWeighted(InputArray src, InputOutputArray dst, double alpha) {
    Mat _src = src.getMat();
    Mat _dst = dst.getMat();
    uchar *ps, *pd;
//#pragma omp parallel for private(ps, pd)
    for (int i = 0; i < _src.rows; ++i) {
        ps = _src.ptr<uchar>(i);
        pd = _dst.ptr<uchar>(i);
        for (int j = 0; j < _src.cols; ++j) {
            pd[j] = (uchar)(pd[j] * alpha + (1-alpha) * ps[j]);
        }
    }
}

void Contourns(InputOutputArray input,  OutputArray output) {
    vector<vector<Point>> contours;
    //findContours(input, contours, )
}


void newProcess(const Mat& frame, const Mat& background, VideoWriter &writer)
{
    Mat result (frame.size(), CV_8U);
    cvtColor(frame, result, CV_RGB2GRAY);
    Mat blur (frame.size(), CV_8U);
    GaussianBlur(result, blur, Size(15, 15), 0);

    Mat delta (frame.size(), CV_8U);
    absdiff(result, background, delta);

    Mat thresh (frame.size(), CV_8U);
    threshold(delta, thresh, Settings::DIFFERENCE_THRESHOLD, 255, THRESH_BINARY);

    //morph(thresh, thresh, MORPH_CLOSE);

    Mat* x = new Mat(frame.size(), CV_8U);
    Filters::BinaryBlocks(x, &thresh, Settings::BLOCK_SIZE, Settings::BLOCK_THRESHOLD );

    subtract(Scalar::all(255),thresh,thresh);
    Mat blob (frame.size(), CV_8UC3);
    Filters::BlobDetector(&blob, &thresh);

    Mat show (frame.size(), CV_8UC3);
    Filters::HighlightBlobMask(&show, &blob, &result);

    imshow("WI", show);
    waitKey(5);
    delete x;
}




/*
void process(Mat* frame, Background* background) {
    //Obtain the luma version of the current frame
    Mat* luma_frame = new Mat(frame->size(), CV_8UC1);
    IP_RGB2GRAY(*frame, *luma_frame);
    

    //Update the background based on information from the current frame
    //background->updateBackground(luma_frame);

    //Obtain the difference of the current frame and the background.
    Mat movement_frame;
    absdiff(*luma_frame, *background->background_frame, movement_frame);

    //Keep only the differences above the threshold value
    threshold(movement_frame, movement_frame, Settings::DIFFERENCE_THRESHOLD, 255,THRESH_BINARY);

    //Use a closing filter so that moving regions get filled (remove non-movement pixels from inside)
    morph(movement_frame,movement_frame, MORPH_CLOSE);

    //Pixelize moving areas
    //Filters::BinaryBlocks(&movement_frame, &movement_frame, Settings::BLOCK_SIZE, Settings::BLOCK_THRESHOLD);
    FastAsFuck::BinaryBlocks(movement_frame);

    //Invert black-white color -- necessary for blob detection
    subtract(Scalar::all(255),movement_frame,movement_frame);

    //Detect blobs
    Mat* blob_frame = new Mat(frame->size(), CV_8UC3);
    Filters::BlobDetector(blob_frame, &movement_frame);

/*  namedWindow("Display Image", WINDOW_AUTOSIZE );
    imshow("Display Image", *blob_frame);
    waitKey(0);*/
/*
    Filters::HighlightBlobMask(frame, blob_frame, luma_frame);

/*  imshow("Display Image", *frame);
    waitKey(0);*/

    //Free resources
//    blob_frame->release();
//}

/**
 *
 */

int main(int argc, char** argv) {
    String input_file = "input.avi", output_file = "output.avi";
    /* Args:
     * 2 - input file
     * 3 - output file*/
    switch (argc) {
        case 3:
            output_file = argv[2];
        case 2:
            input_file = argv[1];
    };

    //Load the video file from disk
    VideoCapture input_video(input_file);

    if (!input_video.isOpened()) {
        return -1;
    }

    /*Gather the information */
    int fps = (int) input_video.get(CV_CAP_PROP_FPS);
    Size size((int)input_video.get(CV_CAP_PROP_FRAME_WIDTH), (int)input_video.get(CV_CAP_PROP_FRAME_HEIGHT));
    int frame_count = (int) input_video.get(CV_CAP_PROP_FRAME_COUNT);

    //Get the first background
    Mat first_frame, background_frame;
    input_video >> first_frame;
    cvtColor(first_frame, background_frame, CV_RGB2GRAY);
    first_frame.release();
    _frames[0] = new Mat(background_frame);
    _frames[1] = new Mat(background_frame);
    _frames[2] = new Mat(background_frame);
    background = new Background(&background_frame);
    VideoWriter output_video(output_file, VideoWriter::fourcc('M', 'P', 'E', 'G'), fps, size, false);

    Mat current_frame;
    Mat x;
    namedWindow("WI", WINDOW_AUTOSIZE);
    //Warn we're back
    std::cout << "Starting... " << frame_count << " frames to go" << std::endl;
    for (int i = 0; i < frame_count - 1; i++) {
        std::cout << "processing: " << i << "/" << frame_count << "\r";
        input_video >> current_frame;
        newProcess(current_frame, background_frame, output_video);
    }


    return 0;
}



