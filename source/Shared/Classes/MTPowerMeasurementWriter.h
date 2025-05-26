/*
     MTPowerMeasurementWriter.h
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
#import "MTModifyData.h"
#import "MTPowerMeasurement.h"

/*!
 @class         MTPowerMeasurementWriter
 @abstract      This class provides methods to write power measurement data to a file.
*/

@interface MTPowerMeasurementWriter : NSObject

/*!
 @property      measurementData
 @abstract      The memory-mapped data from the given file.
 @discussion    The value of this property is NSData.
*/
@property (nonatomic, strong, readwrite) NSData *measurementData;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithFileAtPath:maximumMeasurements: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithFileAtPath:maximumMeasurements:
 @abstract      Initialize a MTPowerMeasurementWriter object with a data file at the given path and the given maximum number of measurements.
 @param         path The path to the data file.
 @param         maximumMeasurements An integer specifying the maximum number of measurements the data file should be able to hold.
 @discussion    Returns an initialized MTPowerMeasurementWriter object with the given data file
                mapped into memory (writeable). If the data file already exists and can exactly hold
                the specified number of measurements, the file is used. Otherwise a new file will be
                created. This method returns nil if an error occurred.
*/
- (instancetype)initWithFileAtPath:(NSString*)path maximumMeasurements:(NSInteger)maximumMeasurements NS_DESIGNATED_INITIALIZER;

/*!
 @method        currentBufferIndex
 @abstract      Return the current position in our buffer.
 @discussion    As our data file is actually a ring buffer, this method returns the current position within this buffer.
*/
- (NSInteger)currentBufferIndex;

/*!
 @method        invalidate
 @abstract      Invalidates the receiver.
 @discussion    Unmaps the measurement file from memory, closes the file handle and invalidates
                the receiver.
*/
- (void)invalidate;

@end

