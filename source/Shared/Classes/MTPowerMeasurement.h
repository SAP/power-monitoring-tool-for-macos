/*
     MTPowerMeasurement.h
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

/*!
 @class         MTPowerMeasurement
 @abstract      This class defines a power measurement.
*/

@interface MTPowerMeasurement : NSMeasurement

/*!
 @struct        MeasurementFileHeader
 @abstract      Specifies the header of a measurement file.
 @discussion    The measurement file format looks like this:
 @code
    +00 7B  magic number        (0x70777264617461)
    +07 1B  reserved            (0x0)
    +08 1B  length of header    (0xA)
    +09 1B  version number      (0x2)
    +10 XX  [data]
*/
typedef struct __attribute__((packed)) {
    
    /// The signature of the file.
    char signature[8];
    /// The size of the header
    uint8_t size;
    /// The file format version.
    uint8_t version;
    
} MeasurementFileHeader;

/*!
 @struct        MeasurementStruct
 @abstract      Specifies a power measurement, containing of the measured value and a timestamp.
*/
typedef struct __attribute__((packed)) {
    
    /// The timestamp of the measurement.
    time_t timestamp;
    /// The measurement value.
    uint32_t value;
    /// A boolean specifying if the Mac is in dark wake mode.
    Boolean darkwake;
    
} MeasurementStruct;

/*!
 @property      timeStamp
 @abstract      A property to store the timestamp of a measurement.
 @discussion    The value of this property is time_t.
*/
@property (assign) time_t timeStamp;

/*!
 @property      darkWake
 @abstract      A property to store if the measurement was done while the Mac was in dark wake mode.
 @discussion    The value of this boolean.
*/
@property (assign) BOOL darkWake;

/*!
 @method        initWithDoubleValue:unit:
 @discussion    The init method is not available. Please use initWithPowerValue: instead.
*/
- (instancetype)initWithDoubleValue:(double)doubleValue unit:(NSUnit *)unit NS_UNAVAILABLE;

/*!
 @method        initWithPowerValue:
 @abstract      Initialize a MTPowerMeasurement object with a given power value.
 @param         powerValue The double-precision floating-point measurement value.
 @discussion    Returns a measurement initialized to have the specified value in watts.
*/
- (instancetype)initWithPowerValue:(double)powerValue NS_DESIGNATED_INITIALIZER;

/*!
 @method        state
 @abstract      Get the power state of a measurement (awake, power nap, sleep).
 @discussion    Returns a localized string for the power state of the measurement.
*/
- (NSString*)state;

/*!
 @method        headerWithFilePath:
 @abstract      Read a pwrdata file's header and return the relevant data in a MeasurementFileHeader struct.
 @param         path The path to the pwrdata file.
 @discussion    Returns a MeasurementFileHeader struct with the values read from file.
*/
+ (MeasurementFileHeader)headerWithFilePath:(NSString*)path;

@end

