//
// Created by rodrigo on 5/24/16.
//

#ifndef INDOORPOS_SETTINGS_H
#define INDOORPOS_SETTINGS_H
/* FLAGS */
//#define SEE_BACKGROUND
#define VERBOSE_
//#define COUNT_TIME

/* VALUES */
#define BLOCK_THRESH 8
#define BLOCK_SIZE 8
#define KERNEL_SIZE 8
#define CLOSE_ITERS 6

/* MACROS */
#define __RECT_ARGS(x, y) (x*BLOCK_SIZE, y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
#define show(frame) imshow("Verbose", frame);\
                    waitKey(1)
#ifdef COUNT_TIME
    #define IF_TIME(cmd) cmd
#else
    #define IF_TIME(cmd)
#endif

#define show_stop(frame) imshow("Verbose", frame);\
                    waitKey(0)

#endif //INDOORPOS_SETTINGS_H
