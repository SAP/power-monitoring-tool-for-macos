/*
     MTSidebarController.m
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

#import "MTSidebarController.h"
#import "MTSidebarItem.h"

@interface MTSidebarController ()
@property (nonatomic, strong, readwrite) NSArray *orderedGroupItems;
@property (nonatomic, strong, readwrite) NSMutableDictionary *allSidebarItems;
@property (nonatomic, strong, readwrite) NSMutableDictionary *allViewControllers;

@property (weak) IBOutlet NSOutlineView *sidebarOutlineView;
@end

@implementation MTSidebarController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    _allSidebarItems = [[NSMutableDictionary alloc] init];
    _allViewControllers = [[NSMutableDictionary alloc] init];

    MTSidebarItem *logItem = [[MTSidebarItem alloc] init];
    [logItem setLabel:NSLocalizedString(@"sidebarEntryPowerEventLog", nil)];
    [logItem setImage:[NSImage imageWithSystemSymbolName:@"bolt" accessibilityDescription:nil]];
    [logItem setTargetViewControllerIdentifier:@"corp.sap.PowerMonitor.PowerEventLog"];

    MTSidebarItem *preventItem = [[MTSidebarItem alloc] init];
    [preventItem setLabel:NSLocalizedString(@"sidebarEntryPreventingSleep", nil)];
    [preventItem setImage:[NSImage imageWithSystemSymbolName:@"exclamationmark.triangle" accessibilityDescription:nil]];
    [preventItem setTargetViewControllerIdentifier:@"corp.sap.PowerMonitor.AppsPreventingSleep"];
    
    MTSidebarItem *powerInfoItem = [[MTSidebarItem alloc] init];
    [powerInfoItem setLabel:NSLocalizedString(@"sidebarEntryPowerInfo", nil)];
    [powerInfoItem setImage:[NSImage imageWithSystemSymbolName:@"minus.plus.batteryblock" accessibilityDescription:nil]];
    [powerInfoItem setTargetViewControllerIdentifier:@"corp.sap.PowerMonitor.PowerInfo"];
    
    MTSidebarItem *journalItem = [[MTSidebarItem alloc] init];
    [journalItem setLabel:NSLocalizedString(@"sidebarEntryJournal", nil)];
    [journalItem setImage:[NSImage imageWithSystemSymbolName:@"book" accessibilityDescription:nil]];
    [journalItem setTargetViewControllerIdentifier:@"corp.sap.PowerMonitor.Journal"];

    [_allSidebarItems setObject:[NSArray arrayWithObjects:logItem, nil]
                         forKey:NSLocalizedString(@"sidebarEntryLogs", nil)
    ];

    [_allSidebarItems setObject:[NSArray arrayWithObjects:preventItem, powerInfoItem, journalItem, nil]
                         forKey:NSLocalizedString(@"sidebarEntryReports", nil)
    ];

    // this array must contain all the keys of the allSidebarItems
    // dictionary in the order they should be displayed
    _orderedGroupItems = [NSArray arrayWithObjects:
                          NSLocalizedString(@"sidebarEntryLogs", nil),
                          NSLocalizedString(@"sidebarEntryReports", nil),
                          nil
    ];

    [[_sidebarOutlineView outlineTableColumn] setWidth:NSWidth([_sidebarOutlineView bounds])];
    [_sidebarOutlineView reloadData];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [_sidebarOutlineView expandItem:nil expandChildren:YES];
    [NSAnimationContext endGrouping];
}

- (NSArray*)childrenForItem:(id)item
{
    NSArray *childItems = nil;
    
    if (!item) {
        
        childItems = _orderedGroupItems;
        
    } else {
        
        NSString *itemLabel = ([item isKindOfClass:[MTSidebarItem class]]) ? [item label] : item;
        childItems = [_allSidebarItems objectForKey:itemLabel];
    }

    return childItems;
}

#pragma mark NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    id returnValue = nil;
    
    NSString *itemLabel = ([item isKindOfClass:[MTSidebarItem class]]) ? [item label] : item;

    if ([[_allSidebarItems allKeys] containsObject:itemLabel]) {

        NSTextField *headerTextField = [outlineView makeViewWithIdentifier:@"HeaderTextField" owner:self];
        [headerTextField setStringValue:itemLabel];
        returnValue = headerTextField;
        
    } else {
        
        NSTableCellView *mainCellView = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        [[mainCellView textField] setStringValue:itemLabel];

        if ([item isKindOfClass:[MTSidebarItem class]]) {
            NSImage *itemImage = [item image];
            if ([itemImage isValid]) { [[mainCellView imageView] setImage:itemImage]; }
        }

        returnValue = mainCellView;
    }
    
    return returnValue;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    if (row == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:1]
                     byExtendingSelection:YES];
        });
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return ([[_allSidebarItems allKeys] containsObject:item]) ? NO : YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [[_allSidebarItems allKeys] containsObject:item];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if ([_sidebarOutlineView selectedRow] != -1) {
        
        id selectedItem = [_sidebarOutlineView itemAtRow:[_sidebarOutlineView selectedRow]];
        
        if ([selectedItem isKindOfClass:[MTSidebarItem class]] && [_sidebarOutlineView parentForItem:selectedItem] && [selectedItem targetViewControllerIdentifier]) {
            
            NSViewController *targetViewController = [_allViewControllers objectForKey:[selectedItem targetViewControllerIdentifier]];
            
            if (!targetViewController) {
                targetViewController = [[self storyboard] instantiateControllerWithIdentifier:[selectedItem targetViewControllerIdentifier]];
                
                if (targetViewController) {
                    [_allViewControllers setObject:targetViewController forKey:[selectedItem targetViewControllerIdentifier]];
                }
            }
            
            if (targetViewController) {
                
                NSSplitViewItem *splitViewItem = [NSSplitViewItem splitViewItemWithViewController:targetViewController];
                NSSplitViewController *splitViewController = (NSSplitViewController*)[self parentViewController];
                [splitViewController removeSplitViewItem:[[splitViewController splitViewItems] lastObject]];
                [splitViewController addSplitViewItem:splitViewItem];
            }
        }
    }
}

#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return [[self childrenForItem:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return ([outlineView parentForItem:item]) ? NO : YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return [[self childrenForItem:item] count];
}

@end
