/*
     MTElectricityMapsAPI.h
     Copyright 2023 SAP SE
     
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
 @class         MTElectricityMapsAPI
 @abstract      This class provides methods to retrieve carbon data using the Electricity Maps API (https://www.electricitymaps.com).
*/

@interface MTElectricityMapsAPI : NSObject

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithAPIKey: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithAPIKey:
 @abstract      Initialize a MTElectricityMapsAPI object with the given API key.
 @param         key The API key..
 @discussion    Returns an initialized MTElectricityMapsAPI object.
*/
- (instancetype)initWithAPIKey:(NSString*)key NS_DESIGNATED_INITIALIZER;

/*!
 @method        requestCarbonDataForLocation:completionHandler:
 @abstract      Get the Mac's carbon data for the given location.
 @param         location The location object.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns the carbon value in gCO2eq/kWh. If an error occurred, the NSError object might
                provide information about the error that caused the operation to fail.
*/
- (void)requestCarbonDataForLocation:(CLLocation*)location
                   completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler;

/*!
 @method        requestCarbonDataForCountry:completionHandler:
 @abstract      Get the Mac's carbon data for the given country.
 @param         country The country code.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns the carbon value in gCO2eq/kWh. If an error occurred, the NSError object might
                provide information about the error that caused the operation to fail.
*/
- (void)requestCarbonDataForCountry:(NSString*)country
                  completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler;
@end
