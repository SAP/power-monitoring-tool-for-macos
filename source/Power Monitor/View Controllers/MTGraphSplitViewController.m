/*
     MTGraphSplitViewController.m
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

#import "MTGraphSplitViewController.h"
#import "MTPowerGraphController.h"
#import "MTPowerGraphInspectorController.h"
#import "Constants.h"

@implementation MTGraphSplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    NSSplitViewItem *contentItem = [[self splitViewItems] firstObject];
    NSSplitViewItem *inspectorItem = [[self splitViewItems] lastObject];
    
    // set a delegate so we can pass data to our inspector
    MTPowerGraphController *contentController = (MTPowerGraphController*)[contentItem viewController];
    MTPowerGraphInspectorController *inspectorController = (MTPowerGraphInspectorController*)[inspectorItem viewController];
    [contentController setDelegate:inspectorController];
    
    // set the minimum width for the inspector
    [inspectorItem setMinimumThickness:150];
}

- (IBAction)showOrHideInspector:(id)sender;
{
    // we could get all of this for free in macOS 14+ but as we
    // also support macOS 13, we have to build this by ourselves…
    NSSplitViewItem *inspectorItem = [[self splitViewItems] lastObject];
    [[inspectorItem animator] setCollapsed:![inspectorItem isCollapsed]];
}

#pragma mark NSToolbarItemValidation

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = NO;

    // we always enable the toggle sidebar item
    if ([[item itemIdentifier] isEqualToString:@"MTToolbarGraphInspectorItem"]) {

        [item setTarget:self];
        enable = YES;
        
    } else {
        
        // get our content view's first view controller
        id contentViewController = [[self childViewControllers] firstObject];
        
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
