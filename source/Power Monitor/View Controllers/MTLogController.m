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

#import "MTLogController.h"
#import "MTDaemonConnection.h"
#import "MTSystemInfo.h"
#import "MTToolbarItem.h"
#import "Constants.h"

@interface MTLogController ()
@property (nonatomic, strong, readwrite) MTDaemonConnection *daemonConnection;
@property (nonatomic, strong, readwrite) NSMutableArray *logEntries;
@property (nonatomic, strong, readwrite) NSString *searchFieldContent;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (assign) BOOL logIsRefreshing;

@property (weak) IBOutlet NSTableView *logTableView;
@property (weak) IBOutlet NSArrayController *logController;
@end

@implementation MTLogController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _userDefaults = [NSUserDefaults standardUserDefaults];
    [_logTableView setAccessibilityLabel:NSLocalizedString(@"accessiblilityLabelLogTableView", nil)];
    
    _logEntries = [[NSMutableArray alloc] init];
    NSSortDescriptor *initialSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES selector:@selector(compare:)];
    [self.logController setSortDescriptors:[NSArray arrayWithObject:initialSortDescriptor]];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(measurementClicked:)
                                                 name:kMTNotificationNamePowerTimeStamp
                                               object:nil
    ];
    
    [self toggleInfoSection:nil];
    [self getLogEntriesFromDaemon];
}

- (void)getLogEntriesFromDaemon
{
    self.logIsRefreshing = YES;
    
    _daemonConnection = [[MTDaemonConnection alloc] init];
    [_daemonConnection connectToDaemonWithExportedObject:nil
                                  andExecuteCommandBlock:^{
        
        // get the logs starting from the first measurement's timestamp
        NSDate *startDate = [self->_userDefaults objectForKey:kMTDefaultsMeasurementStartDateKey];
        
        [[self->_daemonConnection remoteObjectProxy] logEntriesSinceDate:startDate
                                                       completionHandler:^(NSArray<OSLogEntry*> *entries) {
           
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.logEntries = [NSMutableArray arrayWithArray:entries];
                
                // filter messages if configured
                if ([self->_userDefaults boolForKey:kMTDefaultsLogFilterEnabledKey]) {
                    [self filterLogMessages:nil];
                }
                
                NSInteger selectIndex = [[self->_logController arrangedObjects] count] - 1;
                
                if (selectIndex >= 0) {
                    [self.logController setSelectionIndex:selectIndex];
                    [self.logTableView scrollRowToVisible:selectIndex];
                }
                
                [[[self view] window] update];
                self.logIsRefreshing = NO;
            });
            
        }];
    }];
}

- (void)measurementClicked:(NSNotification*)notification
{
    if ([[[self view] window] isVisible] && [_userDefaults boolForKey:kMTDefaultsLogFollowCursorKey]) {
        
        NSDate *selectedTimeStamp = [[notification userInfo] objectForKey:kMTNotificationKeyPowerTimeStamp];

        if (selectedTimeStamp) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date <= %@", selectedTimeStamp];
            NSIndexSet *indexSet = [[_logController arrangedObjects] indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                return [predicate evaluateWithObject:obj];
            }];
            
            NSInteger selectIndex = [indexSet lastIndex];
            
            if (selectIndex >= 0 && selectIndex < [[_logController arrangedObjects] count]) {
                
                [self.logController setSelectionIndex:selectIndex];
                [self.logTableView scrollRowToVisible:selectIndex];
            }
        }
    }
}

#pragma mark IBActions

- (IBAction)updateContent:(id)sender
{
    [self getLogEntriesFromDaemon];
}

- (IBAction)searchLogMessages:(id)sender
{
    if ([[sender class] isEqualTo:[NSSearchField class]]) {

        NSSearchField *searchField = (NSSearchField*)sender;
        _searchFieldContent = [searchField stringValue];
        NSPredicate *predicate = [self composePredicateWithString:_searchFieldContent
                                                   applyingFilter:[_userDefaults boolForKey:kMTDefaultsLogFilterEnabledKey]
        ];
        
        id selectedObject = [[_logController selectedObjects] firstObject];
        [self.logController setFilterPredicate:predicate];
        NSInteger newIndex = [[_logController arrangedObjects] indexOfObject:selectedObject];
        
        if (newIndex != NSNotFound) { [self.logTableView scrollRowToVisible:newIndex]; }
        
        [[[self view] window] update];
    }
}

- (IBAction)filterLogMessages:(id)sender
{
    NSPredicate *predicate = [self composePredicateWithString:_searchFieldContent
                                               applyingFilter:[_userDefaults boolForKey:kMTDefaultsLogFilterEnabledKey]
    ];
    
    id selectedObject = [[_logController selectedObjects] firstObject];
    [self.logController setFilterPredicate:predicate];
    NSInteger newIndex = [[_logController arrangedObjects] indexOfObject:selectedObject];
    
    if (newIndex != NSNotFound) { [self.logTableView scrollRowToVisible:newIndex]; }
    
    [[[self view] window] update];
}

