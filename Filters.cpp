//
// Created by rodrigo on 4/19/16.
//

#include "Filters.h"

inline uchar Filters::Grayscale(Vec3b &pixel) {
    return (uchar) ((pixel(0) + pixel(1) + pixel(2)) / 3);
}

void Filters::Grayscale(Mat* output, Mat* input) {
    for (int i = 0; i < input->size().height; i++) {
        for (int j = 0; j < input->size().width; j++) {
            output->at<uchar>(i, j) = Filters::Grayscale(input->at<Vec3b>(i, j));
        }
    }
}

inline uchar Filters::Luminance(Vec3b &pixel) {
    return (uchar) (0.2989 * pixel(2) + 0.5870 * pixel(1) + 0.1140 * pixel(0));
}

void Filters::Luminance(Mat* output, Mat* input) {
    for (int i = 0; i < input->size().height; i++) {
        for (int j = 0; j < input->size().width; j++) {
            output->at<uchar>(i, j) = Filters::Luminance(input->at<Vec3b>(i, j));
        }
    }
}

inline uchar Filters::AbsoluteDifference(uchar referencePixel, uchar pixel) {
    return (referencePixel > pixel) ? referencePixel - pixel : pixel - referencePixel;
}

void Filters::AbsoluteDifference(Mat* output, Mat* frame_a, Mat* frame_b) {
    for (int i = 0; i < output->size().height; i++) {
        for (int j = 0; j < output->size().width; j++) {
            output->at<uchar>(i, j) = Filters::AbsoluteDifference(frame_a->at<uchar>(i, j), frame_b->at<uchar>(i, j));
        }
    }
}

inline uchar Filters::Threshold(uchar pixel, uchar threshold) {
    return (pixel > threshold) ? (uchar) 255 : (uchar) 0;
}

void Filters::Threshold(Mat* output, Mat* input, uchar threshold) {
    for (int i = 0; i < input->size().height; i++) {
        for (int j = 0; j < input->size().width; j++) {
            output->at<uchar>(i, j) = Filters::Threshold(input->at<uchar>(i, j), threshold);
        }
    }
}

const double MOVING_AVERAGE_FILTER_ALPHA = 0.05;
uchar Filters::MovingAverage(uchar previousAverage, uchar currentPixel) {
    return MOVING_AVERAGE_FILTER_ALPHA * currentPixel + (1 - MOVING_AVERAGE_FILTER_ALPHA) * previousAverage;
}

void Filters::BinaryBlocks(Mat* output, Mat* input, int block_size, int threshold) {
    int frame_height = input->size().height;
    int frame_width = input->size().width;

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
                    if (input->at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) == 255)
                        modified_pixels++;
                }
            }

            //If the number is above a threshold, set all the other pixels also to 255
            for (int i_pixel = 0; i_pixel < block_size; i_pixel++) {
                for (int j_pixel = 0; j_pixel < block_size; j_pixel++) {
                    if (modified_pixels > threshold)
                        output->at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) = 255;
                    else
                        output->at<uchar>(block_origin_i + i_pixel, block_origin_j + j_pixel) = 0;
                }
            }
        }
    }
}

void Filters::HighlightMask(Mat *output, Mat *mask, bool keep_back){
    for (int i = 0; i < mask->size().height; i++) {
        for (int j = 0; j < mask->size().width; j++) {
            uchar tresh_pixel = mask->at<uchar>(i, j);

            if (keep_back) {
                if (tresh_pixel == (uchar) 255) {
                    output->at<Vec3b>(i, j)(0) = (uchar)0;
                    output->at<Vec3b>(i, j)(1) = (uchar)0;
                    output->at<Vec3b>(i, j)(2) = (uchar)255;
                }
            } else {
                output->at<Vec3b>(i, j)(0) = tresh_pixel == (uchar) 255 ? (uchar)0 : 0;
                output->at<Vec3b>(i, j)(1) = tresh_pixel == (uchar) 255 ? (uchar)0 : 0;
                output->at<Vec3b>(i, j)(2) = tresh_pixel == (uchar) 255 ? (uchar)255 : 0;
            }
        }
    }
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