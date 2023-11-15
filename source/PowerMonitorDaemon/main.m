/*
     main.m
     Copyright 2023 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import <Foundation/Foundation.h>
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementWriter.h"
#import "MTSystemInfo.h"
#import "Constants.h"

@interface Main : NSObject
@end

@implementation Main

- (int)run
{
    MTPowerMeasurementWriter *pMWriter = [[MTPowerMeasurementWriter alloc] initWithFileAtPath:kMTMeasurementFilePath
                                                                          maximumMeasurements:kMTMeasurementTimePeriod * 60 * (60 / kMTMeasurementInterval)];
    if (pMWriter) {
        
        printf("Power monitoring started…\n");
        
        // get the latest measurement to adjust file location
        __block NSInteger bufferIndex = [pMWriter currentBufferIndex];
        
        // start measuring…
        [NSTimer scheduledTimerWithTimeInterval:kMTMeasurementInterval
                                        repeats:YES
                                          block:^(NSTimer *timer) {
            
            // get current system power
            float powerValue = [MTSystemInfo rawSystemPower];
            
            if (powerValue > 0) {
                
                // change data
                MeasurementStruct data;
                data.timestamp = CFSwapInt64HostToBig([[NSDate date] timeIntervalSince1970]);
                data.value = CFSwapInt32HostToBig(*(int*)(&powerValue));
                [[pMWriter measurementData] replaceMappedBytesInRange:NSMakeRange(bufferIndex, sizeof(data)) withBytes:&data];
#ifdef DEBUG
                printf("System power (%lu): %f W\n", bufferIndex / sizeof(data), powerValue);
#endif
                if (bufferIndex + sizeof(data) >= [[pMWriter measurementData] length]) {
                    bufferIndex = 0;
                } else {
                    bufferIndex += sizeof(data);
                }
            }
        }];
        
        // …and never return
        CFRunLoopRun();

    } else {

        fprintf(stderr, "ERROR! Failed to access buffer file: %s\n", [kMTMeasurementFilePath UTF8String]);
    }
    
    return EXIT_FAILURE;
}

@end


int main(int argc, const char * argv[])
{
#pragma unused(argc)
#pragma unused(argv)
    
    int exitCode = EXIT_SUCCESS;
    
    @autoreleasepool {
        
        NSCountedSet *countedSet = [[NSCountedSet alloc] initWithArray:[MTSystemInfo processList]];
        
        if ([countedSet countForObject:@"PowerMonitorDaemon"] > 1) {
            
            fprintf(stderr, "ERROR! Another instance of this daemon is already running\n");
            exitCode = EXIT_FAILURE;
            
        } else {
            
            Main *m = [[Main alloc] init];
            exitCode = [m run];
        }
    }
    
    return exitCode;
}
