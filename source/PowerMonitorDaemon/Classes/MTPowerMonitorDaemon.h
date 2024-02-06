/*
     PowerMonitorDaemon.h
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

#import <Cocoa/Cocoa.h>
#import "MTSleepWatcher.h"
#import "PowerMonitorDaemonProtocol.h"

/*!
 @class         MTPowerMonitorDaemon
 @abstract      This class defines the power monitor daemon.
*/

@interface MTPowerMonitorDaemon : NSObject <PowerMonitorDaemonProtocol, NSXPCListenerDelegate, MTSleepWatcherDelegate>

/*!
 @method        startMonitoring
 @abstract      Starts power monitoring.
 @discussion    Returns YES if the measurement file could be opened for writing, mapped into memory
                and power monitoring started successfully, otherwise returns NO.
*/
- (BOOL)startMonitoring;

/*!
 @method        stopMonitoring
 @abstract      Stops power monitoring.
 @discussion    Returns YES if power monitoring has been stopped, otherwise returns NO.
*/
- (BOOL)stopMonitoring;

@end
