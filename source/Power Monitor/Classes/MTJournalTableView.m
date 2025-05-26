/*
     MTJournalTableView.m
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

#import "MTJournalTableView.h"

@implementation MTJournalTableView

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    [super menuForEvent:event];
    
    NSInteger clickedRow = [self clickedRow];
                
    // add an item for deleting one or more journal entries
    NSMenuItem *removeItem = [[self menu] itemWithTag:1000];
    
    if (clickedRow >= 0) {
        
        if ([[self selectedRowIndexes] containsIndex:clickedRow] && [[self selectedRowIndexes] count] > 1) {
            [removeItem setTitle:NSLocalizedString(@"deleteJournalMultipleMenuEntry", nil)];
        } else {
            [removeItem setTitle:NSLocalizedString(@"deleteJournalOneMenuEntry", nil)];
        }
        
        [removeItem setHidden:NO];

    } else {
        
        [removeItem setHidden:YES];
    }
    
    return [self menu];
}

@end
