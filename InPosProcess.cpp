//
// Created by henry on 21/06/16.
//

#include "InPosProcess.h"



InPosProcess::InPosProcess(String &filename) {
    video =  new VideoCapture(filename);
    Mat xx, yy;
    (*video) >> xx;
    cvtColor(xx, xx, CV_RGB2GRAY);
    GaussianBlur(xx, yy, Size(21, 21), 0);
    this->background = new Background(yy);
}

void InPosProcess::_retrieve(const _OutputArray &frame) {
    Mat m;
    video->read(m);
    m.copyTo(frame);
}
void InPosProcess::process(const _OutputArray &output)
{
#ifdef COUNT_TIME
    clock_t begin = clock();
#endif
    Mat frame;
    Mat back(frame.size(), CV_8UC1);
    Mat mShow(frame.size(), CV_8UC3);

    this->_retrieve(mShow);
    cvtColor(mShow, frame, CV_RGB2GRAY);

    GaussianBlur(frame, frame, Size(21, 21), 0);
    this->background->updateBackground(frame, back);
    absdiff(frame, back, frame);
    threshold(frame, frame, DIFF_THRESHOLD, 255, THRESH_BINARY);
    morph(frame, MORPH_CLOSE, CLOSE_ITERS);
    subtract(Scalar::all(255), frame, frame);
    int people_cnt = _detectBlobs(frame, mShow);

#ifdef VERBOSE_
#ifdef COUNT_TIME
    clock_t end = clock();
    double elapsed_secs;
    elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
#endif
    ostringstream strs;
    strs << people_cnt << " people detected ";
    IF_TIME(strs << "| T: " << elapsed_secs << "s");
    string s = strs.str();
#ifdef SEE_BACKGROUND
    Scalar color(255,255,255);
#else
    Scalar color(0,0,0);
#endif
    putText(mShow,s, Point(10, 20), FONT_HERSHEY_SIMPLEX, 0.7, color, 2);
    show(mShow);
#else
    show(mShow);
    frame.copyTo(output);
#endif
}
bool InPosProcess::getFrame(OutputArray image) {
    static int i;
    if (++i == (int) video->get(CV_CAP_PROP_FRAME_COUNT)) {
        return false;
    }
    process(image);
    return true;
}

int InPosProcess::_detectBlobs(const _InputArray &input, InputOutputArray output) {
    SimpleBlobDetector::Params params;
    params.minDistBetweenBlobs = 0;
    params.filterByArea = true;
    params.minArea = 1000;
    params.maxArea = 500000;
    params.filterByCircularity = false;
    params.filterByConvexity = false;
    params.filterByInertia = true;
    params.minInertiaRatio= 0.01;
    params.maxInertiaRatio= 0.99;

    Ptr<SimpleBlobDetector> detector = SimpleBlobDetector::create(params);
    std::vector<KeyPoint> keypoints;
    detector->detect(input, keypoints);
#ifdef SEE_BACKGROUND
    drawKeypoints(output, keypoints, output, Scalar(255,0,0), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
#else
    drawKeypoints(input, keypoints, output, Scalar(255,0,0), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
#endif
    return keypoints.size();
}


