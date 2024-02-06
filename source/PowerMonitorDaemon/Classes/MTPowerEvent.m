/*
     MTPowerEvent.m
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

#import "MTPowerEvent.h"
#import "IOPMLibPrivate.h"

@interface MTPowerEvent ()
@property (nonatomic, strong, readwrite) NSDate *startDate;
@property (nonatomic, strong, readwrite) NSDate *endDate;
@end

@implementation MTPowerEvent

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _startDate = [NSDate date];
    }
    
    return self;
}

- (void)endEvent
{
    _endDate = [NSDate date];
}

- (NSTimeInterval)duration
{
    NSDate *endDate = (_endDate) ? _endDate : [NSDate date];
    NSTimeInterval eventDuration = [endDate timeIntervalSinceDate:_startDate];
    
    return eventDuration;
}

- (BOOL)didEnd
{
    return (_endDate) ? YES : NO;
}

+ (MTPowerEventType)eventTypeWithCapabilities:(IOPMSystemPowerStateCapabilities)capabilities
{
    MTPowerEventType eventType = MTPowerEventTypeNone;
    
    if (IOPMIsASleep(capabilities)) {
        
        eventType = MTPowerEventTypeSleep;
        
    } else if (IOPMIsADarkWake(capabilities)) {
            
        eventType = MTPowerEventTypeDarkWake;
            
    } else if (IOPMIsAUserWake(capabilities)) {
            
        eventType = MTPowerEventTypeUserWake;
    }
    
    return eventType;
}

@end
