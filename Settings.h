//
// Created by rodrigo on 5/24/16.
//

#ifndef INDOORPOS_SETTINGS_H
#define INDOORPOS_SETTINGS_H
//#define REDUCED_FRAME_RATE
#define SEE_BACKGROUND
class Settings {
public:
    //Difference Filter
    static const int DIFFERENCE_THRESHOLD = 70;
    //Closing Filter
    static const int KERNEL_SIZE = 16;
    static const int BACK_ITERATIONS = 5;
    static const int MOV_ITERATIONS = 4;
    //Block Filter
    static const int BLOCK_SIZE = 8; // MUST be some n where n = 2^k
    static const int BLOCK_THRESHOLD = 6;
    //Highlight Filter

};

#endif //INDOORPOS_SETTINGS_H
