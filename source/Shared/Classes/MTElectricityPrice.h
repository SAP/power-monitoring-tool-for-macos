/*
     MTElectricityPrice.h
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
#import "MTPowerMeasurement.h"

@interface MTElectricityPrice : NSObject

/*!
 @method        init:
 @discussion    The init method is not available. Please use initWithRegularPrice:alternativePrice:schedule: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithRegularPrice:alternativePrice:schedule:
 @abstract      Initialize a MTElectricityPrice object with the given values.
 @param         regular The regular electricity price per kWh.
 @param         alternative The alternative electricity price per kWh.
 @param         schedule A dictionary that contains a key for each day of the week, where the number
                0 stands for Sunday, 1 for Monday, and so on. The corresponding value is of type array
                and contains integers for each hour of the day during which the alternative electricity tariff
                is to apply (0-23).
 @discussion    Returns a MTElectricityPrice object initialized with the given values.
*/
- (instancetype)initWithRegularPrice:(double)regular
                    alternativePrice:(double)alternative
                            schedule:(NSDictionary*)schedule NS_DESIGNATED_INITIALIZER;

/*!
 @method        priceAtDate:
 @abstract      Returns the electricity price for the given date and time.
 @param         date The date and time for which the electricity price is to be returned.
 @discussion    Returns the electricity price or -1 if an error occurred.
*/
- (double)priceAtDate:(NSDate*)date;

/*!
 @method        measurementsInRegularTariffWithArray:
 @abstract      Takes an array of measurements and returns only the measurements taken while the regular electricity tariff was active.
 @discussion    Returns an NSArray of MTPowerMeasurement objects.
*/
- (NSArray<MTPowerMeasurement*>*)measurementsInRegularTariffWithArray:(NSArray<MTPowerMeasurement*>*)measurements;

/*!
 @method        measurementsInAltTariffWithArray:
 @abstract      Takes an array of measurements and returns only the measurements taken while the alternative electricity tariff was active.
 @discussion    Returns an NSArray of MTPowerMeasurement objects.
*/
- (NSArray<MTPowerMeasurement*>*)measurementsInAltTariffWithArray:(NSArray<MTPowerMeasurement*>*)measurements;

@end
