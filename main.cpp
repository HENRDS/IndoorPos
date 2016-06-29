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
#include "InPosProcess.h"

using namespace cv;
using namespace std;

int main(int argc, char** argv) {
    String input_file = "input.avi", output_file = "output.avi";
    InPosProcess proc(input_file);
    //Load the video file from disk
    Mat currentFrame;
    while (proc.getFrame(currentFrame))
#ifndef SAVE_FILE
        ;//waitKey(2000);
#else
    VideoWriter writer (output_file, VideoWriter::fourcc('M', 'P', 'E', 'G'), 10, Size(1280, 720), true);
#endif

    /*Gather the information
    int fps = (int) input_video.get(CV_CAP_PROP_FPS);
    Size size((int)input_video.get(CV_CAP_PROP_FRAME_WIDTH), (int)input_video.get(CV_CAP_PROP_FRAME_HEIGHT));
    int frame_count = (int) input_video.get(CV_CAP_PROP_FRAME_COUNT);

    //Get the first background
    Mat first_frame, background_frame;
    input_video >> first_frame;
    cvtColor(first_frame, background_frame, CV_RGB2GRAY);
    first_frame.release();


    VideoWriter background_writer ("background.avi", VideoWriter::fourcc('M', 'P', 'E', 'G'), fps, size, false);

    Mat current_frame;
    //Warn we're back
    std::cout << "Starting... " << frame_count << " frames to go" << std::endl;
    for (int i = 0; i < frame_count - 1; i++) {
        std::cout << "processing: " << i << "/" << frame_count << "\r";
        input_video >> current_frame;
        newProcess(current_frame, background_writer, output_video);
    }

*/
    return 0;
}




