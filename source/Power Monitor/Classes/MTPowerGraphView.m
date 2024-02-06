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
@property (nonatomic, strong, readwrite) NSTrackingArea *trackingArea;
@property (nonatomic, strong, readwrite) MTPowerGraphTooltip *tooltipWindow;
@property (assign) NSInteger currentPosititon;
@property (assign) BOOL insideTrackingArea;
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

- (instancetype)initWithFrame:(NSRect)frameRect powerMeasurements:(NSArray*)measurements
{
    self = [super initWithFrame:frameRect];

    if (self) {
        _measurementData = measurements;
    }
    
    return self;
}

- (void)setUpView
{
    [self setWantsLayer:YES];
    [[self layer] setDrawsAsynchronously:YES];
    
    _graphLayer = [CAShapeLayer layer];
    [_graphLayer setContentsScale:[[self layer] contentsScale]];
    [_graphLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_graphLayer setFrame:[self bounds]];
    [_graphLayer setLineWidth:.1];
    _graphColor = [NSColor systemGreenColor];
    
    _powerNapLayer = [CAShapeLayer layer];
    [_powerNapLayer setContentsScale:[[self layer] contentsScale]];
    [_powerNapLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_powerNapLayer setFrame:[self bounds]];
    [_powerNapLayer setLineWidth:.1];
    _powerNapColor = [NSColor systemYellowColor];
    
    _dayMarkerLayer = [CAShapeLayer layer];
    [_dayMarkerLayer setContentsScale:[[self layer] contentsScale]];
    [_dayMarkerLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_dayMarkerLayer setFrame:[self bounds]];
    [_dayMarkerLayer setLineWidth:1];
    _dayMarkerColor = [NSColor systemYellowColor];
    
    _averageLineLayer = [CAShapeLayer layer];
    [_averageLineLayer setContentsScale:[[self layer] contentsScale]];
    [_averageLineLayer setAutoresizingMask:(kCALayerWidthSizable | kCALayerHeightSizable)];
    [_averageLineLayer setFrame:[self bounds]];
    [_averageLineLayer setLineWidth:1];
    _averageLineColor = [NSColor systemRedColor];
    
    _positionLineColor = [NSColor systemPurpleColor];
    _positionLineLayer = [CAShapeLayer layer];
    [_positionLineLayer setContentsScale:[[self layer] contentsScale]];
    [_positionLineLayer setAutoresizingMask:kCALayerHeightSizable];
    [_positionLineLayer setFrame:NSMakeRect(-10, 0, 1, NSHeight([self bounds]))];
    [_positionLineLayer setBackgroundColor:[_positionLineColor CGColor]];
    [_positionLineLayer setSpeed:NSIntegerMax];
    
    _currentPosititon = -1;
    
    [[self layer] setSublayers:[NSArray arrayWithObjects:
                                _graphLayer,
                                _powerNapLayer,
                                _dayMarkerLayer,
                                _averageLineLayer,
                                _positionLineLayer,
                                nil
                               ]
    ];
    
    _tooltipWindow = [[MTPowerGraphTooltip alloc] init];
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

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSInteger measurementsCount = [_measurementData count];
    
    if (measurementsCount > 0) {

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
            
            CGMutablePathRef dayPath = CGPathCreateMutable();
            
            for (NSNumber *x in dayMarkers) {
                CGPathMoveToPoint(dayPath, NULL, [x floatValue], 0);
                CGPathAddLineToPoint(dayPath, NULL, [x floatValue], NSHeight([self bounds]));
            }
            
            CGPathCloseSubpath(dayPath);
            
            [_dayMarkerLayer setPath:dayPath];
            [_dayMarkerLayer setStrokeColor:[_dayMarkerColor CGColor]];
            [_dayMarkerLayer setHidden:NO];
            
            CGPathRelease(dayPath);
            
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
        
        if (_insideTrackingArea) {
            
            NSPoint cursorPoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
            [self drawPositionLineAtPoint:cursorPoint];
            
        } else {
            
            // make sure the position layer is not visible anymore
            [_positionLineLayer setFrame:NSMakeRect(-10, 0, 1, NSHeight([self bounds]))];
            [_tooltipWindow close];
        }
        
        [_positionLineLayer setBackgroundColor:[_positionLineColor CGColor]];
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
            [_positionLineLayer setPosition:NSMakePoint(x, [_positionLineLayer position].y)];
        }
        
        // update the tooltip
        MTPowerMeasurement *pM = [_measurementData objectAtIndex:_currentPosititon];
        [_tooltipWindow setMeasurement:pM];
        [_tooltipWindow setFrame:NSMakeRect(
                                            [[self window] frame].origin.x + position.x + 50,
                                            [[self window] frame].origin.y + position.y,
                                            NSWidth([_tooltipWindow frame]),
                                            NSHeight([_tooltipWindow frame])
                                            )
                          display:NO
        ];
        [_tooltipWindow orderFront:nil];
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
            [_positionLineLayer setFrame:NSMakeRect(x, 0, 1, NSHeight([self bounds]))];
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
        
    } else {
        
        [_positionLineLayer setFrame:NSMakeRect(-10, 0, 1, NSHeight([self bounds]))];
        [_tooltipWindow close];
        
        success = YES;
    }
    
    return success;
}

- (BOOL)showsPosition
{
    return ([_positionLineLayer frame].origin.x >= 0) ? YES : NO;
}

#pragma mark mouse event handlers

- (void)mouseEntered:(NSEvent *)event
{
    _insideTrackingArea = YES;
    
    // even if we only allow resizing of the height, the width changes
    // to 2 pixels on resizing. therefore we set the layer to the correct
    // size as soon as the mouse enters the tracking area.
    [_positionLineLayer setFrame:NSMakeRect(-10, 0, 1, NSHeight([self bounds]))];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint cursorPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    [self drawPositionLineAtPoint:cursorPoint];
}

- (void)mouseExited:(NSEvent *)event
{
    // make sure the position layer is not visible anymore
    [_positionLineLayer setFrame:NSMakeRect(-10, 0, 1, NSHeight([self bounds]))];
    
    _currentPosititon = -1;
    _insideTrackingArea = NO;
    
    [_tooltipWindow close];
}

- (void)mouseDown:(NSEvent *)event
{
    if (_currentPosititon >= 0 && _currentPosititon < [_measurementData count]) {
        
        MTPowerMeasurement *pM = [_measurementData objectAtIndex:_currentPosititon];
        NSDate *timeStamp = [NSDate dateWithTimeIntervalSince1970:[pM timeStamp]];
        
        if (timeStamp) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNamePowerTimeStamp
                                                                object:nil
                                                              userInfo:[NSDictionary dictionaryWithObject:timeStamp
                                                                                                   forKey:kMTNotificationKeyPowerTimeStamp
                                                                       ]
            ];
        }
    }
}

@end
