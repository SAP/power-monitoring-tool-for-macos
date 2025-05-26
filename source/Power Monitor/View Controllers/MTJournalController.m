/*
     MTLogController.m
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

#import "MTJournalController.h"
#import "MTPowerJournal.h"
#import "MTToolbarItem.h"
#import "Constants.h"
#import "MTSavePanelAccessoryController.h"
#import <os/log.h>
#import <UniformTypeIdentifiers/UTCoreTypes.h>

@interface MTJournalController ()
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) MTPowerJournal *powerJournal;
@property (nonatomic, strong, readwrite) MTSavePanelAccessoryController *accessoryController;
@property (retain) id daemonPreferencesObserver;

@property (weak) IBOutlet NSArrayController *journalController;
@property (weak) IBOutlet NSTableView *tableView;
@end

@implementation MTJournalController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    [_tableView setAccessibilityLabel:NSLocalizedString(@"accessiblilityLabelJournalTableView", nil)];
        
    NSSortDescriptor *initialSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO selector:@selector(compare:)];
    [self.journalController setSortDescriptors:[NSArray arrayWithObject:initialSortDescriptor]];
    
    [self importJournal];
    [self toggleInfoSection:nil];
    
    // observe our user defaults for changes
    NSArray *observedDefaults = [NSArray arrayWithObjects:
                                 kMTDefaultsElectricityPriceKey,
                                 kMTDefaultsAltElectricityPriceKey,
                                 kMTDefaultsShowPriceKey,
                                 nil
    ];
    
    for (NSString *keyPath in observedDefaults) {
        [_userDefaults addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    
    _daemonPreferencesObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:kMTNotificationNameDaemonConfigDidChange
                                                                                              object:nil
                                                                                               queue:nil
                                                                                          usingBlock:^(NSNotification *notification) {
        
        NSDictionary *userInfo = [notification userInfo];
        
        if (userInfo) {
            
            NSString *changedKey = [userInfo objectForKey:kMTNotificationKeyPreferenceChanged];
            
            if ([changedKey isEqualToString:(NSString*)kMTPrefsUseAltPriceKey]) {
                
                [self inspectorUpdateConsumptionSummary];
            }
        }
    }];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self inspectorUpdateConsumptionSummary];
}

- (void)importJournal
{
    self.powerJournal = [[MTPowerJournal alloc] initWithFileAtPath:kMTJournalFilePath];
    
    if (_powerJournal) {

        [self inspectorUpdateConsumptionSummary];
    }
}

- (void)inspectorUpdateConsumptionSummary
{
    if (_delegate && [_delegate respondsToSelector:@selector(journalControllerSelectionDidChange:)]) {

        [_delegate journalControllerSelectionDidChange:_journalController];
    }
}

#pragma mark IBActions

- (IBAction)updateContent:(id)sender
{
    [self importJournal];
}

- (IBAction)saveContent:(id)sender
{
    // load the nib file
    if (!_accessoryController) {
        _accessoryController = [[MTSavePanelAccessoryController alloc] initWithNibName:@"MTSavePanelAccessory" bundle:nil];
    }

    NSArray *selectedObjects = [self->_journalController selectedObjects];
    BOOL selectedOnly = ([selectedObjects count] > 0 && [selectedObjects count] != [[self->_journalController arrangedObjects] count]) ? YES : NO;
    [_accessoryController setHasSelection:selectedOnly];
    [_accessoryController setExportSelected:selectedOnly];
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAccessoryView:[_accessoryController view]];
    [panel setNameFieldStringValue:NSLocalizedString(@"journalExportFileName", nil)];
    [panel setAllowedContentTypes:[NSArray arrayWithObject:([_userDefaults integerForKey:kMTDefaultsJournalExportFormatKey] == 1) ? UTTypeJSON : UTTypeCommaSeparatedText]];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == NSModalResponseOK) {
            
            NSError *error = nil;
            NSArray *entriesForExport = ([self->_accessoryController exportSelected]) ? [self->_journalController selectedObjects] : [self->_journalController arrangedObjects];
            
            if ([self->_userDefaults integerForKey:kMTDefaultsJournalExportFormatKey] == MTJournalExportFileTypeJSON) {

                NSString *jsonString = [MTPowerJournal jsonStringWithEntries:entriesForExport 
                                                                summarizedBy:[self->_accessoryController summarizeType]
                                                             includeDuration:[self->_userDefaults boolForKey:kMTDefaultsJournalExportDurationKey]
                ];
                [jsonString writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:&error];
                
            } else {
                
                NSString *csvString = [MTPowerJournal csvStringWithEntries:entriesForExport
                                                              summarizedBy:[self->_accessoryController summarizeType]
                                                           includeDuration:[self->_userDefaults boolForKey:kMTDefaultsJournalExportDurationKey]
                                                                 addHeader:[self->_userDefaults boolForKey:kMTDefaultsJournalExportCSVHeaderKey]
                ];
                [csvString writeToURL:[panel URL] atomically:YES encoding:NSASCIIStringEncoding error:&error];
            }
            
            if (error) {
                
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "SAPCorp: Unable to export journal: %{public}@", error);
                
                NSAlert *theAlert = [[NSAlert alloc] init];
                [theAlert setMessageText:NSLocalizedString(@"dialogFailedToExportJournalTitle", nil)];
                [theAlert setInformativeText:NSLocalizedString(@"dialogFailedToExportJournalMessage", nil)];
                [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                [theAlert setAlertStyle:NSAlertStyleCritical];
                [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
            }
        }
    }];
}

- (IBAction)delete:(id)sender
{
    NSInteger clickedRow = [_tableView clickedRow];

    if ((clickedRow >= 0 && clickedRow < [[self->_journalController arrangedObjects] count]) || [[_tableView selectedRowIndexes] count] > 0) {
        
        NSIndexSet *toBeDeleted = nil;
        
        if (clickedRow == NSUIntegerMax || [[_tableView selectedRowIndexes] containsIndex:clickedRow]) {
            toBeDeleted = [_tableView selectedRowIndexes];
        } else {
            toBeDeleted = [NSIndexSet indexSetWithIndex:clickedRow];
        }
                
        NSAlert *theAlert = [[NSAlert alloc] init];
        
        if ([toBeDeleted count] > 1) {
            
            if ([toBeDeleted count] == [[self->_journalController arrangedObjects] count]) {
                [theAlert setMessageText:[NSString localizedStringWithFormat:NSLocalizedString(@"dialogJournalDeleteAllTitle", nil), [toBeDeleted count]]];
            } else {
                [theAlert setMessageText:[NSString localizedStringWithFormat:NSLocalizedString(@"dialogJournalDeleteMultipleTitle", nil), [toBeDeleted count]]];
            }
            
        } else {
            [theAlert setMessageText:NSLocalizedString(@"dialogJournalDeleteOneTitle", nil)];
        }
        
        [theAlert setInformativeText:NSLocalizedString(@"dialogJournalDeleteMessage", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"deleteButton", nil)];
        [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
        [theAlert setAlertStyle:NSAlertStyleInformational];
        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
            
            if (returnCode == NSAlertFirstButtonReturn) {
                
                NSArray *entries = [[self->_journalController arrangedObjects] objectsAtIndexes:toBeDeleted];
                [[self->_powerJournal allEntries] removeObjectsInArray:entries];
                [self->_powerJournal synchronize];
                [self importJournal];
            }
        }];
    }
}

- (IBAction)showJournalInFinder:(id)sender
{
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:kMTJournalFilePath]]];
}

- (IBAction)toggleInfoSection:(id)sender
{
    BOOL isEnabled = [_userDefaults boolForKey:kMTDefaultsJournalSummaryEnabledKey];

    NSSplitViewController *splitViewController = (NSSplitViewController*)[self parentViewController];
    
    if (splitViewController) {
        
        if (isEnabled) {
            
            // save the divider position
            if (sender) {
                
                float position = NSHeight([[self view] frame]);
                
                if (position > 0) {
                    [_userDefaults setFloat:position forKey:kMTDefaultsJournalDividerPositionKey];
                }
            }
            
            [[[splitViewController splitViewItems] lastObject] setCollapsed:YES];
            
        } else {
            
            // get saved divider position
            float position = [_userDefaults floatForKey:kMTDefaultsJournalDividerPositionKey];
            [[[splitViewController splitViewItems] lastObject] setCollapsed:NO];
            
            if (position > 0) {
                [[splitViewController splitView] setPosition:position ofDividerAtIndex:0];
            }
        }
    }
    
    if (sender) {
        [_userDefaults setBool:!isEnabled forKey:kMTDefaultsJournalSummaryEnabledKey];
    }
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self inspectorUpdateConsumptionSummary];
}

- (BOOL)tableView:(NSTableView *)tableView userCanChangeVisibilityOfTableColumn:(NSTableColumn *)column
{
    return YES;
}

#pragma mark NSToolbarItemValidation

- (BOOL)enableToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = NO;
    
    if (item) {

        if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleSaveItemIdentifier]) {
            
            // disable the save button if no log entries are shown
            enable = ([[_journalController arrangedObjects] count] > 0) ? YES : NO;
            
        } else if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleReloadItemIdentifier]) {
         
            enable = YES;
            
        } else if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleInfoItemIdentifier]) {
            
            MTToolbarItem *toolbarItem = (MTToolbarItem*)item;
            
            if ([toolbarItem button]) {
                
                [[toolbarItem button] setState:([_userDefaults boolForKey:kMTDefaultsJournalSummaryEnabledKey]) ? NSControlStateValueOn : NSControlStateValueOff];
            }
            
            enable = YES;
        }
    }
        
    return enable;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMTDefaultsShowPriceKey] ||
        [keyPath isEqualToString:kMTDefaultsElectricityPriceKey] ||
        [keyPath isEqualToString:kMTDefaultsAltElectricityPriceKey]) {
        
        [self inspectorUpdateConsumptionSummary];
    }
}

@end
