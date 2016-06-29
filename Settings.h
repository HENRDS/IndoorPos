//
// Created by rodrigo on 5/24/16.
//

#ifndef INDOORPOS_SETTINGS_H
#define INDOORPOS_SETTINGS_H
/* FLAGS */
#define SEE_BACKGROUND
#define BLOB_COUNT
#define COUNT_TIME
#define VERBOSE_
#ifndef BLOB_COUNT
    #define EDGE_DETECTION
#endif
/* VALUES */
#define DIFF_THRESHOLD 25
#define BLOCK_THRESH 32
#define BLOCK_SIZE 16
#define KERNEL_SIZE 8
#define CLOSE_ITERS 8
#define BACKGROUND_BUFFER_SIZE 10
#define PEOPLE_ALPHA 0.02
/* MACROS */
#define __RECT_ARGS(x, y) (x*BLOCK_SIZE, y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
#define show(frame) imshow("Indoor Positioning System", frame);\
                    waitKey(1)
#ifdef COUNT_TIME
    #define IF_TIME(cmd) cmd
#else
    #define IF_TIME(cmd)
#endif

#define show_stop(frame) imshow("Indoor Positioning System", frame);\
                    waitKey(0)
#define print(str) std::cout << str << std::endl
#endif //INDOORPOS_SETTINGS_H
