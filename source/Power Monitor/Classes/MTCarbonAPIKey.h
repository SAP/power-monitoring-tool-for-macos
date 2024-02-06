/*
     MTCarbonAPIKey.h
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
#import "MTCarbonFootprint.h"

/*!
 @class         MTCarbonAPIKey
 @abstract      This class provides methods to store API keys in Keychain (and also to retrieve and delete them).
*/

@interface MTCarbonAPIKey : NSObject

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithAPIType: instead.
*/
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method        initWithAPIType:
 @abstract      Initialize a MTCarbonAPIKey object with a given api type.
 @param         type The type of the api.
 @discussion    Returns an initialized object for the specified api type.
*/
- (instancetype)initWithAPIType:(MTCarbonAPIType)type NS_DESIGNATED_INITIALIZER;

/*!
 @method        storeKey:completionHandler:
 @abstract      Store the given key in the user's login keychain.
 @param         key The key that should be stored.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns a reference to the keychain item (may be nil) and the status of the operation.
*/
- (void)storeKey:(NSString*)key completionHandler:(void(^)(OSStatus status, CFTypeRef item))completionHandler;

/*!
 @method        getKeyWithCompletionHandler:
 @abstract      Retrieve the api key from the user's login keychain.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns the key or nil if an error occurred.
*/
- (void)getKeyWithCompletionHandler:(void(^)(NSString *key))completionHandler;

/*!
 @method        deleteKeyWithCompletionHandler:
 @abstract      Delete the api key from the user's login keychain.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Returns YES if the key has been successfully deleted, otherwise returns NO.
*/
- (void)deleteKeyWithCompletionHandler:(void(^)(BOOL success))completionHandler;

@end
