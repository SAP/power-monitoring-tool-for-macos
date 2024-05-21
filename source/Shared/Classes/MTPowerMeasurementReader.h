/*
     MTPowerMeasurementReader.h
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

#import <Cocoa/Cocoa.h>
#import "MTPowerMeasurement.h"

/*!
 @class         MTPowerMeasurementReader
 @abstract      This class provides methods to read power measurement data from file.
*/

@interface MTPowerMeasurementReader : NSObject

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithContentsOfFile: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithContentsOfFile:
 @abstract      Initialize a MTPowerMeasurementReader object with a data file at the given path.
 @param         path The path to the data file.
 @discussion    Returns an initialized MTPowerMeasurementReader object with the given data file
                mapped into memory (read-only). Returns nil if an error occurred.
*/
- (instancetype)initWithContentsOfFile:(NSString*)path;

/*!
 @method        initWithData:
 @abstract      Initialize a MTPowerMeasurementReader object with the given data.
 @param         data A reference to the data object.
 @discussion    Returns an initialized MTPowerMeasurementReader object with the given data. Returns nil if an error occurred.
*/
- (instancetype)initWithData:(NSData*)data;

/*!
 @method        allMeasurements
 @abstract      Return all measurement data.
 @discussion    Returns an array of MTPowerMeasurement objects. This represents all data that are
                currently stored in the given data file.
*/
- (NSArray<MTPowerMeasurement*>*)allMeasurements;

/*!
 @method        allMeasurementsSinceDate:
 @abstract      Return all measurement data starting with the given date
 @param         date The date from which measured values should be returned
 @discussion    Returns an array of MTPowerMeasurement objects. This represents all data with a
                timestamp after the given date that are currently stored in the given data file.
*/
- (NSArray<MTPowerMeasurement*>*)allMeasurementsSinceDate:(NSDate*)date;

/*!
 @method        currentBufferIndex
 @abstract      Return the current position in our buffer.
 @discussion    As our data file is actually a ring buffer, this method returns the current position within this buffer.
*/
- (NSInteger)currentBufferIndex;

/*!
 @method        currentPower
 @abstract      Returns the current system power.
 @discussion    Returns a MTPowerMeasurement object representing the current system power.
*/
- (MTPowerMeasurement*)currentPower;

/*!
 @method        invalidate
 @abstract      Invalidates the receiver.
 @discussion    Unmaps the measurement file from memory, closes the file handle and invalidates
                the receiver.
*/
- (void)invalidate;

@end
