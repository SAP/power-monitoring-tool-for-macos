/*
     MTSettingsGeneralController.m
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

#import "MTSettingsGeneralController.h"
#import "MTDaemonConnection.h"
#import "MTSystemInfo.h"
#import "Constants.h"

@interface MTSettingsGeneralController ()
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;

@property (weak) IBOutlet NSButton *runInBackgroundButton;
@property (weak) IBOutlet NSButton *loginItemButton;
@property (weak) IBOutlet NSTextField *electricityPriceField;
@property (weak) IBOutlet NSButton *deleteMeasurementsButton;
@end

@implementation MTSettingsGeneralController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    // set the initial state of the "Run in background" checkbox
    [_runInBackgroundButton setState:([_userDefaults boolForKey:kMTDefaultsRunInBackgroundKey]) ? NSControlStateValueOn : NSControlStateValueOff];
    if ([_userDefaults doubleForKey:kMTDefaultsElectricityPriceKey] == 0) { [_userDefaults setBool:NO forKey:kMTDefaultsShowPriceKey]; }
    
    // set the initial state of the "Open at login" checkbox
    [self setLoginButton];
    
    _daemonConnection = [[MTDaemonConnection alloc] init];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self setLoginButton];
}

- (void)setLoginButton
{
    [_loginItemButton setState:([MTSystemInfo loginItemEnabled]) ? NSControlStateValueOn : NSControlStateValueOff];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([_userDefaults doubleForKey:kMTDefaultsElectricityPriceKey] == 0) { [_userDefaults setBool:NO forKey:kMTDefaultsShowPriceKey]; }
}

- (void)mouseDown:(NSEvent *)event
{
    [[_electricityPriceField window] makeFirstResponder:nil];
}

#pragma mark IBActions

- (IBAction)setBackgroundMode:(id)sender
{
    if ([sender state] == NSControlStateValueOn) {
        
        NSAlert *theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:NSLocalizedString(@"dialogBackgroundTitle", nil)];
        [theAlert setInformativeText:NSLocalizedString(@"dialogBackgroundMessage", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"backgroundButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleInformational];
        [theAlert beginSheetModalForWindow:[[self view] window]
                         completionHandler:^(NSModalResponse returnCode) {
            
            [self->_userDefaults setBool:(returnCode == NSAlertFirstButtonReturn) ? YES : NO forKey:kMTDefaultsRunInBackgroundKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setState:(returnCode == NSAlertFirstButtonReturn) ? NSControlStateValueOn : NSControlStateValueOff];
            });
        }];
        
    } else {
        
        [self->_userDefaults setBool:NO forKey:kMTDefaultsRunInBackgroundKey];
    }
}

- (IBAction)setLoginItem:(id)sender
{
    [MTSystemInfo enableLoginItem:([sender state] == NSControlStateValueOn) ? YES : NO];
}

- (IBAction)deleteMeasurements:(id)sender
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:NSLocalizedString(@"dialogDeleteMeasurementsTitle", nil)];
    [theAlert setInformativeText:NSLocalizedString(@"dialogDeleteMeasurementsMessage", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"deleteButton", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
    [theAlert setAlertStyle:NSAlertStyleCritical];
    [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == NSAlertFirstButtonReturn) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self->_deleteMeasurementsButton setEnabled:NO];
                
                [self->_daemonConnection connectToDaemonWithExportedObject:nil
                                                    andExecuteCommandBlock:^{
                    
                    [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
                        
                        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self->_deleteMeasurementsButton setEnabled:YES];
                        });
                        
                    }] deleteMeasurementsWithCompletionHandler:^{
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameReloadDataFile
                                                                                object:nil
                                                                              userInfo:nil
                            ];
                            
                            [self->_deleteMeasurementsButton setEnabled:YES];
                        });
                    }];
                }];
            });
        }
    }];
}

@end
