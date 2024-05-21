/*
     MTPowerMeasurement.m
     Copyright 2023-2024 SAP SE
     
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

#import "MTPowerMeasurement.h"

@implementation MTPowerMeasurement

- (instancetype)initWithPowerValue:(double)powerValue
{
    self = [super initWithDoubleValue:powerValue unit:[NSUnitPower watts]];
    
    return self;
}

+ (MeasurementFileHeader)headerWithFilePath:(NSString*)path
{
    MeasurementFileHeader buffer = (MeasurementFileHeader){ 0 };
    
    int fd = open([path UTF8String], O_RDONLY);
    
    if (fd >= 0) {
        
        size_t headerSize = read(fd, &buffer, sizeof(MeasurementFileHeader));
        close(fd);
        
        if (headerSize != sizeof(MeasurementFileHeader)) {
            buffer = (MeasurementFileHeader){ 0 };
        }
    }
    
    return buffer;
}

- (NSString*)state
{
    NSString *stateString = NSLocalizedString(@"tooltipSleep", nil);
    
    if ([self doubleValue] > 0) {
        
        if ([self darkWake]) {
            
            stateString = NSLocalizedString(@"tooltipPowerNap", nil);
            
        } else {
            
            stateString = NSLocalizedString(@"tooltipAwake", nil);
        }
    }
    
    return stateString;
}

@end
