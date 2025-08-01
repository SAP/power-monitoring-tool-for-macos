/*
     MTPowerMeasurementArray.h
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

/*!
 @abstract      This extends the NSArray class with some convenience methods used by arrays of MTPowerMeasurement objects.
*/

@interface NSArray (MTPowerMeasurementArray)

/*!
 @method        minimumPower
 @abstract      Returns the minimum power value.
 @discussion    Returns an MTPowerMeasurement object representing the minimum power value of the array.
*/
- (MTPowerMeasurement*)minimumPower;

/*!
 @method        averagePower
 @abstract      Returns the average power value.
 @discussion    Returns an MTPowerMeasurement object representing the average power value of the array.
*/
- (MTPowerMeasurement*)averagePower;

/*!
 @method        maximumPower
 @abstract      Returns the maximum power value.
 @discussion    Returns an MTPowerMeasurement object representing the maximum power value of the array.
*/
- (MTPowerMeasurement*)maximumPower;

/*!
 @method        awakeMeasurements
 @abstract      Returns only the measurements taken while the device was awake.
 @discussion    Returns an NSArray of MTPowerMeasurement objects.
*/
- (NSArray<MTPowerMeasurement*>*)awakeMeasurements;

/*!
 @method        powerNapMeasurements
 @abstract      Returns only the measurements taken while the device took a power nap.
 @discussion    Returns an NSArray of MTPowerMeasurement objects.
*/
- (NSArray<MTPowerMeasurement*>*)powerNapMeasurements;

/*!
 @method        totalTime
 @abstract      Returns the total time covered by the taken measurements.
 @discussion    Returns an NSTimeInterval object.
*/
- (NSTimeInterval)totalTime;

/*!
 @method        measurementsGroupedByDay
 @abstract      Returns the measurement data grouped by day.
 @discussion    Returns an NSDictionary with timestamps as keys and NSArrays of MTPowerMeasurement
                objects as values.
*/
- (NSDictionary*)measurementsGroupedByDay;

@end
