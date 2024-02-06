/*
     MTSystemInfo.h
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

/*!
 @class         MTSystemInfo
 @abstract      This class provides methods to get some system information.
*/

@interface MTSystemInfo : NSObject

/*!
 @method        processList
 @abstract      Returns a list of all running processes.
 @discussion    Returns an array containing the complete paths to all running processes
                or nil, if an error occurred.
*/
+ (NSArray*)processList;

/*!
 @method        rawSystemPower
 @abstract      Returns the Mac's current power value.
*/
+ (float)rawSystemPower;

/*!
 @method        deviceSupportsPowerNap
 @abstract      Returns if the device supports Power Nap or not.
 @discussion    Returns YES if Power Nap is supported, otherwise returns NO.
*/
+ (BOOL)deviceSupportsPowerNap;

/*!
 @method        powerNapStatusWithCompletionHandler:
 @abstract      Returns the Mac's current Power Nap settings.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns a boolean indicating if Power Nap is enabled and another boolean indicating
                if it's only enabled while on ac power.
*/
+ (void)powerNapStatusWithCompletionHandler:(void (^) (BOOL enabled, BOOL aconly))completionHandler;

/*!
 @method        enablePowerNap:acPowerOnly:
 @abstract      Enables or disables Power Nap.
 @param         enable If set to YES, Power Naps are allowed, otherwise not
 @param         aconly If set to YES, Power Naps are only allowed if ac power is connected
 @discussion    Returns YES on success, otherwise returns NO.
*/
+ (BOOL)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly;

/*!
 @method        hasBattery
 @abstract      Returns if the device has a battery or not.
 @discussion    Returns YES if the device has a battery, otherwise returns NO.
*/
+ (BOOL)hasBattery;

/*!
 @method        processesPreventingSleep
 @abstract      Returns a list of processes currently preventing sleep mode.
 @discussion    Returns an NSArray containing dictionaries with information about all processes currently
                preventing sleep mode or nil if an error occurred.
*/
+ (NSArray*)processesPreventingSleep;

/*!
 @method        loginItemEnabled
 @abstract      Returns if the current application is registered to be opened at login.
 @discussion    Returns YES if the current application is registered as login item and
                is eligible to run. Otherwise returns NO.
*/
+ (BOOL)loginItemEnabled;

/*!
 @method        enableLoginItem:
 @abstract      Registers the current application to be opened at login.
 @discussion    Returns YES if the current application has been successfully registered as login item and
                is eligible to run. Otherwise returns NO.
*/
+ (BOOL)enableLoginItem:(BOOL)enable;

@end
