/*
     MTPowerGraphInspectorController.h
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

#import "MTPowerGraphInspectorController.h"
#import "MTPowerMeasurement.h"
#import "MTPowerGraphView.h"
#import "Constants.h"

@interface MTPowerGraphInspectorController ()
@property (assign) IBOutlet NSTextField *powerValueField;
@property (assign) IBOutlet NSTextField *powerStateField;
@property (assign) IBOutlet NSTextField *measurementDateField;
@property (assign) IBOutlet NSTextField *secondaryPowerValueField;
@property (assign) IBOutlet NSTextField *secondaryPowerStateField;
@property (assign) IBOutlet NSTextField *secondaryMeasurementDateField;

@property (assign) BOOL hidePrimaryValue;
@property (assign) BOOL hideSecondaryValue;
@property (assign) BOOL primaryValueIsLocked;
@end

@implementation MTPowerGraphInspectorController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.hidePrimaryValue = YES;
    self.hideSecondaryValue = YES;
}

#pragma mark MTPowerGraphControllerDelegate

- (void)graphView:(MTPowerGraphView *)view didChangePinning:(BOOL)isPinned 
{
    if (isPinned) {
        
        [_powerValueField setTextColor:[NSColor systemRedColor]];
        [_powerStateField setTextColor:[NSColor systemRedColor]];
        [_measurementDateField setTextColor:[NSColor systemRedColor]];
        
        [_secondaryPowerValueField setStringValue:[_powerValueField stringValue]];
        [_secondaryPowerStateField setStringValue:[_powerStateField stringValue]];
        [_secondaryMeasurementDateField setStringValue:[_measurementDateField stringValue]];
        
        self.hideSecondaryValue = NO;
        self.primaryValueIsLocked = YES;
        
    } else {
        
        [_powerValueField setTextColor:[NSColor labelColor]];
        [_powerStateField setTextColor:[NSColor labelColor]];
        [_measurementDateField setTextColor:[NSColor labelColor]];
        
        self.hideSecondaryValue = YES;
        self.primaryValueIsLocked = NO;
    }
}

- (void)graphView:(MTPowerGraphView *)view didSelectMeasurement:(MTPowerMeasurement *)measurement 
{
    if (measurement) {
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[measurement timeStamp]];
        
        NSMeasurementFormatter *powerFormatter = [[NSMeasurementFormatter alloc] init];
            
        if ([measurement doubleValue] > 0) {
            
            [[powerFormatter numberFormatter] setMinimumFractionDigits:2];
            [[powerFormatter numberFormatter] setMaximumFractionDigits:2];
            
        } else {
            
            [[powerFormatter numberFormatter] setMinimumFractionDigits:0];
            [[powerFormatter numberFormatter] setMaximumFractionDigits:0];
        }
        
        if (!_hideSecondaryValue) {
            
            [_secondaryPowerValueField setStringValue:[powerFormatter stringFromMeasurement:measurement]];
            [_secondaryPowerStateField setStringValue:[measurement state]];
            [_secondaryMeasurementDateField setStringValue:[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
            
        } else {
            
            [_powerValueField setStringValue:[powerFormatter stringFromMeasurement:measurement]];
            [_powerStateField setStringValue:[measurement state]];
            [_measurementDateField setStringValue:[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
        }
        
    } else {
        
        self.primaryValueIsLocked = NO;
        self.hidePrimaryValue = YES;
        self.hideSecondaryValue = YES;
    }
}

- (void)mouseEnteredGraphView:(MTPowerGraphView *)view 
{
    if (_primaryValueIsLocked) {
        
        self.hideSecondaryValue = NO;
        
    } else {
        
        self.hidePrimaryValue = NO;
    }
}

- (void)mouseExitedGraphView:(MTPowerGraphView *)view 
{
    if (_primaryValueIsLocked) {
        
        self.hideSecondaryValue = YES;
        
    } else {
        
        self.hidePrimaryValue = YES;
    }
}

@end
