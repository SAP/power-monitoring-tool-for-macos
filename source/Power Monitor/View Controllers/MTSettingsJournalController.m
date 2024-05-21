/*
     MTSettingsJournalController.m
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

#import "MTSettingsJournalController.h"
#import "MTDaemonConnection.h"
#import "Constants.h"

@interface MTSettingsJournalController ()
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;

@property (weak) IBOutlet NSButton *enableJournalCheckbox;
@property (weak) IBOutlet NSPopUpButton *autoDeletionButton;
@end

@implementation MTSettingsJournalController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self.enableJournalCheckbox setState:NSControlStateValueOff];
    [self.enableJournalCheckbox setEnabled:NO];
    [self.autoDeletionButton selectItemWithTag:0];
    [self.autoDeletionButton setEnabled:NO];
    
    _daemonConnection = [[MTDaemonConnection alloc] init];
    
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{

        [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
            
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
            
        }] journalEnabledWithReply:^(BOOL enabled, BOOL forced) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.enableJournalCheckbox setState:(enabled) ? NSControlStateValueOn : NSControlStateValueOff];
                [self.enableJournalCheckbox setEnabled:!forced];
            });

        }];
        
        [[[self->_daemonConnection connection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
            
            os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_FAULT, "SAPCorp: Failed to connect to daemon: %{public}@", error);
            
        }] journalAutoDeletionIntervalWithReply:^(NSInteger interval, BOOL forced) {

            if (interval >= 0 && interval <= 3) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.autoDeletionButton selectItemWithTag:interval];
                    [self.autoDeletionButton setEnabled:!forced];
                });
            }
        }];
    }];
}

#pragma mark IBActions

- (IBAction)setJournal:(id)sender
{
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{

        NSControlStateValue checkboxState = [self.enableJournalCheckbox state];

        [[self->_daemonConnection remoteObjectProxy] setJournalEnabled:(checkboxState == NSControlStateValueOn) ? YES : NO completionHandler:^(BOOL success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (success) {
                    
                    if (checkboxState == NSControlStateValueOff && [[NSFileManager defaultManager] fileExistsAtPath:kMTJournalFilePath]) {
                        
                        NSAlert *theAlert = [[NSAlert alloc] init];
                        [theAlert setMessageText:NSLocalizedString(@"dialogTrashJournalTitle", nil)];
                        [theAlert addButtonWithTitle:NSLocalizedString(@"MoveToTrashButton", nil)];
                        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
                        [theAlert setAlertStyle:NSAlertStyleInformational];
                        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
                            
                            if (returnCode == NSAlertFirstButtonReturn) {
                                
                                NSError *error = nil;
                                [[NSFileManager defaultManager] trashItemAtURL:[NSURL fileURLWithPath:kMTJournalFilePath] resultingItemURL:nil error:&error];
                                
                                if (error) {
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        NSAlert *theAlert = [[NSAlert alloc] init];
                                        [theAlert setMessageText:NSLocalizedString(@"dialogTrashJournalFailedTitle", nil)];
                                        [theAlert setInformativeText:NSLocalizedString(@"dialogTrashJournalFailedMessage", nil)];
                                        [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                                        [theAlert setAlertStyle:NSAlertStyleWarning];
                                        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
                                    });
                                }
                            }
                        }];
                    }
                    
                // revert the checkbox if the operation failed
                } else {
                    [self.enableJournalCheckbox setState:(checkboxState == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn];
                }
            });
        }];
    }];
}

- (IBAction)setAutoDeletion:(id)sender
{
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{

        NSInteger selectedTag = [self.autoDeletionButton selectedTag];

        [[self->_daemonConnection remoteObjectProxy] setJournalAutoDeletionInterval:selectedTag completionHandler:^(BOOL success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{

                // revert the selected entry if the operation failed
                if (!success) { [self.autoDeletionButton selectItemWithTag:selectedTag]; }
            });
        }];
    }];
}

@end
