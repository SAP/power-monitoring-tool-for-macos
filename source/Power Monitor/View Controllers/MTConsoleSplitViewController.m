/*
     MTConsoleSplitViewController.m
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

#import "MTConsoleSplitViewController.h"

@interface MTConsoleSplitViewController ()

@end

@implementation MTConsoleSplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = NO;
    
    // we always enable the toggle sidebar item
    if ([[item itemIdentifier] isEqualToString:NSToolbarToggleSidebarItemIdentifier]) {

        // call super to make sure the item's tooltip
        // reflects the current state of the sidebar
        [super validateToolbarItem:item];
        enable = YES;
        
    } else {
        
        // get our content view's last view controller
        id contentViewController = [[self childViewControllers] lastObject];
        
        // if the object itself is a split view, get the
        // split view's first view controller
        if ([contentViewController isKindOfClass:[NSSplitViewController class]]) {
            contentViewController = [[contentViewController childViewControllers] firstObject];
        }
        
        // check if the view controller responds to the selector enableToolbarItem:
        // and if so, call the selector with our toolbar item and enable the toolbar
        // item depending on the result
        SEL selector = NSSelectorFromString(@"enableToolbarItem:");
        if (contentViewController && [contentViewController respondsToSelector:selector]) {
            
            NSInvocationOperation *invocation = [[NSInvocationOperation alloc] initWithTarget:contentViewController
                                                                                     selector:selector
                                                                                       object:item
            ];
            [invocation start];
            [[invocation result] getValue:&enable];
            
            [item setTarget:contentViewController];
        }
    }
        
    return enable;
}

@end
