/*
     MTPowerJournalEntry.m
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

#import "MTPowerJournalEntry.h"
#import <objc/runtime.h>

@interface MTPowerJournalEntry ()
@property (assign) NSTimeInterval timeStamp;
@end

@implementation MTPowerJournalEntry

- (instancetype)initWithTimeIntervalSince1970:(NSTimeInterval)interval
{
    self = [super init];
    
    if (self) {
        
        if (interval) {
            
            NSDate *startOfDay = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate dateWithTimeIntervalSince1970:interval]];
            _timeStamp = [startOfDay timeIntervalSince1970];
            
        } else {
            
            self = nil;
        }
    }
    
    return self;
}

- (NSDictionary*)dictionaryRepresentation
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    unsigned count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    if (properties) {
        
        for (int i = 0; i < count; i++) {
            
            NSString *propertyKey = [NSString stringWithUTF8String:property_getName(properties[i])];
            [dict setObject:([self valueForKey:propertyKey]) ? [self valueForKey:propertyKey] : @""
                     forKey:propertyKey
            ];
        }
        
        free(properties);
    }

    return dict;
}

- (NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *string = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_timeStamp]];
    
    return string;
}

- (NSString*)durationStringAwake
{
    return [self durationStringWithTimeInterval:_durationAwake];
}

- (NSString*)durationStringAltTariff
{
    return [self durationStringWithTimeInterval:_durationAltTariff];
}

- (NSString*)durationStringPowerNap
{
    return [self durationStringWithTimeInterval:_durationPowerNap];
}

- (NSString*)durationStringSleep
{
    return [self durationStringWithTimeInterval:86400 - _durationPowerNap - _durationAwake];
}

- (NSString*)durationStringWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponentsFormatter *durationFormatter = [[NSDateComponentsFormatter alloc] init];
    [durationFormatter setAllowedUnits:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)];
    [durationFormatter setZeroFormattingBehavior:NSDateComponentsFormatterZeroFormattingBehaviorPad];

    NSString *durationString = [durationFormatter stringFromTimeInterval:timeInterval];
    
    return durationString;
}

- (NSString*)consumptionStringAwake
{
    return [self consumptionStringWithMeasurementType:MTJournalEntryEventTypeAwake fractionDigits:6];
}

- (NSString*)consumptionStringAltTariff
{
    return [self consumptionStringWithMeasurementType:MTJournalEntryEventTypeAltTariff fractionDigits:6];
}

- (NSString*)consumptionStringPowerNap
{
    return [self consumptionStringWithMeasurementType:MTJournalEntryEventTypePowerNap fractionDigits:6];
}

- (NSString*)consumptionStringTotal
{
    return [self consumptionStringWithMeasurementType:MTJournalEntryEventTypeAll fractionDigits:6];
}

- (NSString*)consumptionStringWithMeasurementType:(MTJournalEntryEventType)type fractionDigits:(NSInteger)digits
{
    double value = 0;
    
    switch (type) {
            
        case MTJournalEntryEventTypeAll:
            value = [self consumptionTotalInKWh];
            break;
            
        case MTJournalEntryEventTypePowerNap:
            value = [self consumptionPowerNapInKWh];
            break;
            
        case MTJournalEntryEventTypeAwake:
            value = [self consumptionAwakeInKWh];
            break;
            
        case MTJournalEntryEventTypeAltTariff:
            value = [self consumptionAltTariffInKWh];
            break;
            
        default:
            break;
    }
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy kilowattHours]];
    
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:digits];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:digits];
    [powerFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale | NSMeasurementFormatterUnitOptionsProvidedUnit];
    
    NSString *measurementString = [powerFormatter stringFromMeasurement:powerConsumption];
    
    return measurementString;
}

- (double)consumptionTotalInKWh
{
    double value = _consumptionTotal * (_durationAwake + _durationPowerNap);
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

- (double)consumptionAltTariffInKWh
{
    double value = _consumptionAltTariff * _durationAltTariff;
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

- (double)consumptionPowerNapInKWh
{
    double value = _consumptionPowerNap * _durationPowerNap;
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

- (double)consumptionAwakeInKWh
{
    double value = (_consumptionTotal - _consumptionPowerNap) * _durationAwake;
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:value unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    return [powerConsumption doubleValue];
}

+ (MTPowerJournalEntry*)entryWithDictionary:(NSDictionary*)dictionary
{
    MTPowerJournalEntry *entry = nil;
    
    if ([[dictionary allKeys] count] > 0) {
        
        NSTimeInterval interval = [[dictionary valueForKey:@"timeStamp"] doubleValue];
        
        if (interval > 0) {
            
            entry = [[MTPowerJournalEntry alloc] initWithTimeIntervalSince1970:interval];
            [entry setDurationAwake:[[dictionary valueForKey:@"durationAwake"] doubleValue]];
            [entry setConsumptionTotal:[[dictionary valueForKey:@"consumptionTotal"] doubleValue]];
            [entry setDurationAltTariff:[[dictionary valueForKey:@"durationAltTariff"] doubleValue]];
            [entry setConsumptionAltTariff:[[dictionary valueForKey:@"consumptionAltTariff"] doubleValue]];
            [entry setDurationPowerNap:[[dictionary valueForKey:@"durationPowerNap"] doubleValue]];
            [entry setConsumptionPowerNap:[[dictionary valueForKey:@"consumptionPowerNap"] doubleValue]];
        }
    }
    
    return entry;
}

@end
