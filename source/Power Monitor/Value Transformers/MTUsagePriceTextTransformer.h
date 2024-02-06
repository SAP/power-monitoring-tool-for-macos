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

#import <Cocoa/Cocoa.h>

/*!
 @class         MTUsagePriceTextTransformer
 @abstract      A value transformer that returns the localized string "usagePriceText" if the bool value of the
                given value is YES and the double value of the user defaults key kMTDefaultsElectricityPriceKey
                is greater than 0. Otherwise it returns the localized string "usageConsumptionText".
*/

@interface MTUsagePriceTextTransformer : NSValueTransformer

@end
