/*
     MTElectricityMapsAPI.m
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

#import "MTElectricityMapsAPI.h"
#import "Constants.h"

@interface MTElectricityMapsAPI ()
@property (nonatomic, strong, readwrite) NSString* apiKey;
@end

@implementation MTElectricityMapsAPI

- (instancetype)initWithAPIKey:(NSString *)key
{
    self = [super init];
    
    if (self) {
        _apiKey= key;
    }
    
    return self;
}

- (void)requestCarbonDataForLocation:(CLLocation*)location completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler
{
    [self requestCarbonDataForCountry:nil
                             location:location
                    completionHandler:completionHandler
    ];
}

- (void)requestCarbonDataForCountry:(NSString*)country completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler
{
    [self requestCarbonDataForCountry:country
                             location:nil
                    completionHandler:completionHandler
    ];
}

- (void)requestCarbonDataForCountry:(NSString*)country location:(CLLocation*)location completionHandler:(void (^) (NSNumber *gramsCO2eqkWh, NSError *error))completionHandler
{
    NSString *apiURLString = @"https://api.electricitymap.org/v3/carbon-intensity/latest?";
    
    if (country) {
        
        apiURLString = [apiURLString stringByAppendingFormat:@"zone=%@", country];
        
    } else {
        
        CLLocationCoordinate2D coordinate = [location coordinate];
        apiURLString = [apiURLString stringByAppendingFormat:@"lon=%f&lat=%f", coordinate.longitude, coordinate.latitude];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:apiURLString]];
    [request addValue:_apiKey forHTTPHeaderField:@"auth-token"];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        
        NSNumber *gramsCO2eqkWh = 0;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSError *httpError = nil;

        if ([httpResponse statusCode] == 200 && data) {
            
            NSDictionary *carbonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:kNilOptions
                                                                         error:&error
            ];

            gramsCO2eqkWh = [carbonDict valueForKeyPath:@"carbonIntensity"];
            
        } else {
            
            NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Request failed with error: %ld", [httpResponse statusCode]], NSLocalizedDescriptionKey, nil];
            httpError = [NSError errorWithDomain:kMTErrorDomain code:0 userInfo:errorDetail];
        }
        
        if (completionHandler) { completionHandler(gramsCO2eqkWh, httpError); }
    }];

    [dataTask resume];
}

@end
