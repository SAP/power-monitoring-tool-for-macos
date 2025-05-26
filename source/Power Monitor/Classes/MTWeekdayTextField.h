/*
     MTWeekdayTextField.h
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

#import <Cocoa/Cocoa.h>

@interface MTWeekdayTextField : NSTextField

/*!
 @method        dayOfTheWeekForElementWithID:
 @abstract      Returns the day of the week for the element with the given id.
 @param         elementID An integer specifying the id of the element.
 @discussion    Would return 0 on U.S. systems for the element with the id 1, because there the first day of the week is Sunday (0).
                On a German system it would return 1, because there the week starts on Monday (1). Returns the day of the week
                as an integer or -1 if an error occurred.
*/
+ (NSInteger)dayOfTheWeekForElementWithID:(NSInteger)elementID;

@end
