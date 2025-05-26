/*
     MTElectricityPrice.m
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

#import "MTElectricityPrice.h"

@interface MTElectricityPrice ()
@property (nonatomic, strong, readwrite) NSDictionary *savedSchedule;
@property (assign) double regularPrice;
@property (assign) double altPrice;
@end

@implementation MTElectricityPrice

- (instancetype)initWithRegularPrice:(double)regular
                    alternativePrice:(double)alternative
                            schedule:(NSDictionary*)schedule
{
    self = [super init];
    
    if (self) {
        
        _regularPrice = regular;
        _altPrice = alternative;
        _savedSchedule = schedule;
    }
    
    return self;
}

- (double)priceAtDate:(NSDate*)date
{
    double pricePerKWh = -1;

    if (date) {        
        pricePerKWh = ([self isAlternatePriceWithDate:date]) ? _altPrice : _regularPrice;
    }

    return pricePerKWh;
}

- (BOOL)isAlternatePriceWithDate:(NSDate*)date
{
    BOOL isAlternate = NO;
    
    // check if the given date lies in one of the alternative price ranges
    if (_savedSchedule) {
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSInteger dayOfTheWeek = [calendar component:NSCalendarUnitWeekday fromDate:date];
        NSInteger index = dayOfTheWeek - 1;
        
        NSArray *idxSet = [_savedSchedule objectForKey:[NSString stringWithFormat:@"%ld", index]];
        NSDateComponents *timeComponents = [calendar components:NSCalendarUnitHour fromDate:date];
        
        isAlternate = ([idxSet containsObject:[NSNumber numberWithInteger:[timeComponents hour]]]);
    }
    
    return isAlternate;
}

- (NSArray<MTPowerMeasurement*>*)measurementsInAltTariffWithArray:(NSArray<MTPowerMeasurement*>*)measurements
{
    NSMutableArray *usingAltTariff = [[NSMutableArray alloc] init];
        
    for (MTPowerMeasurement *pM in measurements) {
        
        if ([self isAlternatePriceWithDate:[NSDate dateWithTimeIntervalSince1970:[pM timeStamp]]]) {
            [usingAltTariff addObject:pM];
        }
    }
    
    return usingAltTariff;
}

- (NSArray<MTPowerMeasurement*>*)measurementsInRegularTariffWithArray:(NSArray<MTPowerMeasurement*>*)measurements
{
    NSMutableArray *usingRegularTariff = [[NSMutableArray alloc] init];
    
    for (MTPowerMeasurement *pM in measurements) {
        
        if (![self isAlternatePriceWithDate:[NSDate dateWithTimeIntervalSince1970:[pM timeStamp]]]) {
            [usingRegularTariff addObject:pM];
        }
    }
    
    return usingRegularTariff;
}

@end
