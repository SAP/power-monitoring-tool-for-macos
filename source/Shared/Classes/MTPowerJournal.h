/*
     MTPowerJournal.h
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
#import "MTPowerJournalEntry.h"

@interface MTPowerJournal : NSObject

/*!
 @enum          MTJournalExportFileType
 @abstract      Specifies the file format of the export file.
 @constant      MTJournalExportFileTypeCSV Specifies the CSV file format.
 @constant      MTJournalExportFileTypeJSON Specifies the JSON file format.
*/
typedef enum {
    MTJournalExportFileTypeCSV  = 0,
    MTJournalExportFileTypeJSON = 1
} MTJournalExportFileType;

/*!
 @property      allEntries
 @abstract      A property that holds all entries of the journal.
 @discussion    The value of this property NSArray.
*/
@property (nonatomic, strong, readwrite) NSMutableArray *allEntries;

/*!
 @property      filePath
 @abstract      A read-only property that returns the path to the journal file.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readonly) NSString *filePath;

/*!
 @method        init:
 @discussion    The init method is not available. Please use initWithFileAtPath: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithFileAtPath:
 @abstract      Initialize a MTPowerJournal object with a given file path.
 @param         path The path to the journal file.
 @discussion    Returns a MTPowerJournal object initialized with the contents of the journal file at the given path.
*/
- (instancetype)initWithFileAtPath:(NSString*)path NS_DESIGNATED_INITIALIZER;

/*!
 @method        entryWithTimeStamp:
 @abstract      Returns the journal entry with the given timestamp.
 @param         timestamp The timestamp of the journal entry.
 @discussion    Returns a MTPowerJournalEntry object or nil if the entry does not exist.
*/
- (MTPowerJournalEntry*)entryWithTimeStamp:(NSTimeInterval)timestamp;

/*!
 @method        synchronize
 @abstract      Writes the power journal into a plist file.
 @discussion    Returns YES on success, otherwise returns NO.
*/
- (BOOL)synchronize;

/*!
 @method        consumptionTotalInKWhWithEntries:
 @abstract      Returns the total power consumption in KWh for the given journal entries.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (double)consumptionTotalInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        consumptionAwakeInKWhWithEntries:
 @abstract      Returns the power consumption in KWh for the time the Mac was awake for the given journal entries.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (double)consumptionAwakeInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        consumptionPowerNapInKWhWithEntries:
 @abstract      Returns the power consumption in KWh for the time the Mac took Power Naps for the given journal entries.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (double)consumptionPowerNapInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        consumptionStringTotalWithEntries:
 @abstract      Returns the total power consumption in KWh for the given journal entries as string.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (NSString*)consumptionStringTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        consumptionStringAwakeWithEntries:
 @abstract      Returns the power consumption in KWh for the time the Mac was awake for the given journal entries as string.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (NSString*)consumptionStringAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        consumptionStringPowerNapWithEntries:
 @abstract      Returns the power consumption in KWh for the time the Mac took Power Naps for the given journal entries as string.
 @param         entries An array of journal entries to calculate the power consumption from.
*/
+ (NSString*)consumptionStringPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationTotalWithEntries:
 @abstract      Returns the total duration of all power events (in seconds) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSTimeInterval)durationTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationAwakeWithEntries:
 @abstract      Returns the total duration of power events the Mac was awake (in seconds) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSTimeInterval)durationAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationPowerNapWithEntries:
 @abstract      Returns the total duration of power events the Mac took a Power Nap (in seconds) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSTimeInterval)durationPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationStringTotalWithEntries:
 @abstract      Returns the total duration of all power events (as string with format hh:mm:ss) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSString*)durationStringTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationStringAwakeWithEntries:
 @abstract      Returns the total duration of power events the Mac was awake (as string with format hh:mm:ss) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSString*)durationStringAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        durationStringPowerNapWithEntries:
 @abstract      Returns the total duration of power events the Mac took a Power Nap (as string with format hh:mm:ss) for the given journal entries.
 @param         entries An array of journal entries to calculate the duration from.
*/
+ (NSString*)durationStringPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries;

/*!
 @method        journalEntries:summarizedBy:
 @abstract      Returns a dictionary of journal entries summarized by the given calendar unit.
 @param         entries An array of journal entries to summarize.
 @param         unit The NSCalendarUnit the entries should be summarized by.
*/
+ (NSDictionary*)journalEntries:(NSArray<MTPowerJournalEntry*>*)entries summarizedBy:(NSCalendarUnit)unit;

/*!
 @method        csvStringWithEntries:summarizedBy:includeDuration:addHeader:
 @abstract      Returns the given journal entries as a csv string.
 @param         entries An array of journal entries.
 @param         unit The NSCalendarUnit the entries should be summarized by. If set to 0, then entries will not be summarized.
 @param         duration A boolean specifying if the duration of the power events should be included or not.
 @param         header A boolean specifying if a csv header should be added or not.
*/
+ (NSString*)csvStringWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
                     summarizedBy:(NSCalendarUnit)unit
                  includeDuration:(BOOL)duration
                        addHeader:(BOOL)header;
/*!
 @method        jsonStringWithEntries:summarizedBy:includeDuration:
 @abstract      Returns the given journal entries as a json string.
 @param         entries An array of journal entries.
 @param         unit The NSCalendarUnit the entries should be summarized by. If set to 0, then entries will not be summarized.
 @param         duration A boolean specifying if the duration of the power events should be included or not.
*/
+ (NSString*)jsonStringWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
                      summarizedBy:(NSCalendarUnit)unit
                   includeDuration:(BOOL)duration;

@end
