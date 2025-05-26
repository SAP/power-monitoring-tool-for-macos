/*
     MTPowerJournal.m
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

#import "MTPowerJournal.h"

@interface MTPowerJournal ()
@property (nonatomic, strong, readwrite) NSString *filePath;
@end

@implementation MTPowerJournal

- (instancetype)initWithFileAtPath:(NSString *)path
{
    self = [super init];
    
    if (self) {
        
        BOOL success = NO;
        
        NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithShort:0777], NSFilePosixPermissions,
                                        @"staff", NSFileGroupOwnerAccountName,
                                        nil];
        
        if ([[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES
                                                       attributes:attributesDict
                                                            error:nil
            ]) {
            
            NSArray *journal = [NSArray arrayWithContentsOfFile:path];
            
            if (journal) {
                
                // we have to convert our entries back to
                // MTPowerJournalEntry objects
                __block NSMutableArray *convertedJournal = [[NSMutableArray alloc] init];
                
                [journal enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [convertedJournal addObject:[MTPowerJournalEntry entryWithDictionary:obj]];
                    }
                }];
                
                _allEntries = [NSMutableArray arrayWithArray:convertedJournal];
                
            } else {
                
                _allEntries = [[NSMutableArray alloc] init];
            }

            _filePath = path;
            
            success = YES;
        }
        
        if (!success) { self = nil; }
    }
    
    return self;
}

- (MTPowerJournalEntry *)entryWithTimeStamp:(NSTimeInterval)timestamp
{
    MTPowerJournalEntry *journalEntry = nil;
    
    if (timestamp) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp == %lf", timestamp];
        NSArray *filteredArray = [_allEntries filteredArrayUsingPredicate:predicate];
        
        if ([filteredArray count] == 1) {
            
            journalEntry = [filteredArray firstObject];
        }
    }
    
    return journalEntry;
}

- (BOOL)synchronize
{
    // to make the journal better readable (e.g. for scripts),
    // we decided not to use NSArchiver but to convert our
    // MTPowerJournalEntry object into objects that can be
    // written to a plist file.
    __block NSMutableArray *convertedJournal = [[NSMutableArray alloc] init];
    
    [_allEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[MTPowerJournalEntry class]]) {
            
            NSDictionary *convertedEntry = [obj dictionaryRepresentation];
            [convertedJournal addObject:convertedEntry];
        }
    }];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:YES];
    NSArray *sortedJournal = [convertedJournal sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    
    BOOL success = [sortedJournal writeToFile:_filePath atomically:YES];
    
    if (success) {
        
        NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithShort:0666], NSFilePosixPermissions,
                                        @"staff", NSFileGroupOwnerAccountName,
                                        nil];
        
        success = [[NSFileManager defaultManager] setAttributes:attributesDict ofItemAtPath:_filePath error:nil];
    }

    return success;
}

#pragma mark class methods

+ (NSString*)consumptionStringTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self consumptionStringWithValue:[self consumptionTotalInKWhWithEntries:entries] fractionDigits:3];
}

+ (NSString*)consumptionStringAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self consumptionStringWithValue:[self consumptionAwakeInKWhWithEntries:entries] fractionDigits:3];
}

+ (NSString*)consumptionStringPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self consumptionStringWithValue:[self consumptionPowerNapInKWhWithEntries:entries] fractionDigits:3];
}

+ (NSString*)consumptionStringAltTariffWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self consumptionStringWithValue:[self consumptionAltTariffInKWhWithEntries:entries] fractionDigits:3];
}

+ (NSString*)consumptionStringWithValue:(double)value fractionDigits:(NSInteger)digits
{
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy kilowattHours]];

    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:digits];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:digits];
    [powerFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale | NSMeasurementFormatterUnitOptionsProvidedUnit];

    return [powerFormatter stringFromMeasurement:powerConsumption];
}

+ (double)consumptionTotalInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    double value = [self consumptionWithEntries:entries entryType:MTJournalEntryEventTypeAll];
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

+ (double)consumptionAltTariffInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    double value = [self consumptionWithEntries:entries entryType:MTJournalEntryEventTypeAltTariff];
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

+ (double)consumptionAwakeInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    double value = [self consumptionWithEntries:entries entryType:MTJournalEntryEventTypeAwake];
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

+ (double)consumptionPowerNapInKWhWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    double value = [self consumptionWithEntries:entries entryType:MTJournalEntryEventTypePowerNap];
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

+ (double)consumptionWithEntries:(NSArray<MTPowerJournalEntry*>*)entries entryType:(MTJournalEntryEventType)type
{
    double consumptionTotal = 0;

    for (MTPowerJournalEntry *journalEntry in entries) {
        
        switch (type) {
                
            case MTJournalEntryEventTypeAll:
                consumptionTotal += [journalEntry consumptionTotal] * ([journalEntry durationAwake] + [journalEntry durationPowerNap]);
                break;
                
            case MTJournalEntryEventTypePowerNap:
                consumptionTotal += [journalEntry consumptionPowerNap] * [journalEntry durationPowerNap];
                break;
                
            case MTJournalEntryEventTypeAwake:
                consumptionTotal += ([journalEntry consumptionTotal] - [journalEntry consumptionPowerNap]) * [journalEntry durationAwake];
                break;
                
            case MTJournalEntryEventTypeAltTariff:
                consumptionTotal += [journalEntry consumptionAltTariff] * ([journalEntry durationAwake] + [journalEntry durationPowerNap]);
                break;
                
            default:
                break;
        }
    }
    
    return consumptionTotal;
}

+ (NSString*)durationStringTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    NSTimeInterval duration = [self durationTotalWithEntries:entries];
    return [self durationStringWithTimeInterval:duration];
}

+ (NSString*)durationStringAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    NSTimeInterval duration = [self durationAwakeWithEntries:entries];
    return [self durationStringWithTimeInterval:duration];
}

+ (NSString*)durationStringPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    NSTimeInterval duration = [self durationPowerNapWithEntries:entries];
    return [self durationStringWithTimeInterval:duration];
}

+ (NSString*)durationStringAltTariffWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    NSTimeInterval duration = [self durationAltTariffWithEntries:entries];
    return [self durationStringWithTimeInterval:duration];
}

+ (NSString*)durationStringWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponentsFormatter *durationFormatter = [[NSDateComponentsFormatter alloc] init];
    [durationFormatter setAllowedUnits:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)];
    [durationFormatter setZeroFormattingBehavior:NSDateComponentsFormatterZeroFormattingBehaviorPad];

    NSString *durationString = [durationFormatter stringFromTimeInterval:timeInterval];
    
    return durationString;
}

+ (NSTimeInterval)durationTotalWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self durationWithEntries:entries entryType:MTJournalEntryEventTypeAll];
}

+ (NSTimeInterval)durationAwakeWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self durationWithEntries:entries entryType:MTJournalEntryEventTypeAwake];
}

+ (NSTimeInterval)durationPowerNapWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self durationWithEntries:entries entryType:MTJournalEntryEventTypePowerNap];
}

+ (NSTimeInterval)durationAltTariffWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
{
    return [self durationWithEntries:entries entryType:MTJournalEntryEventTypeAltTariff];
}

+ (NSTimeInterval)durationWithEntries:(NSArray<MTPowerJournalEntry*>*)entries entryType:(MTJournalEntryEventType)type
{
    NSTimeInterval durationTotal = 0;

    for (MTPowerJournalEntry *journalEntry in entries) {
        
        switch (type) {
                
            case MTJournalEntryEventTypeAll:
                durationTotal += [journalEntry durationAwake] + [journalEntry durationPowerNap];
                break;
                
            case MTJournalEntryEventTypePowerNap:
                durationTotal += [journalEntry durationPowerNap];
                break;
                
            case MTJournalEntryEventTypeAwake:
                durationTotal += [journalEntry durationAwake];
                break;
                
            case MTJournalEntryEventTypeAltTariff:
                durationTotal += [journalEntry durationAltTariff];
                break;
                
            default:
                break;
        }
    }

    return durationTotal;
}

+ (NSArray<MTPowerJournalEntry*>*)journalEntries:(NSArray<MTPowerJournalEntry*>*)entries
                                    summarizedBy:(NSCalendarUnit)unit
{
    NSMutableArray *summarizedEntries = [[NSMutableArray alloc] init];
    
    if (unit > 0) {
        
        if (entries) {
            
            // split the entries an separate arrays
            // matching the given NSCalendarUnit
            NSDate *anchorDate = [NSDate distantPast];
            NSMutableArray *groupedEntries = [[NSMutableArray alloc] init];
            NSMutableArray *groupedEntriesContainer = [[NSMutableArray alloc] init];
            
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:YES];
            NSArray *sortedEntries = [entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
            
            for (MTPowerJournalEntry *entry in sortedEntries) {
                
                NSDate *measurementDate = [NSDate dateWithTimeIntervalSince1970:[entry timeStamp]];
                
                if ([[NSCalendar currentCalendar] compareDate:anchorDate
                                                       toDate:[NSDate dateWithTimeIntervalSince1970:[entry timeStamp]]
                                            toUnitGranularity:unit] != NSOrderedSame) {
                    
                    if ([groupedEntries count] > 0) {
                        
                        [groupedEntriesContainer addObject:groupedEntries];
                        groupedEntries = [[NSMutableArray alloc] init];
                    }
                    
                    anchorDate = [[NSCalendar currentCalendar] startOfDayForDate:measurementDate];
                }
                
                [groupedEntries addObject:entry];
            }
            
            if ([groupedEntries count] > 0) {
                
                [groupedEntriesContainer addObject:groupedEntries];
            }
            
            // loop through the arrays, calculate the totals
            // and create a journal entry per array
            for (NSArray *entriesArray in groupedEntriesContainer) {
                                
                if ([entriesArray count] > 0) {
                    
                    NSDate *entryDate = [NSDate dateWithTimeIntervalSince1970:[[entriesArray firstObject] timeStamp]];
                    NSCalendarUnit relevantComponents = unit;
                    
                    switch (unit) {
                        case NSCalendarUnitWeekOfYear:
                            relevantComponents = (NSCalendarUnitWeekOfYear | NSCalendarUnitYearForWeekOfYear);
                            break;
                            
                        case NSCalendarUnitMonth:
                            relevantComponents = (NSCalendarUnitYear | NSCalendarUnitMonth);
                            break;
                            
                        case NSCalendarUnitYear:
                            relevantComponents = NSCalendarUnitYear;
                            break;
                            
                        default:
                            break;
                    }
                    
                    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:relevantComponents fromDate:entryDate];
                    NSDate *anchorDate = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
                    
                    double energyTotal = [self consumptionWithEntries:entriesArray entryType:MTJournalEntryEventTypeAll];
                    double energyPowerNap = [self consumptionWithEntries:entriesArray entryType:MTJournalEntryEventTypePowerNap];
                    double durationAwake = [self durationAwakeWithEntries:entriesArray];
                    double durationPowernap = [self durationPowerNapWithEntries:entriesArray];
                    
                    energyTotal = energyTotal / (durationAwake + durationPowernap);
                    energyPowerNap = (durationPowernap > 0) ? energyPowerNap / durationPowernap : 0;
                    
                    MTPowerJournalEntry *entry = [[MTPowerJournalEntry alloc] initWithTimeIntervalSince1970:[anchorDate timeIntervalSince1970]];
                    [entry setConsumptionTotal:energyTotal];
                    [entry setConsumptionPowerNap:energyPowerNap];
                    [entry setDurationAwake:durationAwake];
                    [entry setDurationPowerNap:durationPowernap];
                    [summarizedEntries addObject:entry];
                }
            }
        }
    }
    
    return (unit > 0) ? summarizedEntries : entries;
}

+ (NSString*)csvStringWithEntries:(NSArray<MTPowerJournalEntry*>*)entries
                     summarizedBy:(NSCalendarUnit)unit
                  includeDuration:(BOOL)duration
                    addHeader:(BOOL)header
{
    NSMutableString *csvString = [[NSMutableString alloc] init];
    
    if (header) {
        
        if (duration) {
            [csvString appendString:@"Date,Consumption Total (kWh),Consumption Power Nap (kWh),Duration Awake,Duration Power Nap\r\n"];
        } else {
            [csvString appendString:@"Date,Consumption Total (kWh),Consumption Power Nap (kWh)\r\n"];
        }
    }

    for (MTPowerJournalEntry *entry in [self journalEntries:entries summarizedBy:unit]) {

        NSMutableString *csvEntryString = [NSMutableString stringWithFormat:@"%@,%@,%@",
                                           [entry dateString],
                                           [NSNumber numberWithDouble:[entry consumptionTotalInKWh]],
                                           [NSNumber numberWithDouble:[entry consumptionPowerNapInKWh]]
        ];
        
        if (duration) {
            [csvEntryString appendFormat:@",%@,%@", [entry durationStringAwake], [entry durationStringPowerNap]];
        }
        
        [csvEntryString appendString:@"\r\n"];
        [csvString appendString:csvEntryString];
    }
        
    return csvString;
}

+ (NSString*)jsonStringWithEntries:(NSArray<MTPowerJournalEntry*>*)entries 
                      summarizedBy:(NSCalendarUnit)unit
                   includeDuration:(BOOL)duration
{
    NSError *error = nil;
    NSString *jsonString = @"";
    NSMutableArray *processedEntries = [[NSMutableArray alloc] init];
    
    for (MTPowerJournalEntry *entry in [self journalEntries:entries summarizedBy:unit]) {
        
        NSMutableDictionary *entryDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [entry dateString], @"Date",
                                   [NSNumber numberWithDouble:[entry consumptionTotalInKWh]], @"Consumption Total (kWh)",
                                   [NSNumber numberWithDouble:[entry consumptionPowerNapInKWh]], @"Consumption Power Nap (kWh)",
                                   nil
        ];
        
        if (duration) {
            
            [entryDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [entry durationStringAwake], @"Duration Awake",
                                                    [entry durationStringPowerNap], @"Duration Power Nap",
                                                    nil
                                                ]
            ];
        }
        
        [processedEntries addObject:entryDict];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:processedEntries
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error
    ];
    
    if (!error) { jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]; }
    
    return jsonString;
}

@end
