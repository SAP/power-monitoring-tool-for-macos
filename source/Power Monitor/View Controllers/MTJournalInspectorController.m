/*
     MTJournalInspectorController.h
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

#import "MTJournalInspectorController.h"
#import "MTPowerJournal.h"
#import "MTDaemonConnection.h"
#import "Constants.h"

@interface MTJournalInspectorController ()
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;

@property (weak) IBOutlet NSTextField *consumptionSummaryValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryLabel;
@property (weak) IBOutlet NSTextField *consumptionSummaryNapValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryAltTariffValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryPriceValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryNapPriceValue;
@property (weak) IBOutlet NSTextField *consumptionSummaryAltTariffPriceValue;
@property (weak) IBOutlet NSTextField *durationSummaryAwakeValue;
@property (weak) IBOutlet NSTextField *durationSummaryNapValue;
@property (weak) IBOutlet NSTextField *durationSummaryAltTariffValue;
@property (weak) IBOutlet NSTextField *entriesCountValue;
@end

@implementation MTJournalInspectorController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _daemonConnection = [[MTDaemonConnection alloc] init];
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
    [self.consumptionSummaryAltTariffValue setStringValue:[MTPowerJournal consumptionStringAltTariffWithEntries:selectedObjects]];
    [self.durationSummaryAwakeValue setStringValue:[MTPowerJournal durationStringAwakeWithEntries:selectedObjects]];
    [self.durationSummaryNapValue setStringValue:[MTPowerJournal durationStringPowerNapWithEntries:selectedObjects]];
    [self.durationSummaryAltTariffValue setStringValue:[MTPowerJournal durationStringAltTariffWithEntries:selectedObjects]];
        
    if ([_userDefaults boolForKey:kMTDefaultsShowPriceKey]) {

        [_daemonConnection connectToDaemonWithExportedObject:nil
                                      andExecuteCommandBlock:^{
            
            [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
                
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
                
            }] altPriceEnabledWithReply:^(BOOL enabled, BOOL forced) {
                
                double pricePerKWh = [self->_userDefaults doubleForKey:kMTDefaultsElectricityPriceKey];
                double totalKWh = [MTPowerJournal consumptionTotalInKWhWithEntries:selectedObjects];
                double napKWh = [MTPowerJournal consumptionPowerNapInKWhWithEntries:selectedObjects];
                double electricityPriceTotal = 0;
                double electricityPriceNap = 0;
                double electricityPriceAltTariff = 0;
                
                if (enabled) {
                    
                    double altPricePerKWh = [self->_userDefaults doubleForKey:kMTDefaultsAltElectricityPriceKey];
                    double altTariffKWh = [MTPowerJournal consumptionAltTariffInKWhWithEntries:selectedObjects];
                    electricityPriceAltTariff = altTariffKWh * altPricePerKWh;
                    electricityPriceTotal = ((totalKWh - altTariffKWh) * pricePerKWh) + electricityPriceAltTariff;
                    electricityPriceNap = napKWh * pricePerKWh;

                } else {
                     
                    electricityPriceTotal = totalKWh * pricePerKWh;
                    electricityPriceNap = napKWh * pricePerKWh;
                }
                        
                NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
                [priceFormatter setMinimumFractionDigits:2];
                [priceFormatter setMaximumFractionDigits:2];
                [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [priceFormatter setLocalizesFormat:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                                        
                    [self.consumptionSummaryPriceValue setStringValue:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPriceTotal]]];
                    [self.consumptionSummaryNapPriceValue setStringValue:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPriceNap]]];
                    [self.consumptionSummaryAltTariffPriceValue setStringValue:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:electricityPriceAltTariff]]];
                });
            }];
        }];
    }
}

@end
