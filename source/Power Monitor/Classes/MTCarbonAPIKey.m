/*
     MTCarbonAPIKey.m
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

#import "MTCarbonAPIKey.h"

@interface MTCarbonAPIKey ()
@property (assign) MTCarbonAPIType type;
@end

@implementation MTCarbonAPIKey

- (instancetype)initWithAPIType:(MTCarbonAPIType)type
{
    self = [super init];
    
    if (self) {
        _type = type;
    }
    
    return self;
}

- (void)storeKey:(NSString*)key completionHandler:(void(^)(OSStatus status, CFTypeRef item))completionHandler
{
    // if the key exists, we delete it
    [self getKeyWithCompletionHandler:^(NSString *existingKey) {
        
        if (existingKey) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [self deleteKeyWithCompletionHandler:^(BOOL success) { dispatch_semaphore_signal(semaphore); }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }

        CFTypeRef item = NULL;
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                               key, (__bridge id)kSecValueData,
                               [[NSBundle mainBundle] bundleIdentifier], (__bridge id)kSecAttrService,
                               [NSString stringWithFormat:@"%d", self->_type], (__bridge id)kSecAttrAccount,
                               nil
        ];

        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)attrs, &item);
        if (completionHandler) { completionHandler(result, item); }

        if (item) { CFRelease(item); }
    }];
}

- (void)keychainItemWithCompletionHandler:(void(^)(OSStatus status, CFTypeRef item))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CFTypeRef item = NULL;
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                               (__bridge id)kSecMatchLimitOne, (__bridge id)kSecMatchLimit,
                               (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                               (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnData,
                               [[NSBundle mainBundle] bundleIdentifier], (__bridge id)kSecAttrService,
                               [NSString stringWithFormat:@"%d", self->_type], (__bridge id)kSecAttrAccount,
                               nil
        ];
        
        OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)attrs, &item);
        if (completionHandler) { completionHandler(result, item); }
    });
}

- (void)getKeyWithCompletionHandler:(void(^)(NSString *key))completionHandler
{
    [self keychainItemWithCompletionHandler:^(OSStatus status, CFTypeRef item) {
        
        NSString *apiKey = nil;
        
        if (item) {
            
            NSDictionary *attributes = (__bridge_transfer NSDictionary *)item;
            apiKey = [[NSString alloc] initWithData:[attributes objectForKey:(__bridge id)kSecValueData] encoding:NSUTF8StringEncoding];
        }
        
        if (completionHandler) { completionHandler(apiKey); }
    }];
}

- (void)deleteKeyWithCompletionHandler:(void(^)(BOOL success))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            BOOL success = NO;
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                                   (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                   (__bridge id)kCFBooleanFalse, (__bridge id)kSecReturnAttributes,
                                   (__bridge id)kCFBooleanFalse, (__bridge id)kSecReturnData,
                                   [[NSBundle mainBundle] bundleIdentifier], (__bridge id)kSecAttrService,
                                   [NSString stringWithFormat:@"%d", self->_type], (__bridge id)kSecAttrAccount,
                                   nil
            ];
            
            OSStatus result = SecItemDelete((__bridge CFDictionaryRef)attrs);
            
            if (result == errSecSuccess) { success = YES; }
            if (completionHandler) { completionHandler(success); }
    });
}

@end
