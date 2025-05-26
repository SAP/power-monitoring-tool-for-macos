/*
     PowerMonitorDaemonProtocol.h
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

/*!
 @method        deleteMeasurementsWithCompletionHandler :
 @abstract      Deletes all measurements.
 @param         completionHandler The handler to call when the request is complete.
*/
- (void)deleteMeasurementsWithCompletionHandler:(void (^)(void))completionHandler;

/*!
 @method        enablePowerNap:acPowerOnly:completionHandler:
 @abstract      Enables or disables Power Nap.
 @param         enable A boolean specifying if Power Nap should be enabled or disabled.
 @param         aconly A boolean specifying if the settings should be applied to ac power only (YES) or all power sources (NO).
 @param         completionHandler The handler to call when the request is complete.
 @discussion    Returns YES if Power Nap has been successfully set to the given value, otherwise returns NO.
*/
- (void)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly completionHandler:(void (^)(BOOL success))completionHandler;

/*!
 @method        setJournalEnabled:completionHandler:
 @abstract      Enables or disables the power journal.
 @param         enabled A boolean specifying if the journal should be enabled or disabled.
 @param         completionHandler The handler to call when the request is complete.
 @discussion    Returns YES if the journal has been successfully set to the given value,
                otherwise returns NO.
*/
- (void)setJournalEnabled:(BOOL)enabled completionHandler:(void (^)(BOOL success))completionHandler;

/*!
 @method        journalEnabledWithReply:
 @abstract      Returns the current status of the journal.
 @param         reply The reply block to call when the request is complete.
 @discussion    Returns YES if the journal is enabled, otherwise returns NO. The second argument is set to YES, if the
                setting is managed (via configuration profile), otherwise returns NO.
*/
- (void)journalEnabledWithReply:(void (^)(BOOL enabled, BOOL forced))reply;

/*!
 @method        setJournalAutoDeletionInterval:completionHandler:
 @abstract      Sets the interval for the automatic deleting of power journal entries.
 @param         interval An ineger specifying the deletion interval.
 @param         completionHandler The handler to call when the request is complete.
 @discussion    Returns YES if the interval has been successfully set to the given value,
                otherwise returns NO.
*/
- (void)setJournalAutoDeletionInterval:(NSInteger)interval completionHandler:(void (^)(BOOL success))completionHandler;

/*!
 @method        journalAutoDeletionIntervalWithReply:
 @abstract      Returns the current deletion interval for power journal entries.
 @param         reply The reply block to call when the request is complete.
 @discussion    Returns the currently configured deletion interval. The second argument is set to YES, if the
                setting is managed (via configuration profile), otherwise returns NO.
*/
- (void)journalAutoDeletionIntervalWithReply:(void (^)(NSInteger interval, BOOL forced))reply;

/*!
 @method        setIgnorePowerNaps:completionHandler:
 @abstract      Configures if Power Naps should be ignored or not. If set to YES, Power Naps are treated like
                times in sleep mode and no power data is catured during Power Naps.
 @param         ignore A boolean specifying if Power Naps should be ignored or not.
 @param         completionHandler The handler to call when the request is complete.
 @discussion    Returns YES if the the option has been successfully set to the given value,
                otherwise returns NO.
*/
- (void)setIgnorePowerNaps:(BOOL)ignore completionHandler:(void (^)(BOOL success))completionHandler;

/*!
 @method        powerNapsIgnoredWithReply:
 @abstract      Returns if Power Naps are currently ignored or not.
 @param         reply The reply block to call when the request is complete.
 @discussion    Returns YES if Power Naps are currently ignored, otherwise returns NO. The second argument is set to YES, if the
                setting is managed (via configuration profile), otherwise returns NO.
*/
- (void)powerNapsIgnoredWithReply:(void (^)(BOOL ignored, BOOL forced))reply;


- (void)setAltPriceEnabled:(BOOL)enabled completionHandler:(void (^)(BOOL success))completionHandler;
- (void)altPriceEnabledWithReply:(void (^)(BOOL enabled, BOOL forced))reply;

- (void)setAltPriceSchedule:(NSDictionary*)schedule completionHandler:(void (^)(BOOL success))completionHandler;
- (void)altPriceScheduleWithReply:(void (^)(NSDictionary *schedule, BOOL forced))reply;


@end
