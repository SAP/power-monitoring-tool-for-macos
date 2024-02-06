/*
     PowerMonitorDaemonProtocol.h
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
#import <OSLog/OSLog.h>

/*!
 @protocol      PowerMonitorDaemonProtocol
 @abstract      Defines the protocol implemented by the daemon and
                called by the xpc service and Power Monitor.
*/

@protocol PowerMonitorDaemonProtocol

/*!
 @method        connectWithEndpointReply:
 @abstract      Returns an endpoint that's connected to the daemon.
 @param         reply The reply block to call when the request is complete.
 @discussion    This method is only called by the xpc service.
*/
- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint* endpoint))reply;

/*!
 @method        logEntriesSinceDate:completionHandler:
 @abstract      Returns the log entries beginning from the given date.
 @param         date An NSDate object specifying the beginning of the log entries.
 @param         completionHandler The handler to call when the request is complete.
 @discussion    Returns an array containing the log entries for SapMachine Manager and
                its components from the given date until now.
*/
- (void)logEntriesSinceDate:(NSDate*)date completionHandler:(void (^)(NSArray<OSLogEntry*> *entries))completionHandler;

- (void)deleteMeasurementsWithCompletionHandler:(void (^)(void))completionHandler;

- (void)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly completionHandler:(void (^)(BOOL success))completionHandler;

@end
