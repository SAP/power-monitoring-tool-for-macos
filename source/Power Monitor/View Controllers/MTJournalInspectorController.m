/*
     MTJournalInspectorController.h
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

#import "MTJournalInspectorController.h"
#import "MTPowerJournal.h"
#import "Constants.h"

@interface MTJournalInspectorController ()
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;

@property (weak) IBOutlet NSTextField *consumptionSummaryValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryLabel;
@property (weak) IBOutlet NSTextField *consumptionSummaryNapValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryPriceValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryNapPriceValue;
@property (weak) IBOutlet NSTextField *durationSummaryAwakeValue;
@property (weak) IBOutlet NSTextField *durationSummaryNapValue;
@property (weak) IBOutlet NSTextField *entriesCountValue;
@end

@implementation MTJournalInspectorController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
}

#pragma mark MTJournalControllerDelegate

- (void)journalControllerSelectionDidChange:(NSArrayController*)controller
{
    NSArray *selectedObjects = [controller selectedObjects];
        
    if ([selectedObjects count] > 0) {
        
        [self.consumptionSummaryLabel setStringValue:NSLocalizedString(@"consumptionLabelSelected", nil)];

    } else {
        
        selectedObjects = [controller arrangedObjects];
        [self.consumptionSummaryLabel setStringValue:NSLocalizedString(@"consumptionLabelAll", nil)];
    }
    
    [self.entriesCountValue setStringValue:[NSString stringWithFormat:@"%ld", [selectedObjects count]]];
    [self.consumptionSummaryValue setStringValue:[MTPowerJournal consumptionStringTotalWithEntries:selectedObjects]];
    [self.consumptionSummaryNapValue setStringValue:[MTPowerJournal consumptionStringPowerNapWithEntries:selectedObjects]];
    [self.durationSummaryAwakeValue setStringValue:[MTPowerJournal durationStringAwakeWithEntries:selectedObjects]];
    [self.durationSummaryNapValue setStringValue:[MTPowerJournal durationStringPowerNapWithEntries:selectedObjects]];
    
    if ([_userDefaults boolForKey:kMTDefaultsShowPriceKey]) {
        
        double pricePerKWh = [_userDefaults doubleForKey:kMTDefaultsElectricityPriceKey];
        double electricityPriceTotal = [MTPowerJournal consumptionTotalInKWhWithEntries:selectedObjects] * pricePerKWh;
        double electricityPriceNap = [MTPowerJournal consumptionPowerNapInKWhWithEntries:selectedObjects] * pricePerKWh;
        
        NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
        [priceFormatter setMinimumFractionDigits:2];
        [priceFormatter setMaximumFractionDigits:2];
        [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [priceFormatter setLocalizesFormat:YES];
        
        [self.consumptionSummaryPriceValue setStringValue:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPriceTotal]]];
        [self.consumptionSummaryNapPriceValue setStringValue:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPriceNap]]];
    }
}

@end
