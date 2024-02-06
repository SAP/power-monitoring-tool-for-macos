/*
     MTSleepWatcher.m
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

#import "MTSleepWatcher.h"

@interface MTSleepWatcher ()
@property (assign) id <MTSleepWatcherDelegate> delegate;
@end

@implementation MTSleepWatcher

MTPowerEvent *event;
IOPMConnection connection;

void sleep_changed(void * param,
                   IOPMConnection connection,
                   IOPMConnectionMessageToken token,
                   IOPMSystemPowerStateCapabilities capabilities)
{
    id delegate = (__bridge id)(param);
    
    if (IOPMIsASleep(capabilities)) {
        
        // going to sleep
        
        if (event && [event type] != MTPowerEventTypeSleep) {
            
            [event endEvent];
            
            if (delegate && [delegate respondsToSelector:@selector(powerEventDidEnd:)]) {
                [delegate powerEventDidEnd:event];
            }
        }
        
        if (!event || [event didEnd]) {
            
            event = [[MTPowerEvent alloc] init];
            [event setType:MTPowerEventTypeSleep];
            
            if (delegate && [delegate respondsToSelector:@selector(powerEventDidStart:)]) {
                [delegate powerEventDidStart:event];
            }
        }
        
    } else {
        
        // waking up
            
        if (event && [event type] == MTPowerEventTypeSleep) {
            
            [event endEvent];
            
            if (delegate && [delegate respondsToSelector:@selector(powerEventDidEnd:)]) {
                [delegate powerEventDidEnd:event];
            }
        }
        
        // as we can get multiple wake events, we make sure we
        // initialize our object just during the first event
        // and just update the event type for further events
        if (!event || [event didEnd]) {
            
            event = [[MTPowerEvent alloc] init];
            [event setType:[MTPowerEvent eventTypeWithCapabilities:capabilities]];
            
            if (delegate && [delegate respondsToSelector:@selector(powerEventDidStart:)]) {
                [delegate powerEventDidStart:event];
            }
            
        } else {
            
            MTPowerEventType eventType = [MTPowerEvent eventTypeWithCapabilities:capabilities];
            
            if (eventType > [event type]) {
                
                if (delegate && [delegate respondsToSelector:@selector(powerEvent:willChangeType:)]) {
                    [delegate powerEvent:event willChangeType:eventType];
                }
                
                [event setType:eventType];
            }
        }
    }
    
    return;
}

- (instancetype)initWithDelegate:(id<MTSleepWatcherDelegate>)delegate
{
    self = [super init];
    
    if (self) {
        
        _delegate = delegate;
    }
    
    return self;
}

- (BOOL)startWatching
{
    IOReturn ret = kIOReturnError;
    
    if (_delegate && !event) {
        
        event = [[MTPowerEvent alloc] init];
        
        // get the current state of the machine
        IOPMSystemPowerStateCapabilities capabilities = IOPMConnectionGetSystemCapabilities();
        [event setType:[MTPowerEvent eventTypeWithCapabilities:capabilities]];
        
        connection = NULL;
        
        ret = IOPMConnectionCreate(
                                   CFSTR("Sleep/Wake Monitoring"),
                                   kIOPMSleepWakeInterest,
                                   &connection
                                   );
        
        if (ret == kIOReturnSuccess) {
            
            ret = IOPMConnectionSetNotification(
                                                connection,
                                                (__bridge void *)(_delegate),
                                                sleep_changed
                                                );
            
            if (ret == kIOReturnSuccess) {
                
                ret = IOPMConnectionScheduleWithRunLoop(
                                                        connection,
                                                        CFRunLoopGetCurrent(),
                                                        kCFRunLoopDefaultMode
                                                        );
            }
        }
    }
            
    return (ret == kIOReturnSuccess) ? YES : NO;
}

- (BOOL)stopWatching
{
    IOReturn ret = kIOReturnError;
    
    ret = IOPMConnectionUnscheduleFromRunLoop(
                                              connection,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopDefaultMode
                                              );
    connection = NULL;
    event = NULL;
    
    return (ret == kIOReturnSuccess) ? YES : NO;
}

- (MTPowerEvent*)currentEvent
{
    return event;
}

@end
