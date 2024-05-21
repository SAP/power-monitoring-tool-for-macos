/*
     MTPowerGraphView.m
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

#import "MTPowerGraphView.h"
#import "MTPowerGraphTooltip.h"
#import "Constants.h"
#import <QuartzCore/CAShapeLayer.h>

@interface MTPowerGraphView ()
@property (nonatomic, strong, readwrite) CAShapeLayer *graphLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *powerNapLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *dayMarkerLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *averageLineLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *positionLineLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *positionLineLockLayer;
@property (nonatomic, strong, readwrite) NSTrackingArea *trackingArea;
@property (nonatomic, strong, readwrite) MTPowerGraphTooltip *tooltipWindow;
@property (nonatomic, strong, readwrite) MTPowerMeasurement *pinnedMeasurement;
@property (assign) NSInteger currentPosititon;
@property (assign) CGFloat lineWidth;
@property (assign) BOOL insideTrackingArea;
@property (assign) BOOL isPinned;
@property (assign) NSPoint pinnedPosition;
@end

@implementation MTPowerGraphView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) { [self setUpView]; }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) { [self setUpView]; }
    
    return self;
}

- (void)setUpView
{
    [self setWantsLayer:YES];
    [[self layer] setDrawsAsynchronously:YES];
    
    CGFloat scaleFactor = [[self layer] contentsScale];

    _graphLayer = [CAShapeLayer layer];
    [_graphLayer setContentsScale:scaleFactor];
    [_graphLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_graphLayer setFrame:[self bounds]];
    [_graphLayer setDelegate:self];
    _graphColor = [NSColor systemGreenColor];
    
    _powerNapLayer = [CAShapeLayer layer];
    [_powerNapLayer setContentsScale:scaleFactor];
    [_powerNapLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_powerNapLayer setFrame:[self bounds]];
    [_powerNapLayer setDelegate:self];
    _powerNapColor = [NSColor systemYellowColor];
    
    _dayMarkerLayer = [CAShapeLayer layer];
    [_dayMarkerLayer setContentsScale:scaleFactor];
    [_dayMarkerLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_dayMarkerLayer setFrame:[self bounds]];
    [_dayMarkerLayer setDelegate:self];
    _dayMarkerColor = [NSColor systemYellowColor];
    
    _averageLineLayer = [CAShapeLayer layer];
    [_averageLineLayer setContentsScale:scaleFactor];
    [_averageLineLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_averageLineLayer setFrame:[self bounds]];
    [_averageLineLayer setLineWidth:1];
    [_averageLineLayer setDelegate:self];
    _averageLineColor = [NSColor systemRedColor];
    
    _positionLineColor = [NSColor systemPurpleColor];
    _positionLineLayer = [CAShapeLayer layer];
    [_positionLineLayer setContentsScale:scaleFactor];
    [_positionLineLayer setAutoresizingMask:kCALayerHeightSizable];
    [_positionLineLayer setBackgroundColor:[_positionLineColor CGColor]];
    [_positionLineLayer setDelegate:self];
    
    _positionLineLockLayer = [CAShapeLayer layer];
    [_positionLineLockLayer setContentsScale:scaleFactor];
    [_positionLineLockLayer setAutoresizingMask:kCALayerHeightSizable];
    [_positionLineLockLayer setBackgroundColor:[_positionLineColor CGColor]];
    [_positionLineLockLayer setDelegate:self];
    
    _currentPosititon = -1;
    
    [[self layer] setSublayers:[NSArray arrayWithObjects:
                                _graphLayer,
                                _powerNapLayer,
                                _dayMarkerLayer,
                                _averageLineLayer,
                                _positionLineLockLayer,
                                _positionLineLayer,
                                nil
                               ]
    ];
    
    _tooltipWindow = [[MTPowerGraphTooltip alloc] init];
}

- (void)setView:(MTPowerGraphView*)view
{
    if (view && [view isKindOfClass:[MTPowerGraphView class]]) {
  
        _measurementData = [[view measurementData] copy];
        _showAverage = [view showAverage];
        _showDayMarkers = [view showDayMarkers];
        _showPowerNaps = [view showPowerNaps];
        _graphColor = [view graphColor];
        _averageLineColor = [view averageLineColor];
        _dayMarkerColor = [view dayMarkerColor];
        _powerNapColor = [view powerNapColor];
        _positionLineColor = [view positionLineColor];
        _allowPinning = [view allowPinning];
        _isPinned = [view isPinned];
        _pinnedPosition = [view pinnedPosition];
        _pinnedMeasurement = [view pinnedMeasurement];
        _allowToolTip = [view allowToolTip];
        
        [self setNeedsDisplay:YES];
    }
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    // disable all implicit animations
    return [NSNull null];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if (_trackingArea) { [self removeTrackingArea:_trackingArea]; }
    
    NSTrackingAreaOptions options = (
                                     NSTrackingMouseEnteredAndExited |
                                     NSTrackingMouseMoved |
                                     NSTrackingActiveInKeyWindow
                                     );
        
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:options
                                                   owner:self
                                                userInfo:nil
    ];
    
    [self addTrackingArea:_trackingArea];
}

- (void)viewDidMoveToWindow
{
    // make sure our tooltip window is closed
    // if our parent window is closed
    if ([self window]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[self window]
        ];
    }
}

- (void)dealloc
{
    if ([_tooltipWindow isVisible]) { [_tooltipWindow close]; }
}

- (void)windowWillClose:(NSNotification*)notification 
{
    if ([_tooltipWindow isVisible]) { [_tooltipWindow close]; }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSInteger measurementsCount = [_measurementData count];
    
    if (measurementsCount > 0) {
        
        CGFloat scaleFactor = [[self layer] contentsScale];
        _lineWidth = (scaleFactor > 1) ? 2.0 / scaleFactor : 1;
        [_dayMarkerLayer setLineWidth:_lineWidth];
        [_graphLayer setLineWidth:_lineWidth / 10.0];
        [_powerNapLayer setLineWidth:_lineWidth / 10.0];

        CGMutablePathRef linePath = CGPathCreateMutable();
        CGMutablePathRef powerNapPath = CGPathCreateMutable();
        
        MTPowerMeasurement *maxValue = [_measurementData maximumPower];
        MTPowerMeasurement *avgValue = [_measurementData averagePower];
        
        float maxX = (measurementsCount == 1) ? 1 : measurementsCount - 1;
        float maxY = [maxValue doubleValue] * 1.1;
        
        CGPathMoveToPoint(linePath, NULL, 0, 0);
        CGPathMoveToPoint(powerNapPath, NULL, 0, 0);
        
        __block BOOL isNapping = NO;
        __block NSDate *lastDate = nil;
        __block NSMutableArray *dayMarkers = [[NSMutableArray alloc] init];
        
        [_measurementData enumerateObjectsUsingBlock:^(MTPowerMeasurement *obj, NSUInteger idx, BOOL *stop) {
            
            float x = NSWidth([self bounds]) / maxX * idx;
            float y = NSHeight([self bounds]) / maxY * [obj doubleValue];
            
            CGPathAddLineToPoint(linePath, NULL, x, y);
            
            if (_showPowerNaps) {
                
                if ([obj darkWake]) {
                    
                    if (!isNapping) {
                        CGPathAddLineToPoint(powerNapPath, NULL, x, 0);
                        isNapping = YES;
                    }
                    
                    CGPathAddLineToPoint(powerNapPath, NULL, x, y);
                    
                } else {
                    
                    if (isNapping) {
                        CGPathAddLineToPoint(powerNapPath, NULL, x, y);
                        isNapping = NO;
                    }
                    
                    CGPathAddLineToPoint(powerNapPath, NULL, x, 0);
                }
            }
            
            // day markers
            if (_showDayMarkers) {
                
                time_t timestamp = [obj timeStamp];
                
                if (timestamp > 0) {
                    
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    
                    if (lastDate) {
                        
                        if ([[NSCalendar currentCalendar] compareDate:lastDate toDate:date toUnitGranularity:NSCalendarUnitDay] == NSOrderedAscending) {
                            
                            lastDate = date;
                            [dayMarkers addObject:[NSNumber numberWithFloat:x]];
                        }
                        
                    } else {
                        
                        lastDate = date;
                    }
                }
                
            } else {
                
                [_dayMarkerLayer setHidden:YES];
            }
        }];
        
        if (maxX == 1) { CGPathAddLineToPoint(linePath, NULL, NSWidth([self bounds]), NSHeight([self bounds]) / maxY * [[_measurementData firstObject] doubleValue]); }
        CGPathAddLineToPoint(linePath, NULL, NSWidth([self bounds]), 0);
        CGPathCloseSubpath(linePath);
        
        [_graphLayer setPath:linePath];
        [_graphLayer setFillColor:[_graphColor CGColor]];
        [_graphLayer setStrokeColor:[_graphColor CGColor]];
        
        CGPathRelease(linePath);
        
        if (_showPowerNaps) {
            
            CGPathAddLineToPoint(powerNapPath, NULL, NSWidth([self bounds]), 0);
            CGPathCloseSubpath(powerNapPath);
            
            [_powerNapLayer setPath:powerNapPath];
            [_powerNapLayer setFillColor:[_powerNapColor CGColor]];
            [_powerNapLayer setStrokeColor:[_powerNapColor CGColor]];
            [_powerNapLayer setHidden:NO];
            
        } else {
            
            [_powerNapLayer setHidden:YES];
        }

        CGPathRelease(powerNapPath);
        
        // day markers
        if ([dayMarkers count] > 0) {
            
            [_dayMarkerLayer setSublayers:nil];
            
            for (NSNumber *x in dayMarkers) {
                
                CAShapeLayer *aDayMakerLayer = [CAShapeLayer layer];
                [aDayMakerLayer setContentsScale:scaleFactor];
                [aDayMakerLayer setAutoresizingMask:kCALayerHeightSizable];
                [aDayMakerLayer setBackgroundColor:[_dayMarkerColor CGColor]];
                [aDayMakerLayer setFrame:NSMakeRect([x floatValue], 0, _lineWidth, NSHeight([self bounds]))];
                [_dayMarkerLayer addSublayer:aDayMakerLayer];
            }

            [_dayMarkerLayer setHidden:NO];
            
        } else {
            
            [_dayMarkerLayer setHidden:YES];
        }
        
        // average line
        if (_showAverage) {
            
            float y = NSHeight([self bounds]) / maxY * [avgValue doubleValue];
            
            CGMutablePathRef averagePath = CGPathCreateMutable();
            CGPathMoveToPoint(averagePath, NULL, 0, y);
            CGPathAddLineToPoint(averagePath, NULL, NSWidth([self bounds]), y);
            CGPathCloseSubpath(averagePath);
            
            [_averageLineLayer setPath:averagePath];
            [_averageLineLayer setStrokeColor:[_averageLineColor CGColor]];
            [_averageLineLayer setHidden:NO];
            
            CGPathRelease(averagePath);
            
        } else {
            
            [_averageLineLayer setHidden:YES];
        }
        
        // position line
        if (_isPinned) {
                        
            float maxX = [_measurementData count] - 1;
            float x = NSWidth([self bounds]) / maxX * [_measurementData indexOfObject:_pinnedMeasurement];
            if (x == NSWidth([self bounds])) { x--; }
            [_positionLineLockLayer setFrame:NSMakeRect(x, 0, _lineWidth, NSHeight([self bounds]))];
            _pinnedPosition = [_positionLineLockLayer position];
            
        } else {
         
            if (_insideTrackingArea) {
                
                NSPoint cursorPoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
                [self drawPositionLineAtPoint:cursorPoint];
                [_positionLineLayer setHidden:NO];
                
            } else {
                
                // make sure the position layer is not visible anymore
                [_positionLineLayer setHidden:YES];
                [_positionLineLockLayer setHidden:YES];
                [_tooltipWindow close];
            }
        }
        
        [_positionLineLayer setBackgroundColor:[_positionLineColor CGColor]];
        [_positionLineLockLayer setBackgroundColor:[_positionLineColor CGColor]];
    }
}

- (void)drawPositionLineAtPoint:(NSPoint)position
{
    NSInteger measurementsCount = [_measurementData count];
    NSInteger objectPosition = floorf(measurementsCount / NSWidth([self bounds]) * position.x);

    if (objectPosition >= 0 && objectPosition < measurementsCount) {
        
        // we only update the position line if the
        // horizontal mouse position has changed
        if (objectPosition != _currentPosititon) {
            
            _currentPosititon = objectPosition;
            float x = NSWidth([self bounds]) / (measurementsCount - 1) * _currentPosititon;
            [_positionLineLayer setFrame:NSMakeRect(x, 0, _lineWidth, NSHeight([self bounds]))];
        }
        
        // update the tooltip
        if (_allowToolTip) {
            
            [_tooltipWindow setMeasurement:[_measurementData objectAtIndex:_currentPosititon]];
            [_tooltipWindow setFrame:NSMakeRect(
                                                [[self window] frame].origin.x + position.x + 50,
                                                [[self window] frame].origin.y + position.y,
                                                NSWidth([_tooltipWindow frame]),
                                                NSHeight([_tooltipWindow frame])
                                                )
                             display:NO
            ];
            [_tooltipWindow orderFront:nil];
            
        } else if ([_tooltipWindow isVisible]) { [_tooltipWindow close]; }
        
        if (_postPositionChangedNotification) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphPositionUpdated
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:[_measurementData objectAtIndex:_currentPosititon]
                                                                                                   forKey:kMTNotificationKeyGraphPosition
                                                                       ]
            ];
        }
    }
}

- (BOOL)showMeasurement:(MTPowerMeasurement*)measurement withTooltip:(BOOL)tooltip
{
    BOOL success = NO;
    
    if (measurement) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"doubleValue == %lf", [measurement doubleValue]];
        NSArray *filteredArray = [_measurementData filteredArrayUsingPredicate:predicate];
        
        if ([filteredArray count] > 0) {
            
            MTPowerMeasurement *measurement = [filteredArray firstObject];
            
            float maxX = [_measurementData count] - 1;
            float x = NSWidth([self bounds]) / maxX * [_measurementData indexOfObject:measurement];
            if (x == NSWidth([self bounds])) { x--; }
            [_positionLineLayer setFrame:NSMakeRect(x, 0, _lineWidth, NSHeight([self bounds]))];
            success = YES;
            
            if (tooltip) {
                
                // update the tooltip
                [_tooltipWindow setMeasurement:measurement];
                [_tooltipWindow setFrame:NSMakeRect(
                                                    [[self window] frame].origin.x + x + 30,
                                                    [[self window] frame].origin.y + (NSHeight([self frame]) / 2) + (NSHeight([_tooltipWindow frame]) / 2),
                                                    NSWidth([_tooltipWindow frame]),
                                                    NSHeight([_tooltipWindow frame])
                                                    )
                                 display:NO
                ];
                [_tooltipWindow orderFront:nil];
            }
        }
        
        [_positionLineLayer setHidden:NO];
        
    } else {
        
        [_positionLineLayer setHidden:YES];
        [_tooltipWindow close];
        
        success = YES;
    }
    
    return success;
}

- (BOOL)showsPosition
{
    return ![_positionLineLayer isHidden];
}

#pragma mark mouse event handlers

- (void)mouseEntered:(NSEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphMouseEntered
                                                        object:self
                                                      userInfo:nil
    ];
    
    _insideTrackingArea = YES;
    
    NSPoint cursorPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    [self drawPositionLineAtPoint:cursorPoint];
    [_positionLineLayer setHidden:NO];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint cursorPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    [self drawPositionLineAtPoint:cursorPoint];
}

- (void)mouseExited:(NSEvent *)event
{
    // make sure the position layer is not visible anymore
    [_positionLineLayer setHidden:YES];
    
    _currentPosititon = -1;
    _insideTrackingArea = NO;
    
    [_tooltipWindow close];
            
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphMouseExited
                                                        object:self
                                                      userInfo:nil
    ];
}

- (void)mouseDown:(NSEvent *)event
{
    if (_currentPosititon >= 0 && _currentPosititon < [_measurementData count]) {
        
        MTPowerMeasurement *pM = [_measurementData objectAtIndex:_currentPosititon];
        NSDate *timeStamp = [NSDate dateWithTimeIntervalSince1970:[pM timeStamp]];
        
        if (timeStamp) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNamePowerTimeStamp
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:timeStamp
                                                                                                   forKey:kMTNotificationKeyPowerTimeStamp
                                                                       ]
            ];
        }
        
        if (_allowPinning) {
            
            _isPinned = !_isPinned;
            
            if (_isPinned) {
                
                _pinnedPosition = [_positionLineLayer position];
                _pinnedMeasurement = [_measurementData objectAtIndex:_currentPosititon];
                [_positionLineLockLayer setPosition:_pinnedPosition];
                [_positionLineLockLayer setHidden:NO];
                
            } else {
                
                _pinnedPosition = NSZeroPoint;
                _pinnedMeasurement = nil;
                [_positionLineLockLayer setHidden:YES];
            }
            
            [self setNeedsDisplay:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphPinChanged
                                                                object:self
                                                              userInfo:nil
            ];
        }
    }
}

- (void)mouseUp:(NSEvent *)event
{
    if ([event clickCount] == 2) {
    
        [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameGraphShowDetail
                                                            object:self
                                                          userInfo:nil
        ];
    }
}

@end
