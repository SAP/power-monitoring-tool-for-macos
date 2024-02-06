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
#import "PowerMonitorXPC.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection 
{
    [newConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(PowerMonitorXPCProtocol)]];
    [newConnection setExportedObject:[[PowerMonitorXPC alloc] init]];
    [newConnection resume];
    
    return YES;
}

@end

int main(int argc, const char *argv[])
{
#pragma unused(argc)
#pragma unused(argv)
    
    ServiceDelegate *delegate = [[ServiceDelegate alloc] init];
    
    // set up the NSXPCListener
    NSXPCListener *listener = [NSXPCListener serviceListener];
    [listener setDelegate:delegate];
    [listener resume];
    
    return EXIT_SUCCESS;
}
