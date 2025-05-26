/*
     PowerMonitorXPC.m
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

#import "PowerMonitorXPC.h"
#import "PowerMonitorDaemonProtocol.h"
#import "Constants.h"
#import <os/log.h>

@interface PowerMonitorXPC ()
@property (atomic, strong, readwrite) NSXPCConnection *daemonConnection;
@end

@implementation PowerMonitorXPC

- (void)connectToDaemon
{
    if (!_daemonConnection) {
        
        _daemonConnection = [[NSXPCConnection alloc] initWithMachServiceName:kMTDaemonMachServiceName
                                                                     options:NSXPCConnectionPrivileged];
        [_daemonConnection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(PowerMonitorDaemonProtocol)]];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        [_daemonConnection setInvalidationHandler:^{
          
            [self->_daemonConnection setInvalidationHandler:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                os_log(OS_LOG_DEFAULT, "SAPCorp: Daemon connection invalidated");
                self->_daemonConnection = nil;
            });
        }];
        
        [_daemonConnection setInterruptionHandler:^{
         
            [self->_daemonConnection setInterruptionHandler:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                os_log(OS_LOG_DEFAULT, "SAPCorp: Daemon connection interrupted");
                self->_daemonConnection = nil;
            });
        }];
#pragma clang diagnostic pop

        [_daemonConnection resume];
    }
}

- (void)connectWithDaemonEndpointReply:(void(^)(NSXPCListenerEndpoint *endpoint))reply
{
    [self connectToDaemon];
    [[_daemonConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
        reply(nil);
        
    }] connectWithEndpointReply:^(NSXPCListenerEndpoint *endpoint) {
        
        reply(endpoint);
    }];
}

@end
