/*
     MTPowerJournalEntry.h
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

@interface MTPowerJournalEntry : NSObject

/*!
 @enum          MTJournalEntryEventType
 @abstract      Specifies the type of event a journal entry belongs to.
 @constant      MTJournalEntryEventTypeAll Specifies all power events.
 @constant      MTJournalEntryEventTypeAwake Specifies an event where the Mac was awake.
 @constant      MTJournalEntryEventTypePowerNap Specifies a Power Nap event.
 @constant      MTJournalEntryEventTypeAltTariff Specifies an event where the alternative electricity tariff was active.
*/
typedef enum {
    MTJournalEntryEventTypeAll       = 0,
    MTJournalEntryEventTypeAwake     = 1,
    MTJournalEntryEventTypePowerNap  = 2,
    MTJournalEntryEventTypeAltTariff = 3
} MTJournalEntryEventType;

/*!
 @property      timeStamp
 @abstract      A read-only property that holds the timestamp of the journal entry.
 @discussion    The value of this property NSTimeInterval.
*/
@property (readonly) NSTimeInterval timeStamp;

/*!
 @property      durationAwake
 @abstract      A property to store the duration the machine was awake.
 @discussion    The value of this property NSTimeInterval.
*/
@property (assign) NSTimeInterval durationAwake;

/*!
 @property      durationAltTariff
 @abstract      A property to store the duration the machine used the alternative electricity tariff.
 @discussion    The value of this property NSTimeInterval.
*/
@property (assign) NSTimeInterval durationAltTariff;

/*!
 @property      durationPowerNap
 @abstract      A property to store the duration the machine took Power Naps.
 @discussion    The value of this property NSTimeInterval.
*/
@property (assign) NSTimeInterval durationPowerNap;

/*!
 @property      consumptionTotal
 @abstract      A property to store the total power the machine consumed.
 @discussion    The value of this property double. The stored value specifies the average
                power the machine consumed during the total time represented by the
                journal entry (durationAwake + durationPowerNap).
*/
@property (assign) double consumptionTotal;

/*!
 @property      consumptionPowerNap
 @abstract      A property to store the power the machine consumed during Power Naps.
 @discussion    The value of this property double. The stored value specifies the average
                power the machine consumed during Power Nap.
*/
@property (assign) double consumptionPowerNap;

/*!
 @property      consumptionAltTariff
 @abstract      A property to store the power the machine consumed during while the alternative
                electricity tariff was active.
 @discussion    The value of this property double. The stored value specifies the average
                power the machine consumed while the alternative electricity tariff was active.
*/
@property (assign) double consumptionAltTariff;

/*!
 @method        init:
 @discussion    The init method is not available. Please use initWithTimeIntervalSince1970: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithTimeIntervalSince1970:
 @abstract      Initialize a MTPowerJournalEntry object with a given timestamp.
 @param         interval The timestamp for the journal entry.
 @discussion    Returns a MTPowerJournalEntry object initialized with the given timestamp.
*/
- (instancetype)initWithTimeIntervalSince1970:(NSTimeInterval)interval NS_DESIGNATED_INITIALIZER;

/*!
 @method        dictionaryRepresentation
 @abstract      Returns a dictionary representation of the MTPowerJournalEntry object.
*/
- (NSDictionary*)dictionaryRepresentation;

/*!
 @method        consumptionAwakeInKWh
 @abstract      Returns the power consuption for the MTPowerJournalEntry object in KWh for the time the Mac was awake.
*/
- (double)consumptionAwakeInKWh;

/*!
 @method        consumptionAltTariffInKWh
 @abstract      Returns the power consuption for the MTPowerJournalEntry object in KWh for the time the alternative electricity tariff was active.
*/
- (double)consumptionAltTariffInKWh;

/*!
 @method        consumptionPowerNapInKWh
 @abstract      Returns the power consuption for the MTPowerJournalEntry object in KWh for the time the Mac took Power Naps.
*/
- (double)consumptionPowerNapInKWh;

/*!
 @method        consumptionTotalInKWh
 @abstract      Returns the total power consuption for the MTPowerJournalEntry object in KWh.
*/
- (double)consumptionTotalInKWh;

/*!
 @method        dateString
 @abstract      Returns the date string for the MTPowerJournalEntry object.
*/
- (NSString*)dateString;

/*!
 @method        durationStringAwake
 @abstract      Returns the duration of the MTPowerJournalEntry object as string, where the Mac was awake.
*/
- (NSString*)durationStringAwake;

/*!
 @method        durationStringAltTariff
 @abstract      Returns the duration of the MTPowerJournalEntry object as string, where the alternative electricity tariff was active.
*/
- (NSString*)durationStringAltTariff;

/*!
 @method        durationStringPowerNap
 @abstract      Returns the duration of the MTPowerJournalEntry object as string, where the Mac took Power Naps.
*/
- (NSString*)durationStringPowerNap;

/*!
 @method        durationStringSleep
 @abstract      Returns the duration of the MTPowerJournalEntry object as string, where the Mac was sleeping.
*/
- (NSString*)durationStringSleep;

/*!
 @method        consumptionStringAwake
 @abstract      Returns the power consumption for the MTPowerJournalEntry object as string (in KWh), where the Mac was awake.
*/
- (NSString*)consumptionStringAwake;

/*!
 @method        consumptionStringAltTariff
 @abstract      Returns the power consumption for the MTPowerJournalEntry object as string (in KWh), where the alternative electricity tariff was active.
*/
- (NSString*)consumptionStringAltTariff;

/*!
 @method        consumptionStringPowerNap
 @abstract      Returns the power consumption for the MTPowerJournalEntry object as string (in KWh), where the Mac took Power Naps.
*/
- (NSString*)consumptionStringPowerNap;

/*!
 @method        consumptionStringTotal
 @abstract      Returns the total power consumption for the MTPowerJournalEntry object as string (in KWh).
*/
- (NSString*)consumptionStringTotal;

/*!
 @method        entryWithDictionary:
 @abstract      Initialize a MTPowerJournalEntry object with a given dictionary.
 @param         dictionary A dictionary containing the information for the journal entry.
 @discussion    Returns a MTPowerJournalEntry object initialized with the given dictionary.
*/
+ (MTPowerJournalEntry*)entryWithDictionary:(NSDictionary*)dictionary;

@end
