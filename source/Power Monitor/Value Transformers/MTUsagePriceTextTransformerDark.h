/*
     MTUsagePriceTextTransformerDark.h
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
 @class         MTUsagePriceTextTransformerDark
 @abstract      A value transformer that returns the localized string "usagePriceTextDark" if the float value of the
                given value is greater than 0 and display of the energy costs has been enabled in the app's defaults.
                Otherwise it returns the localized string "usageConsumptionTextDark".
*/

@interface MTUsagePriceTextTransformerDark : NSValueTransformer

@end
