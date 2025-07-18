/*
     PowerMonitorXPCProtocol.h
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

#import <Foundation/Foundation.h>

/*!
 @protocol      PowerMonitorXPCProtocol
 @abstract      Defines the protocol implemented by the xpc service and
                called by Power Monitor.
*/

@protocol PowerMonitorXPCProtocol

/*!
 @method        connectWithDaemonEndpointReply:
 @abstract      Returns an endpoint that's connected to the daemon.
 @param         reply The reply block to call when the request is complete.
 */
- (void)connectWithDaemonEndpointReply:(void(^)(NSXPCListenerEndpoint *endpoint))reply;

@end
