/*
     MTSegmentedControl.m
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

#import "MTSegmentedControl.h"

@implementation MTSegmentedControl

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        [self setUpControl];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        
        [self setUpControl];
    }
    
    return self;
}

- (void)setUpControl
{
    [self setSelectedSegment:-1];
    [self setToolTip:NSLocalizedString(@"altScheduleToolTip", nil)];
    [self setAccessibilityChildren:nil];
}

- (void)setSelectedSegmentsWithArray:(NSArray*)selected
{
    [self setSelectedSegment:-1];
    
    for (NSNumber *index in selected) {
                
        NSInteger selectedIndex = [index integerValue];
        NSInteger numberOfSegments = [self segmentCount];
                
        if (selectedIndex >= 0 && selectedIndex < numberOfSegments) {
            [self setSelected:YES forSegment:selectedIndex];
        }
    }
}

@end
