/*
     MTSettingsPowerNapController.m
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

#import "MTSettingsPowerNapController.h"
#import "MTDaemonConnection.h"
#import "MTSystemInfo.h"
#import "Constants.h"

@interface MTSettingsPowerNapController ()
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;
@property (nonatomic, strong, readwrite) NSMutableArray *powerNapMenuArray;

@property (weak) IBOutlet NSArrayController *powerNapController;
@property (weak) IBOutlet NSTextField *powerNapEnableLabel;
@property (weak) IBOutlet NSPopUpButton *powerNapButton;
@property (weak) IBOutlet NSButton *ignorePowerNapsCheckbox;
@end

@implementation MTSettingsPowerNapController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _powerNapMenuArray = [[NSMutableArray alloc] init];
    
    _daemonConnection = [[MTDaemonConnection alloc] init];
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{

        [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
            
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
            
        }] powerNapsIgnoredWithReply:^(BOOL enabled, BOOL forced) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.ignorePowerNapsCheckbox setState:(enabled) ? NSControlStateValueOn : NSControlStateValueOff];
                [self.ignorePowerNapsCheckbox setEnabled:!forced];
            });

        }];
    }];
    
    // populate the popup button's menu
    NSMutableArray *menuEntryDicts = [[NSMutableArray alloc] init];
    
    if ([MTSystemInfo hasBattery]) {
        
        NSDictionary *firstDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"powerNapEnableAlways", nil), kMTPopupMenuEntryLabelKey,
                                      [NSNumber numberWithInt:1], kMTPopupMenuEntryPowerNapKey,
                                      nil
        ];
        
        NSDictionary *secondDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"powerNapEnableACPower", nil), kMTPopupMenuEntryLabelKey,
                                      [NSNumber numberWithInt:2], kMTPopupMenuEntryPowerNapKey,
                                      nil
        ];
        
        NSDictionary *thirdDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"powerNapEnableNever", nil), kMTPopupMenuEntryLabelKey,
                                      [NSNumber numberWithInt:0], kMTPopupMenuEntryPowerNapKey,
                                      nil
        ];
        
        [menuEntryDicts addObjectsFromArray:[NSArray arrayWithObjects:firstDict, secondDict, thirdDict, nil]];
        
        [_powerNapEnableLabel setStringValue:NSLocalizedString(@"powerNapHasBatteryLabel", nil)];
        
    } else {
        
        NSDictionary *firstDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"powerNapEnable", nil), kMTPopupMenuEntryLabelKey,
                                      [NSNumber numberWithInt:1], kMTPopupMenuEntryPowerNapKey,
                                      nil
        ];
        
        NSDictionary *secondDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       NSLocalizedString(@"powerNapDisable", nil), kMTPopupMenuEntryLabelKey,
                                       [NSNumber numberWithInt:0], kMTPopupMenuEntryPowerNapKey,
                                       nil
        ];
        
        [menuEntryDicts addObjectsFromArray:[NSArray arrayWithObjects:firstDict, secondDict, nil]];
        
        [_powerNapEnableLabel setStringValue:NSLocalizedString(@"powerNapNoBatteryLabel", nil)];
    }
    
    [_powerNapController addObjects:menuEntryDicts];
    [_powerNapButton setEnabled:[MTSystemInfo deviceSupportsPowerNap]];
    [self setPowerNapButton];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self setPowerNapButton];
}

- (void)setPowerNapButton
{
    [MTSystemInfo powerNapStatusWithCompletionHandler:^(BOOL enabled, BOOL aconly) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSInteger powerNapValue = 0;
            
            if (enabled) {
                
                powerNapValue++;
                if (aconly) { powerNapValue++; }
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"powerNap == %ld", powerNapValue];
            NSArray *filteredArray = [[self.powerNapController arrangedObjects] filteredArrayUsingPredicate:predicate];
            
            if ([filteredArray count] > 0) {
                NSInteger index = [[self.powerNapController arrangedObjects] indexOfObjectIdenticalTo:[filteredArray lastObject]];
                [self.powerNapController setSelectionIndex:index];
            }
        });
    }];
}

#pragma mark IBActions

- (IBAction)setPowerNap:(id)sender
{
    NSInteger selectionIndex = [_powerNapController selectionIndex];
    
    if (selectionIndex >= 0 && selectionIndex < [[_powerNapController arrangedObjects] count]) {
        
        NSDictionary *selectionDict = [[_powerNapController arrangedObjects] objectAtIndex:selectionIndex];
        NSInteger powerNap = [[selectionDict valueForKey:kMTPopupMenuEntryPowerNapKey] integerValue];
        BOOL enable = (powerNap > 0) ? YES : NO;
        BOOL aconly = (powerNap > 1) ? YES : NO;
        
        [self->_daemonConnection connectToDaemonWithExportedObject:nil
                                            andExecuteCommandBlock:^{
            
            [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
                
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
                
            }] enablePowerNap:enable acPowerOnly:aconly completionHandler:^(BOOL success) {
                
                [self setPowerNapButton];
            }];
        }];
    }
}

- (IBAction)setIgnorePowerNaps:(id)sender
{
    NSControlStateValue checkboxState = [self.ignorePowerNapsCheckbox state];
    
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{

        [[self->_daemonConnection remoteObjectProxy] setIgnorePowerNaps:(checkboxState == NSControlStateValueOn) ? YES : NO completionHandler:^(BOOL success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{

                // revert the selected entry if the operation failed
                if (!success) {
                    [self.ignorePowerNapsCheckbox setState:(checkboxState == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn];
                }
            });
        }];
    }];
}

@end
