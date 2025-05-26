/*
     MTHourTextField.m
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

#import "MTHourTextField.h"
#import "MTElectricityPrice.h"

@implementation MTHourTextField

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
    NSInteger hour = [self tag];
    
    if (hour >= 0 && hour <= 23) {
        
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setHour:hour];
        [components setMinute:0];

        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
        timeFormatter.dateStyle = NSDateFormatterNoStyle;
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSString *hourString = [timeFormatter stringFromDate:[calendar dateFromComponents:components]];
        
        [self setStringValue:hourString];
    }
}

@end
