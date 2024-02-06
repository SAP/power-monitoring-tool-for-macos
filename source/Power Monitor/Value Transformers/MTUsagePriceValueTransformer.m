/*
     MTUsagePriceValueTransformer.h
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

#import "MTUsagePriceValueTransformer.h"
#import "Constants.h"

@implementation MTUsagePriceValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSString *returnValue = nil;
    NSNumber *measuredValue = (NSNumber*)value;
    double pricePerKWh = [[NSUserDefaults standardUserDefaults] doubleForKey:kMTDefaultsElectricityPriceKey];
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:[measuredValue doubleValue] unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kMTDefaultsShowPriceKey] && pricePerKWh > 0) {
        
        double electricityPrice = [powerConsumption doubleValue] * pricePerKWh;
        
        NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
        [priceFormatter setMinimumFractionDigits:2];
        [priceFormatter setMaximumFractionDigits:2];
        [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [priceFormatter setLocalizesFormat:YES];
        
        returnValue = [priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPrice]];
        
    } else {
        
        NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
        [[powerFormatter numberFormatter] setMinimumFractionDigits:3];
        [[powerFormatter numberFormatter] setMaximumFractionDigits:3];
        [powerFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale | NSMeasurementFormatterUnitOptionsProvidedUnit];
        
        returnValue = [powerFormatter stringFromMeasurement:powerConsumption];
    }
    
    return returnValue;
}

@end
