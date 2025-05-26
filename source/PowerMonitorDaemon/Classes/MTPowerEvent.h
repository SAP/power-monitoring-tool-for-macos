/*
     MTPowerEvent.h
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
#import "IOPMLibPrivate.h"

/*!
 @class         MTPowerEvent
 @abstract      This class defines a power event.
*/

@interface MTPowerEvent : NSObject

/*!
 @enum          MTPowerEventType
 @abstract      Specifies a power measurement, containing of the measured value and a timestamp.
 @constant      MTPowerEventTypeNone
 @constant      MTPowerEventTypeSleep Specifies a sleep event.
 @constant      MTPowerEventTypeDarkWake Specifies a dark wake event.
 @constant      MTPowerEventTypeUserWake Specifies a user wake event.
*/
typedef enum {
    MTPowerEventTypeNone     = 0,
    MTPowerEventTypeSleep    = 1,
    MTPowerEventTypeDarkWake = 2,
    MTPowerEventTypeUserWake = 3
} MTPowerEventType;

/*!
 @property      type
 @abstract      A property to store event type.
 @discussion    The value of this property is MTPowerEventType.
*/
@property (assign) MTPowerEventType type;

/*!
 @property      startDate
 @abstract      A property to store the event's start date.
 @discussion    The value of this property is NSDate.
*/
@property (nonatomic, strong, readonly) NSDate *startDate;

/*!
 @property      type
 @abstract      A property to store the event's end date.
 @discussion    The value of this property is NSDate.
*/
@property (nonatomic, strong, readonly) NSDate *endDate;

/*!
 @method        endEvent
 @abstract      End the event by setting the receiver's end date.
*/
- (void)endEvent;

/*!
 @method        duration
 @abstract      Returns the durantion of the event.
 @discussion    If the event is still active, the time interval between the event start date and the current date
                is returned, otherwise the time interval between start and end date is returned.
*/
- (NSTimeInterval)duration;

/*!
 @method        didEnd
 @abstract      Returns if an event has ended or not.
 @discussion    Returns YES if the event has ended, otherwise returns NO.
*/
- (BOOL)didEnd;

/*!
 @method        eventTypeWithCapabilities:
 @abstract      Returns the MTPowerEventType for the given IOPMSystemPowerStateCapabilities.
 @param         capabilities The IOPMSystemPowerStateCapabilities.
*/
+ (MTPowerEventType)eventTypeWithCapabilities:(IOPMSystemPowerStateCapabilities)capabilities;

@end

