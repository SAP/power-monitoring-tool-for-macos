/*
     MTWeekdayTextField.m
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

#import "MTWeekdayTextField.h"

@implementation MTWeekdayTextField

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
    NSInteger index = [MTWeekdayTextField dayOfTheWeekForElementWithID:[self tag]];
    
    if (index >= 0) {
        [self setStringValue:[NSString stringWithFormat:@"%@:", [[[NSCalendar currentCalendar] weekdaySymbols] objectAtIndex:index]]];
    }
}

+ (NSInteger)dayOfTheWeekForElementWithID:(NSInteger)elementID
{
    NSInteger index = -1;
    
    // weekday numbers start from 1 (first day of the week)
    if (elementID >= 1 && elementID <= 7) {
        
        index = (elementID - 1 + [[NSCalendar currentCalendar] firstWeekday] - 1) % 7;
    }
    
    return index;
}

@end
