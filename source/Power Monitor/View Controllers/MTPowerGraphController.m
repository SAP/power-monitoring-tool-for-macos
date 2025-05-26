/*
     MTPowerGraphController.m
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

#import "MTPowerGraphController.h"
#import "Constants.h"

@interface MTPowerGraphController ()
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSSlider *magnificationSlider;

@property (nonatomic, strong, readwrite) MTPowerGraphView* powerGraphView;
@end

@implementation MTPowerGraphController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    _powerGraphView = [[MTPowerGraphView alloc] init];
    
    [_scrollView setPostsFrameChangedNotifications:YES];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDetailView:)
                                                 name:kMTNotificationNameGraphReloadData
                                               object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inspectorUpdatePowerData:)
                                                 name:kMTNotificationNameGraphPositionUpdated
                                               object:_powerGraphView
    ];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inspectorPinChanged:)
                                                 name:kMTNotificationNameGraphPinChanged
                                               object:_powerGraphView
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inspectorShowOrHidePowerData:)
                                                 name:kMTNotificationNameGraphMouseEntered
                                               object:_powerGraphView
    ];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inspectorShowOrHidePowerData:)
                                                 name:kMTNotificationNameGraphMouseExited
                                               object:_powerGraphView
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[_scrollView contentView]
    ];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    if (_delegate && [_delegate respondsToSelector:@selector(graphView:didSelectMeasurement:)]) {
        [_delegate graphView:_powerGraphView didSelectMeasurement:nil];
    }
}

- (void)addGraphView
{
    [_powerGraphView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_powerGraphView setAllowPinning:YES];
    [_powerGraphView setAllowToolTip:NO];
    [_powerGraphView setPostPositionChangedNotification:YES];
    
    [_scrollView setMagnification:1];
    [_magnificationSlider setDoubleValue:[_magnificationSlider minValue]];
    [_scrollView setDocumentView:_powerGraphView];
    
    // add constraints
    NSLayoutConstraint *documentViewLeft = [NSLayoutConstraint constraintWithItem:[_scrollView documentView]
                                                                        attribute:NSLayoutAttributeLeading
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_scrollView
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1
                                                                         constant:0];
        
    NSLayoutConstraint *documentViewRight = [NSLayoutConstraint constraintWithItem:[_scrollView documentView]
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_scrollView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1
                                                                          constant:0];
    
    NSLayoutConstraint *documentViewTop = [NSLayoutConstraint constraintWithItem:[_scrollView documentView]
                                                                       attribute:NSLayoutAttributeTop
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_scrollView
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1
                                                                        constant:0];

    NSLayoutConstraint *documentViewBottom = [NSLayoutConstraint constraintWithItem:[_scrollView documentView]
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:_scrollView
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1
                                                                           constant:0];

    [_scrollView addConstraints:[NSArray arrayWithObjects:documentViewLeft, documentViewRight, documentViewTop, documentViewBottom, nil]];
}

#pragma mark NSNotification handlers

- (void)updateDetailView:(NSNotification*)notification
{
    MTPowerGraphView *graphView = [[notification userInfo] objectForKey:kMTNotificationKeyGraphData];
    
    if (graphView && [graphView isKindOfClass:[MTPowerGraphView class]]) {
                
        [_powerGraphView setView:graphView];
        [self addGraphView];
    }
}

- (void)inspectorUpdatePowerData:(NSNotification*)notification
{
    if (_delegate && [_delegate respondsToSelector:@selector(graphView:didSelectMeasurement:)]) {
        
        MTPowerMeasurement *measurement = (MTPowerMeasurement*)[[notification userInfo] objectForKey:kMTNotificationKeyGraphPosition];
        [_delegate graphView:_powerGraphView didSelectMeasurement:measurement];
    }
}

- (void)inspectorPinChanged:(NSNotification*)notification
{
    if (_delegate && [_delegate respondsToSelector:@selector(graphView:didChangePinning:)]) {
        [_delegate graphView:_powerGraphView didChangePinning:[_powerGraphView isPinned]];
    }
}

- (void)inspectorShowOrHidePowerData:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:kMTNotificationNameGraphMouseEntered]) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(mouseEnteredGraphView:)]) {
            [_delegate mouseEnteredGraphView:_powerGraphView];
        }
        
    } else if ([[notification name] isEqualToString:kMTNotificationNameGraphMouseExited]) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(mouseExitedGraphView:)]) {
            [_delegate mouseExitedGraphView:_powerGraphView];
        }
    }
}

- (void)frameDidChange:(NSNotification*)notification
{
    if ([_powerGraphView isPinned]) {
        
        NSRect visibleRect = [_scrollView documentVisibleRect];

        [[_scrollView contentView] scrollPoint:NSMakePoint(
                                                           [_powerGraphView pinnedPosition].x - (NSWidth(visibleRect) / 2),
                                                           [_powerGraphView pinnedPosition].y
                                                           )
        ];
    }
}

#pragma mark NSToolbarItemValidation

- (BOOL)enableToolbarItem:(NSToolbarItem *)item
{
    BOOL enable = YES;
    
    if (item) {

        id view = [item view];
        
        if ([view isKindOfClass:[NSButton class]]) {
        
            NSButton *itemButton = (NSButton*)view;
            
            if ([[item itemIdentifier] isEqualToString:MTToolbarGraphAverageLineItemIdentifier]) {
                
                [itemButton setState:([_powerGraphView showAverage]) ? NSControlStateValueOn : NSControlStateValueOff];
                
            } else if ([[item itemIdentifier] isEqualToString:MTToolbarGraphDayMarkerItemIdentifier]) {
                
                [itemButton setState:([_powerGraphView showDayMarkers]) ? NSControlStateValueOn : NSControlStateValueOff];
                
            } else if ([[item itemIdentifier] isEqualToString:MTToolbarGraphPowerNapItemIdentifier]) {
                
                [itemButton setState:([_powerGraphView showPowerNaps]) ? NSControlStateValueOn : NSControlStateValueOff];
            }
        }
    }
        
    return enable;
}

#pragma mark IBActions

- (IBAction)graphShowAverage:(id)sender
{
    [_powerGraphView setShowAverage:![_powerGraphView showAverage]];
    [_powerGraphView setNeedsDisplay:YES];
}

- (IBAction)graphShowDayMarkers:(id)sender
{
    [_powerGraphView setShowDayMarkers:![_powerGraphView showDayMarkers]];
    [_powerGraphView setNeedsDisplay:YES];
}

- (IBAction)graphShowPowerNaps:(id)sender
{
    [_powerGraphView setShowPowerNaps:![_powerGraphView showPowerNaps]];
    [_powerGraphView setNeedsDisplay:YES];
}

- (IBAction)zoomGraphView:(id)sender
{
    CGFloat height = NSHeight([[_scrollView contentView] bounds]);
    NSRect visibleRect = [_scrollView documentVisibleRect];
    
    if ([_powerGraphView isPinned]) {
        
        [_scrollView setMagnification:[sender doubleValue] centeredAtPoint:[_powerGraphView pinnedPosition]];
        
    } else {
        
        [_scrollView setMagnification:[sender doubleValue]];
    }
    
    [[_scrollView contentView] setBoundsSize:NSMakeSize(
                                                        NSWidth([[_scrollView contentView] bounds]),
                                                        height
                                                        )
    ];
    
    [_powerGraphView setNeedsDisplay:YES];

    if (![_powerGraphView isPinned]) {
        [[_scrollView contentView] scrollPoint:visibleRect.origin];
    }
}

@end
