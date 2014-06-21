//
//  BGLog.h
//  Miner
//
//  Created by AndrewShmig on 4/10/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#ifndef Miner_BGLog____FILEEXTENSION___
#define Miner_BGLog____FILEEXTENSION___

#define SILENT_LOGS 0
#define VERBOSE_LOGS 1
#define MEGA_VERBOSE_LOGS 2

#define LOG_MODE VERBOSE_LOGS // Current log level

#if LOG_MODE == MEGA_VERBOSE_LOGS
#   define BGLog(format, ...)\
    @try {\
        NSLog(@"(%d, %@, %@) " format, __LINE__, [self class], NSStringFromSelector(_cmd), ##__VA_ARGS__);\
    } @catch (NSException *e) {\
        NSLog(@"!!!EXCEPTION OCCURED!!! (%d, %@, %@): %@", __LINE__, [self class], NSStringFromSelector(_cmd), e);\
    }
#elif LOG_MODE == VERBOSE_LOGS
#   ifdef DEBUG
#   define BGLog(format, ...) NSLog(@"(%d, %@, %@)", __LINE__, [self class], NSStringFromSelector(_cmd))
#   else
#   define BGLog(format, ...) /**/
#   endif
#elif LOG_MODE == SILENT_LOGS
#   define BGLog(format, ...) /**/
#endif

#endif
