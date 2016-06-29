//
// Created by henry on 21/06/16.
//

#include "InPosProcess.h"



InPosProcess::InPosProcess(String &filename) {
    video =  new VideoCapture(filename);
    Mat xx;
    (*video) >> xx;
    cvtColor(xx, xx, CV_RGB2GRAY);
    GaussianBlur(xx, xx, Size(11, 11), 0);
    this->background = new Background(xx);
}

void InPosProcess::_retrieve(const _OutputArray &frame) {
    Mat m;

    video->read(m);


    m.copyTo(frame);
}
void InPosProcess::_markEdges(const _InputOutputArray &image) {
    Mat canny_output;
    vector<vector<Point> > contours;
    vector<Vec4i> hierarchy;

    /// Detect edges using canny
    Canny( image, canny_output, 40, 200, 3);
    /// Find contours
    findContours( canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point(0, 0) );

    for( int i = 0; i< contours.size(); i++ )
    {
        Scalar color = Scalar(255);
        if (contourArea(contours[i]) > 500) {
            drawContours(image, contours, i, color, 1, 8, hierarchy, 5, Point());
        }
    }

}
void InPosProcess::process(const _OutputArray &output)
{
#ifdef COUNT_TIME
    clock_t begin = clock();
#endif
    static double x;
    int people_cnt = 0;
    Mat frame;
    Mat back(frame.size(), CV_8UC1);
    Mat mShow(frame.size(), CV_8UC3);

    this->_retrieve(mShow);
    cvtColor(mShow, frame, CV_RGB2GRAY); // to luma
    GaussianBlur(frame, frame, Size(11, 11), 0);
    this->background->updateBackground(frame, back);
    absdiff(frame, back, frame);
    threshold(frame, frame, DIFF_THRESHOLD, 255, THRESH_BINARY);
    Block_Processor::BinaryBlocks(frame);
    morph(frame, MORPH_CLOSE, CLOSE_ITERS);

#ifdef BLOB_COUNT
    subtract(Scalar::all(255), frame, frame);
    people_cnt = _detectBlobs(frame, mShow);
#endif
#ifdef VERBOSE_
    double elapsed_secs = 0;
#ifdef COUNT_TIME
        clock_t end = clock();
        elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
#endif
    if (x == 0)
        x = people_cnt;
    else
        x = x * (1-PEOPLE_ALPHA) + people_cnt * PEOPLE_ALPHA;
    _putTextOnOutput(mShow, (int)ceil(x), elapsed_secs);
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
#ifdef  VERBOSE_
void InPosProcess::_putTextOnOutput(const _InputOutputArray &image, int people_cnt, int elapsed_secs) {

    ostringstream strs;
    strs << people_cnt << " people detected ";
    IF_TIME(strs << "| T: " << elapsed_secs << "s");
    string s = strs.str();
#ifdef SEE_BACKGROUND
    Scalar color(255,255,255);
#else
    Scalar color(0, 0, 0);
#endif
    putText(image, s, Point(10, 20), FONT_HERSHEY_SIMPLEX, 0.7, color, 2);

}
#endif
int InPosProcess::_detectBlobs(const _InputArray &input, InputOutputArray output) {
    SimpleBlobDetector::Params params;
    params.minDistBetweenBlobs = 1;
    params.filterByArea = true;
    params.minArea = 1000;
    params.maxArea = 100000;
    params.filterByCircularity = false;
    params.filterByConvexity = false;
    params.filterByInertia = true;
    params.minInertiaRatio= 0.01;
    params.maxInertiaRatio= 1;

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