- (NSPredicate*)composePredicateWithString:(NSString*)string applyingFilter:(BOOL)filter
{
    NSMutableArray *predicatesArray = [[NSMutableArray alloc] init];
    
    if ([string length] > 0) {
        [predicatesArray addObject:[NSPredicate predicateWithFormat:@"composedMessage CONTAINS[c] %@", string]];
    }
    
    if (filter) {
        [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(composedMessage CONTAINS[c] %@ OR composedMessage CONTAINS[c] %@) AND NOT composedMessage BEGINSWITH %@",
                                    @"wake",
                                    @"sleep",
                                    @"Cancelling notification"
                                    ]
        ];
    }
    
    NSPredicate *predicate = nil;
    
    if ([predicatesArray count] > 0) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
    }
    
    return predicate;
}

- (IBAction)toggleInfoSection:(id)sender
{
    BOOL isEnabled = [_userDefaults boolForKey:kMTDefaultsLogDetailsEnabledKey];
    
    NSSplitViewController *splitViewController = (NSSplitViewController*)[self parentViewController];
    
    if (splitViewController) {
        
        if (isEnabled) {
            
            // save the divider position
            if (sender) {
                
                float position = NSHeight([[self view] frame]);
                
                if (position > 0) {
                    [_userDefaults setFloat:position forKey:kMTDefaultsLogDividerPositionKey];
                }
            }
            
            [[[splitViewController splitViewItems] lastObject] setCollapsed:YES];
            
        } else {
            
            // get saved divider position
            float position = [_userDefaults floatForKey:kMTDefaultsLogDividerPositionKey];
            [[[splitViewController splitViewItems] lastObject] setCollapsed:NO];
            
            if (position > 0) {
                [[splitViewController splitView] setPosition:position ofDividerAtIndex:0];
            }
        }
    }
    
    if (sender) {
        [_userDefaults setBool:!isEnabled forKey:kMTDefaultsLogDetailsEnabledKey];
    }
}

- (IBAction)saveContent:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:NSLocalizedString(@"logFileName", nil)];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == NSModalResponseOK) {
            
            NSError *error = nil;
            NSMutableString *logString = [[NSMutableString alloc] init];
                                
            for (OSLogEntryLog *logEntry in [self->_logController arrangedObjects]) {
                
                // create the timestamp
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSZ"];
                NSString *dateString = [dateFormatter stringFromDate:[logEntry date]];
                
                // create the level string
                NSString *levelString = nil;
                switch ([logEntry level]) {
                        
                    case OSLogEntryLogLevelDebug:
                        levelString = @"DEBUG";
                        break;
                        
                    case OSLogEntryLogLevelInfo:
                        levelString = @"INFO";
                        break;
                        
                    case OSLogEntryLogLevelNotice:
                        levelString = @"NOTICE";
                        break;
                        
                    case OSLogEntryLogLevelError:
                        levelString = @"ERROR";
                        break;
                        
                    case OSLogEntryLogLevelFault:
                        levelString = @"FAULT";
                        break;
                        
                    default:
                        levelString = @"UNDEFINED";
                        break;
                }
                
                NSString *logEntryString = [NSString stringWithFormat:@"%@   %@ %@[%d]: %@\n", 
                                            dateString,
                                            [levelString stringByPaddingToLength:11 withString:@" " startingAtIndex:0],
                                            [logEntry process],
                                            [logEntry processIdentifier],
                                            [logEntry composedMessage]
                ];
                [logString appendString:logEntryString];
            }
            
            [logString writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                
                os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "SAPCorp: Unable to save log file: %{public}@", error);
                
                NSAlert *theAlert = [[NSAlert alloc] init];
                [theAlert setMessageText:NSLocalizedString(@"dialogFailedToSaveLogTitle", nil)];
                [theAlert setInformativeText:NSLocalizedString(@"dialogFailedToSaveLogMessage", nil)];
                [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                [theAlert setAlertStyle:NSAlertStyleCritical];
                [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
            }
        }
    }];
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSArray *selectedObjects = [_logController selectedObjects];
    
    if ([selectedObjects count] > 0) {
        
        OSLogEntry *entry = (OSLogEntry*)[selectedObjects firstObject];
        NSString *logMessage = [entry composedMessage];
        
        if (logMessage) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameLogMessage
                                                                object:nil
                                                              userInfo:[NSDictionary dictionaryWithObject:logMessage
                                                                                                   forKey:kMTNotificationKeyLogMessage
                                                                       ]
            ];
        }
    }
}

#pragma mark NSToolbarItemValidation

- (BOOL)enableToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = NO;
    
    if (item) {
        
        // we disable all toolbar items while the log is reloaded
        // and if there are no log entries
        if (!_logIsRefreshing && [_logEntries count] > 0) {
            
            if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleSaveItemIdentifier]) {
                
                // disable the save button if no log entries are shown
                enable = ([[_logController arrangedObjects] count] > 0) ? YES : NO;
                
            } else {
                
                enable = YES;
            }
        }
        
        if ([[item itemIdentifier] isEqualToString:MTToolbarConsoleInfoItemIdentifier]) {
            
            MTToolbarItem *toolbarItem = (MTToolbarItem*)item;
            
            if ([toolbarItem button]) {
                
                [[toolbarItem button] setState:([_userDefaults boolForKey:kMTDefaultsLogDetailsEnabledKey]) ? NSControlStateValueOn : NSControlStateValueOff];
            }
        }
    }
        
    return enable;
}

@end
