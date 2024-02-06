/*
     MTCarbonFootprint.h
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
#import <CoreLocation/CoreLocation.h>

/*!
 @class         MTCarbonFootprint
 @abstract      This class provides methods to determine the carbon footprint.
*/

@interface MTCarbonFootprint : NSObject <CLLocationManagerDelegate>

/*!
 @enum         MTCarbonAPIType
 @abstract     Specifies the type of the carbon API.
 @constant     MTCarbonAPITypeCO2Signal Specifies the CO2Signal API.
 @constant     MTCarbonAPITypeElectricityMaps Specifies the Electricity Maps API.
*/
typedef enum {
    MTCarbonAPITypeCO2Signal        = 0,
    MTCarbonAPITypeElectricityMaps  = 1
} MTCarbonAPIType;

/*!
 @property      allowUserInteraction
 @abstract      A property to specify if user interaction is allowed or not.
 @discussion    If set to YES, the user might be asked if the location of the Mac can be used to determine the correct carbon
                footprint. If set to NO, the user is not prompted and another but less accurate method is used to determine
                the approximate location of the Mac. The value of this property is boolean.
*/
@property (assign) BOOL allowUserInteraction;

/*!
 @property      apiType
 @abstract      A property to specify which API should be used.
 @discussion    The value of this property is MTCarbonAPIType.
*/
@property (assign) MTCarbonAPIType apiType;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithAPIKey: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithAPIKey:
 @abstract      Initialize a MTCarbonFootprint object with the given API key.
 @param         key The API key..
 @discussion    Returns an initialized MTCarbonFootprint object.
*/
- (instancetype)initWithAPIKey:(NSString *)key NS_DESIGNATED_INITIALIZER;

/*!
 @method        currentLocationWithCompletionHandler:
 @abstract      Get the Macs current location.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns the Mac's current location together with a boolean that indicates if the location
                is precise (location services) or not (MapKit).
*/
- (void)currentLocationWithCompletionHandler:(void (^) (CLLocation *location, BOOL preciseLocation))completionHandler;

/*!
 @method        footprintWithLocation:completionHandler:
 @abstract      Get the Mac's carbon footprint at the given location.
 @param         location The location object.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns the carbon value in gCO2eq/kWh. If an error occurred, the NSError object might
                provide information about the error that caused the operation to fail.
*/
- (void)footprintWithLocation:(CLLocation*)location completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler;

/*!
 @method        countryCodeWithLocation:completionHandler:
 @abstract      Get the country code for the given location.
 @param         location The location object.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns country code for the given location or nil, if the location could not be determined.
*/
- (void)countryCodeWithLocation:(CLLocation*)location completionHandler:(void (^) (NSString *countryCode))completionHandler;

@end
