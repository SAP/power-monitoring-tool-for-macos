/*
     MTPowerMeasurementArray.m
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

#import "MTPowerMeasurementArray.h"
#import "MTElectricityPrice.h"
#import "Constants.h"

@implementation NSArray (MTPowerMeasurementArray)

- (MTPowerMeasurement*)minimumPower
{
    NSNumber *minimum = 0;
    
    if ([self count] > 0) {
        minimum = [self valueForKeyPath:@"@min.doubleValue"];
    }
 
    MTPowerMeasurement *measurement = [[MTPowerMeasurement alloc] initWithPowerValue:[minimum doubleValue]];
    
    return measurement;
}

- (MTPowerMeasurement*)averagePower
{
    NSNumber *average = 0;
    
    if ([self count] > 0) {
        average = [self valueForKeyPath:@"@avg.doubleValue"];
    }
 
    MTPowerMeasurement *measurement = [[MTPowerMeasurement alloc] initWithPowerValue:[average doubleValue]];
    
    return measurement;
}

- (MTPowerMeasurement*)maximumPower
{
    NSNumber *maximum = 0;
    
    if ([self count] > 0) {
        maximum = [self valueForKeyPath:@"@max.doubleValue"];
    }
 
    MTPowerMeasurement *measurement = [[MTPowerMeasurement alloc] initWithPowerValue:[maximum doubleValue]];
    
    return measurement;
}

- (NSArray<MTPowerMeasurement*>*)awakeMeasurements
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"darkWake == %@", [NSNumber numberWithBool:NO]];
    NSArray *awakeMeasurements = [self filteredArrayUsingPredicate:predicate];
    
    return awakeMeasurements;
}

- (NSArray<MTPowerMeasurement*>*)powerNapMeasurements
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"darkWake == %@", [NSNumber numberWithBool:YES]];
    NSArray *powerNapMeasurements = [self filteredArrayUsingPredicate:predicate];
    
    return powerNapMeasurements;
}

- (NSTimeInterval)totalTime
{
    NSTimeInterval total = [self count] * kMTMeasurementInterval;
    
    return total;
}

- (NSDictionary*)measurementsGroupedByDay
{
    NSDate *anchorDate = [NSDate distantPast];
    NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *groupedEntries = [[NSMutableArray alloc] init];
    
    for (MTPowerMeasurement *pM in self) {
        
        NSDate *measurementDate = [NSDate dateWithTimeIntervalSince1970:[pM timeStamp]];
        
        if ([[NSCalendar currentCalendar] compareDate:anchorDate
                                               toDate:measurementDate
                                    toUnitGranularity:NSCalendarUnitDay] != NSOrderedSame) {
        
            if ([groupedEntries count] > 0) {
                
                [groupedDict setObject:groupedEntries forKey:[NSString stringWithFormat:@"%.0lf", [anchorDate timeIntervalSince1970]]];
                groupedEntries = [[NSMutableArray alloc] init];
            }

            anchorDate = [[NSCalendar currentCalendar] startOfDayForDate:measurementDate];
        }

        [groupedEntries addObject:pM];
    }
    
    if ([groupedEntries count] > 0) {
        
        [groupedDict setObject:groupedEntries forKey:[NSString stringWithFormat:@"%.0lf", [anchorDate timeIntervalSince1970]]];
    }
    
    return groupedDict;
}

@end
