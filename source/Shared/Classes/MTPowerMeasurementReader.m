/*
     MTPowerMeasurementReader.m
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

#import "MTPowerMeasurementReader.h"
#import "MTPowerMeasurementArray.h"
#import "MTSystemInfo.h"

@interface MTPowerMeasurementReader ()
@property (nonatomic, strong, readwrite) NSData *measurementData;
@property (assign) int fileFD;
@end

@implementation MTPowerMeasurementReader

- (instancetype)initWithContentsOfFile:(NSString*)path
{
    self = [super init];
    
    if (self) {
        
        BOOL success = NO;
        
        if (path) {
            
            _fileFD = open([path UTF8String], O_RDONLY);
                    
            // set file size
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                            error:nil];
            if (fileAttributes) {
                
                NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                NSInteger fileSize = [fileSizeNumber integerValue];
                
                char *mappedAddress = mmap(0, fileSize, PROT_READ, MAP_SHARED|MAP_FILE|MAP_NOCACHE, _fileFD, 0);
                
                if (mappedAddress == MAP_FAILED) {
                    
                    NSLog(@"SAPCorp: ERROR! Failed to map buffer file (errno=%d): %s", errno, strerror(errno));
                    
                } else {
                    
                    _measurementData = [[NSData alloc] initWithBytesNoCopy:mappedAddress
                                                                    length:fileSize
                                                               deallocator:^(void *bytes, NSUInteger length) {
                        
                        munmap(mappedAddress, fileSize);
                        close(self->_fileFD);
                    }];
                    
                    success = YES;
                }
                
            }
        }
        
        if (!success) { self = nil; }
    }
    
    return self;
}

- (NSArray<MTPowerMeasurement*>*)allMeasurements
{
    NSMutableArray *allMeasurements = [[NSMutableArray alloc] init];

    if (_measurementData) {
        
        uint32_t chunkSize = sizeof(MeasurementStruct);
        uint32_t chunkOffset = 0;
        
        // create an array of NSData objects
        while (chunkOffset + chunkSize <= [_measurementData length]) {
            
            NSData *dataChunk = [_measurementData subdataWithRange:NSMakeRange(chunkOffset, chunkSize)];
            MeasurementStruct data;
            [dataChunk getBytes:&data length:chunkSize];
            uint32_t powerValue = CFSwapInt32BigToHost(data.value);
            
            if (powerValue > 0) {
                
                time_t timeStamp = CFSwapInt64BigToHost(data.timestamp);
                MTPowerMeasurement *measurement = [[MTPowerMeasurement alloc] initWithPowerValue:*(float*)(&powerValue)];
                [measurement setTimeStamp:timeStamp];
                [allMeasurements addObject:measurement];
                
                chunkOffset += chunkSize;
                
            } else {
                break;
            }
        }
        
        // sort the data we got from our ring buffer
        NSInteger index = [self currentBufferIndex] / sizeof(MeasurementStruct);

        if (index > 0 && index < [allMeasurements count]) {
            NSRange moveRange = NSMakeRange(0, index);
            NSArray *toBeMoved = [allMeasurements subarrayWithRange:moveRange];
            [allMeasurements removeObjectsInRange:moveRange];
            [allMeasurements addObjectsFromArray:toBeMoved];
        }
    }
        
    return allMeasurements;
}

- (NSInteger)currentBufferIndex
{
    NSInteger measurementIndex = -1;
    
    if (_measurementData) {
        
        measurementIndex = 0;
        uint32_t chunkSize = sizeof(MeasurementStruct);
        uint32_t chunkOffset = 0;
        time_t lastTimestamp = 0;
        
        while (chunkOffset + chunkSize <= [_measurementData length]) {
            
            NSData *dataChunk = [_measurementData subdataWithRange:NSMakeRange(chunkOffset, chunkSize)];
            MeasurementStruct data;
            [dataChunk getBytes:&data length:chunkSize];
            time_t timestamp = CFSwapInt64BigToHost(data.timestamp);
            
            if (timestamp == 0 || timestamp < lastTimestamp) {
                break;
                
            } else {
                
                chunkOffset += chunkSize;
                lastTimestamp = timestamp;
                
                if (measurementIndex + chunkOffset > [_measurementData length]) {
                    chunkOffset = 0;
                    break;
                }
            }
        }
        
        measurementIndex = chunkOffset;
    }

    return measurementIndex;
}

- (MTPowerMeasurement*)currentPower
{
    MTPowerMeasurement *measurement = [[MTPowerMeasurement alloc] initWithPowerValue:[MTSystemInfo rawSystemPower]];
    
    return measurement;
}

@end
