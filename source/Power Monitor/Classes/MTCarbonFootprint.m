/*
     MTCarbonFootprint.m
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

#import "MTCarbonFootprint.h"
#import "MTCO2SignalAPI.h"
#import "MTElectricityMapsAPI.h"
#import "Constants.h"
#import <MapKit/MapKit.h>

@interface MTCarbonFootprint ()
@property (nonatomic, strong, readwrite) CLLocationManager *locationManager;
@property (nonatomic, strong, readwrite) NSString *apiKey;
@property (nonatomic, copy) void (^completionHandler) (CLLocation* location, BOOL preciseLocation);
@end

@implementation MTCarbonFootprint

- (instancetype)initWithAPIKey:(NSString *)key
{
    self = [super init];
    
    if (self) {
        _apiType = MTCarbonAPITypeCO2Signal;
        _apiKey = key;
    }
    
    return self;
}

- (void)currentLocationWithCompletionHandler:(void (^) (CLLocation* location, BOOL preciseLocation))completionHandler
{
    // if user interaction is allowed and location services are
    // enabled, we use it to get the machine's approximate location.
    // Otherwise we use MapKit to get the machine's approximate
    // location.
    if (_allowUserInteraction) {
    
        if ([CLLocationManager locationServicesEnabled]) {

            _completionHandler = completionHandler;
        
            _locationManager = [[CLLocationManager alloc] init];
            [_locationManager setDelegate:self];
            [_locationManager setDesiredAccuracy:kCLLocationAccuracyReduced];
        
            if ([_locationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            
                [_locationManager requestAlwaysAuthorization];
            
            } else if ([_locationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            
                [_locationManager startUpdatingLocation];
            
            } else if (completionHandler) {
            
                completionHandler([self approximateLocation], NO);
            }
            
        } else if (completionHandler) {

            completionHandler([self approximateLocation], NO);
        }

    } else if (completionHandler) {

        completionHandler([self approximateLocation], NO);
    }
}

- (void)footprintWithLocation:(CLLocation*)location completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler
{
    if (_apiType == MTCarbonAPITypeCO2Signal) {
        
        MTCO2SignalAPI *co2API = [[MTCO2SignalAPI alloc] initWithAPIKey:_apiKey];
        [co2API requestCarbonDataForLocation:location
                           completionHandler:^(NSNumber *gramsCO2eqkWh, NSError *error) {
        
                if (completionHandler) { completionHandler(gramsCO2eqkWh, error); }
        }];
        
    } else if (_apiType == MTCarbonAPITypeElectricityMaps) {
        
        MTElectricityMapsAPI *co2API = [[MTElectricityMapsAPI alloc] initWithAPIKey:_apiKey];
        [co2API requestCarbonDataForLocation:location
                           completionHandler:^(NSNumber *gramsCO2eqkWh, NSError *error) {
            
            if (completionHandler) { completionHandler(gramsCO2eqkWh, error); }
        }];
        
    } else if (completionHandler) {
        
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"API type not specified", NSLocalizedDescriptionKey, nil];
        NSError *error = [NSError errorWithDomain:kMTErrorDomain code:0 userInfo:errorDetail];
        
        completionHandler(0, error);
    }
}

- (CLLocation*)approximateLocation
{
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];

    CLLocationCoordinate2D regionCenter = [mapView region].center;
    CLLocation *approximateLocation = [[CLLocation alloc] initWithLatitude:regionCenter.latitude
                                                                 longitude:regionCenter.longitude];

    return approximateLocation;
}

- (void)countryCodeWithLocation:(CLLocation*)location completionHandler:(void (^) (NSString *countryCode))completionHandler
{
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        NSString *countryCode = nil;
        if ([placemarks count] > 0) { countryCode = [[placemarks firstObject] ISOcountryCode]; }
        if (completionHandler) { completionHandler(countryCode); }
    }];
}

#pragma mark CoreLocation delegate methods

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    // if the user did not allow location usage, we
    // fall back to the machine's approximate location
    if ([manager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        
        [_locationManager startUpdatingLocation];

    } else if (_completionHandler) {

        _completionHandler([self approximateLocation], NO);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // if location manager fails, we fall back
    // to the machine's approximate location
    [_locationManager stopUpdatingLocation];
    
    if (_completionHandler) { _completionHandler([self approximateLocation], NO); }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [self->_locationManager stopUpdatingLocation];
    
    if (_completionHandler) {
        
        CLLocationCoordinate2D coordinate = [[manager location] coordinate];
        
        if (coordinate.latitude > 0 && coordinate.longitude > 0) {
            _completionHandler([manager location], YES);
        } else {
            _completionHandler([self approximateLocation], NO);
        }
    }
}

@end
