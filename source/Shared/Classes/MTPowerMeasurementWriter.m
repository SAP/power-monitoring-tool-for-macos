/*
     MTPowerMeasurementWriter.m
     Copyright 2023-2025 SAP SE
     
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

#import "MTPowerMeasurementWriter.h"
#import "Constants.h"
#import <os/log.h>

@interface MTPowerMeasurementWriter ()
@property (assign) int fileFD;
@end

@implementation MTPowerMeasurementWriter

- (instancetype)initWithFileAtPath:(NSString*)path maximumMeasurements:(NSInteger)maximumMeasurements
{
    self = [super init];
    
    if (self) {
        
        BOOL success = NO;
                    
        NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithShort:0777], NSFilePosixPermissions,
                                        @"staff", NSFileGroupOwnerAccountName,
                                        nil];
        
        if ([[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES
                                                       attributes:attributesDict
                                                            error:nil
            ]) {
                
            // check if the file already exists and if it has
            // the correct size. otherwise create a new file
            NSInteger calculatedFileSize = maximumMeasurements * sizeof(MeasurementStruct) + sizeof(MeasurementFileHeader);
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                            error:nil];
            if (fileAttributes) {
                
                NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                if ([fileSizeNumber integerValue] == calculatedFileSize) { 
                    
                    // check the header
                    MeasurementFileHeader header = [MTPowerMeasurement headerWithFilePath:path];
                    if (strcmp(header.signature, kMTFileHeaderSignature) == 0 && header.version == kMTFileHeaderVersion) {
                        success = YES;
                    }
                }
            }
            
            if (!success) {
                
                // write a new file
                NSMutableData *emptyData = [NSMutableData dataWithLength:calculatedFileSize];
                
                MeasurementFileHeader fileHeader =
                {
                    .signature = kMTFileHeaderSignature,
                    .version = kMTFileHeaderVersion,
                    .size = sizeof(MeasurementFileHeader)
                };
                
                [emptyData replaceBytesInRange:NSMakeRange(0, sizeof(MeasurementFileHeader))
                                     withBytes:&fileHeader
                ];
                
                success = [emptyData writeToFile:path atomically:NO];
                [[NSFileManager defaultManager] setAttributes:attributesDict ofItemAtPath:path error:nil];
            }
            
            // map the file
            if (success) {
                
                success = NO;
                _fileFD = open([path UTF8String], O_RDWR);
                
                // set file size
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                                error:nil];
                if (fileAttributes) {
                    
                    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                    NSInteger fileSize = [fileSizeNumber integerValue];
                    
                    char *mappedAddress = mmap(
                                               0,
                                               fileSize,
                                               PROT_WRITE | PROT_READ,
                                               MAP_SHARED | MAP_FILE | MAP_NOCACHE,
                                               _fileFD,
                                               0
                                               );
                    
                    if (mappedAddress == MAP_FAILED) {
                        
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to map buffer file (errno=%{public}d): %{public}s", errno, strerror(errno));
                        
                    } else {
                        
                        _measurementData = [[NSData alloc] initWithBytesNoCopy:mappedAddress + sizeof(MeasurementFileHeader)
                                                                        length:fileSize - sizeof(MeasurementFileHeader)
                                                                   deallocator:^(void *bytes, NSUInteger length) {

                            msync(mappedAddress, fileSize, MS_SYNC);
                            munmap(mappedAddress, fileSize);
                            close(self->_fileFD);
                        }];
                        
                        success = YES;
                    }
                }
            }
        }
        
        if (!success) { self = nil; }
    }
    
    return self;
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

- (void)invalidate
{
    _measurementData = nil;
}

@end
