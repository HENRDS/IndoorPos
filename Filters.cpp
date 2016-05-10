//
// Created by rodrigo on 4/19/16.
//

#include "Filters.h"

inline uchar Filters::Grayscale(Vec3b &pixel) {
    return (uchar) ((pixel(0) + pixel(1) + pixel(2)) / 3);
}

Mat *Filters::Grayscale(Mat &frame) {
    Mat *result = new Mat(frame.size(), CV_8UC1);
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = Filters::Grayscale(frame.at<Vec3b>(i, j));
        }
    }
    return result;
}

inline uchar Filters::Luminance(Vec3b &pixel) {
    return (uchar) (0.2989 * pixel(2) + 0.5870 * pixel(1) + 0.1140 * pixel(0));
}

Mat *Filters::Luminance(Mat &frame) {
    Mat *result = new Mat(frame.size(), CV_8UC1);
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = Filters::Luminance(frame.at<Vec3b>(i, j));
        }
    }
    return result;
}

inline uchar Filters::Difference(uchar referencePixel, uchar pixel) {
    return (referencePixel > pixel) ? referencePixel - pixel : pixel - referencePixel;
}

Mat *Filters::Difference(Mat &reference_frame, Mat &frame) {
    Mat *result = new Mat(frame.size(), CV_8UC1);
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = Filters::Difference(reference_frame.at<uchar>(i, j), frame.at<uchar>(i, j));
        }
    }
    return result;
}

inline uchar Filters::Threshold(uchar pixel, uchar threshold) {
    return (pixel > threshold) ? (uchar) 255 : (uchar) 0;
}

Mat *Filters::Threshold(Mat &frame, uchar threshold) {
    Mat *result = new Mat(frame.size(), CV_8UC1);
    for (int i = 0; i < frame.size().height; i++) {
        for (int j = 0; j < frame.size().width; j++) {
            result->at<uchar>(i, j) = Filters::Threshold(frame.at<uchar>(i, j), threshold);
        }
    }
    return result;
}

const double MOVING_AVERAGE_FILTER_ALPHA = 0.05;
uchar Filters::MovingAverage(uchar previousAverage, uchar currentPixel) {
    return MOVING_AVERAGE_FILTER_ALPHA * currentPixel + (1 - MOVING_AVERAGE_FILTER_ALPHA) * previousAverage;
}

Mat *Filters::BinaryBlocks(Mat &frame, int block_size, int threshold) {
    Mat *result = new Mat(frame.size(), CV_8UC1);

    int frame_height = frame.size().height;
    int frame_width = frame.size().width;

    //Since the block_size must be power of 2, it is possible to divide only by executing shifts
    int log2_block_size = (int) log2((double)block_size);
    int vertical_blocks = (frame_height >> log2_block_size);
    int horizontal_blocks = (frame_width >> log2_block_size);

    //Process each block separately
    for (int i_block = 0; i_block < vertical_blocks; i_block++) {
        for (int j_block = 0; j_block < horizontal_blocks; j_block++){

            int modified_pixels = 0;
            int block_origin_i = i_block*block_size;
            int block_origin_j = j_block*block_size;

            //Count the number of pixels in the block with color 255
            for (int i_pixel = 0; i_pixel < block_size; i_pixel++) {
                for (int j_pixel = 0; j_pixel < block_size; j_pixel++) {
                    if (frame.at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) == 255)
                        modified_pixels++;
                }
            }

            //If the number is above a threshold, set all the other pixels also to 255
            for (int i_pixel = 0; i_pixel < block_size; i_pixel++) {
                for (int j_pixel = 0; j_pixel < block_size; j_pixel++) {
                    if (modified_pixels > threshold)
                        result->at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) = 255;
                    else
                        result->at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) = 0;
                }
            }
        }
    }

    return result;
}

const double PI = 3.14159265359;
Mat Filters::GaussianBlur(Mat &frame, int radius) {
    Mat *res = new Mat(frame.size(), CV_8UC1);
    double rs = ceil(radius * 2.57);
    int width = frame.size().width, height = frame.size().height;
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            double val = 0, wsum = 0;
            for (int k = i - rs; k < i + rs + 1; ++k) {
                for (int l = j - rs; l < j + rs + 1; ++l) {
                    int x = min(width - 1, max(0, l));
                    int y = min(height - 1, max(0, k));
                    int dsq = (l - j) * (l - j) + (k - i) * (k - i);
                    double ex = exp( -dsq / (2 * radius * radius) );
                    double pix2sq = (PI * 2 * radius * radius);
                    double weight = ex / pix2sq;
                    val += frame.at<uchar>(y , x) * weight;
                    wsum += weight;
                }
            }
            double z = val / wsum;
            if (z > 255)
                res->at<uchar>(i , j) = 255;
            else
                res->at<uchar>(i , j) = (uchar)z;
        }
    }
    return *res;
}

//inline uchar avg (uchar * vec) {
//    return (*vec + *(vec+1) + *(vec+2)) / 3;
//}
//
//Mat * grayscale (Mat &frame) {
//    Mat * result = new Mat(frame.size(), CV_8UC1);
//    std::cout << frame.rows << "x" << frame.cols << std::endl;
//    for (int i=0; i < frame.rows; i++) {
//        uchar * res= result->ptr(i);
//        uchar * frptr = frame.ptr(i);
//        for (int j = 0; j < frame.cols; j++) {
//            if ((i  >  1920) || (j > 1080))
//                std::cout << "EOI" << std::endl;
//            *res = avg(frptr+(3*i));
//            std::cout << *res << std::endl;
//        }
//    }
//    return result;
//}

/**
 *
 */
void BoxBlurFilter() { }