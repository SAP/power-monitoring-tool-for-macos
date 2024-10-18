/*
     MTSleepWatcher.h
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
#import "MTPowerEvent.h"

/*!
 @protocol      MTSleepWatcherDelegate
 @abstract      Defines an interface for delegates of MTSleepWatcher to be notified about power events.
*/
@protocol MTSleepWatcherDelegate <NSObject>
@optional

/*!
 @method        powerEventDidStart:
 @abstract      Called if a new power event has started.
 @param         event A reference to the MTPowerEvent instance that has started.
*/
- (void)powerEventDidStart:(MTPowerEvent*)event;

/*!
 @method        powerEventDidEnd:
 @abstract      Called if a power event has ended.
 @param         event A reference to the MTPowerEvent instance that has ended.
*/
- (void)powerEventDidEnd:(MTPowerEvent*)event;

/*!
 @method        powerEvent:willChangeType:
 @abstract      Called if the type of a power event will change.
 @param         event A reference to the MTPowerEvent instance that will change.
 @param         type The new type of the power event.
*/
- (void)powerEvent:(MTPowerEvent*)event willChangeType:(MTPowerEventType)type;

@end

/*!
 @class         MTSleepWatcher
 @abstract      This class defines a power event.
*/

@interface MTSleepWatcher : NSObject

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithDelegate: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithDelegate:
 @abstract      Initialize a MTSleepWatcher object with a given delegate.
 @param         delegate The receiver's delegate. The value of this property is an object
                conforming to the MTSleepWatcherDelegate protocol.
 @discussion    Returns an initialized MTSleepWatcher object.
*/
- (instancetype)initWithDelegate:(id<MTSleepWatcherDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/*!
 @method        startWatching
 @abstract      Starts watching for sleep/wake events.
 @discussion    Returns YES if watching has been started successfully, otherwise returns NO.
*/
- (BOOL)startWatching;

/*!
 @method        stopWatching
 @abstract      Stops watching for sleep/wake events.
 @discussion    Returns YES if watching has been stopped successfully, otherwise returns NO.
*/
- (BOOL)stopWatching;

/*!
 @method        currentEvent
 @abstract      Returns the current event.
*/
- (MTPowerEvent*)currentEvent;

@end
