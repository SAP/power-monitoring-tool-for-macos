/*
     main.m
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

#import <Foundation/Foundation.h>
#import "MTSystemInfo.h"
#import "MTPowerMonitorDaemon.h"

@interface Main : NSObject
@property (nonatomic, strong, readwrite) MTPowerMonitorDaemon *powerMonitorDaemon;
@end

@implementation Main

- (int)run
{
    BOOL success = [_powerMonitorDaemon startMonitoring];
    
    if (success) {

        signal(SIGTERM, SIG_IGN);
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, queue);
         
        if (source) {
            
            dispatch_source_set_event_handler(source, ^{
                
                [self->_powerMonitorDaemon stopMonitoring];
                self->_powerMonitorDaemon = nil;
                os_log(OS_LOG_DEFAULT, "SAPCorp: Exiting");
                
                exit(0);
            });
         
            // start processing signals
            dispatch_resume(source);
        }
        
        // never return
        CFRunLoopRun();
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
            m.powerMonitorDaemon = [[MTPowerMonitorDaemon alloc] init];
            exitCode = [m run];
        }
    }
    
    return exitCode;
}
