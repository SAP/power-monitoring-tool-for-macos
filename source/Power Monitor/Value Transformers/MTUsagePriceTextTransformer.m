/*
     MTUsagePriceTextTransformer.h
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

#import "MTUsagePriceTextTransformer.h"
#import "Constants.h"

@implementation MTUsagePriceTextTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSString *returnValue = @"";

    if ([value boolValue] && [[NSUserDefaults standardUserDefaults] doubleForKey:kMTDefaultsElectricityPriceKey] > 0) {
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsTodayValuesOnlyKey]) {
            
            returnValue = NSLocalizedString(@"usagePriceTodayText", nil);
        } else {
            returnValue = NSLocalizedString(@"usagePriceText", nil);
        }
        
    } else {
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsTodayValuesOnlyKey]) {
            
            returnValue = NSLocalizedString(@"usageConsumptionTodayText", nil);
        } else {
            returnValue = NSLocalizedString(@"usageConsumptionText", nil);
        }
    }
    
    return returnValue;
}

@end
