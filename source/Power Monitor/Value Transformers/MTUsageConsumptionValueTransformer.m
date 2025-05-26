/*
     MTUsageConsumptionValueTransformer.m
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

#import "MTUsageConsumptionValueTransformer.h"
#import "Constants.h"

@implementation MTUsageConsumptionValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSNumber *measuredValue = (NSNumber*)value;
    
    NSMeasurement *powerConsumption = [[NSMeasurement alloc] initWithDoubleValue:[measuredValue doubleValue] unit:[NSUnitEnergy joules]];
    powerConsumption = [powerConsumption measurementByConvertingToUnit:[NSUnitEnergy kilowattHours]];
        
    NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
    [[powerFormatter numberFormatter] setMinimumFractionDigits:3];
    [[powerFormatter numberFormatter] setMaximumFractionDigits:3];
    [powerFormatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale | NSMeasurementFormatterUnitOptionsProvidedUnit];
    
    NSString *returnValue = [powerFormatter stringFromMeasurement:powerConsumption];
    
    return returnValue;
}

@end
