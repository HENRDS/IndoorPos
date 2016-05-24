//
// Created by rodrigo on 5/24/16.
//

#ifndef INDOORPOS_SETTINGS_H
#define INDOORPOS_SETTINGS_H

class Settings {
public:
    //Difference Filter
    static const int DIFFERENCE_THRESHOLD = 40;
    //Closing Filter
    static const int KERNEL_SIZE = 8;
    //Block Filter
    static const int BLOCK_SIZE = 8; // MUST be some n where n = 2^k
    static const int BLOCK_THRESHOLD = 6;
    //Highlight Filter
    static const bool SEE_BACK = true; // Enable background in output
};

#endif //INDOORPOS_SETTINGS_H
