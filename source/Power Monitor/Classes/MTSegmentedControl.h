/*
     MTSegmentedControl.h
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

@interface MTSegmentedControl : NSSegmentedControl

/*!
 @method        setSelectedSegmentsWithArray:
 @abstract      Selects the specified segments.
 @param         selected An array of NSNumber objects representing the indexes of the segments that should be selected.
*/
- (void)setSelectedSegmentsWithArray:(NSArray<NSNumber*>*)selected;

@end
