/*
     MTPowerGraphView.m
     Copyright 2023 SAP SE
     
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
#import <QuartzCore/CAShapeLayer.h>

@interface MTPowerGraphView ()
@property (nonatomic, strong, readwrite) CAShapeLayer *graphLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *dayMarkerLayer;
@property (nonatomic, strong, readwrite) CAShapeLayer *averageLineLayer;
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
    [_graphLayer setFrame:[self bounds]];
    [_graphLayer setLineWidth:.1];
    _graphColor = [NSColor systemGreenColor];
    
    _dayMarkerLayer = [CAShapeLayer layer];
    [_dayMarkerLayer setContentsScale:[[self layer] contentsScale]];
    [_dayMarkerLayer setFrame:[self bounds]];
    [_dayMarkerLayer setLineWidth:1];
    _dayMarkerColor = [NSColor systemBlueColor];
    
    _averageLineLayer = [CAShapeLayer layer];
    [_averageLineLayer setContentsScale:[[self layer] contentsScale]];
    [_averageLineLayer setFrame:[self bounds]];
    [_averageLineLayer setLineWidth:1];
    _averageLineColor = [NSColor systemRedColor];
    
    [[self layer] setSublayers:[NSArray arrayWithObjects:_graphLayer, _dayMarkerLayer, _averageLineLayer, nil]];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    CGMutablePathRef linePath = CGPathCreateMutable();
    
    MTPowerMeasurement *maxValue = [_measurementData maximumPower];
    MTPowerMeasurement *avgValue = [_measurementData averagePower];
    
    float maxX = [_measurementData count] - 1;
    float maxY = [maxValue doubleValue] * 1.1;

    CGPathMoveToPoint(linePath, NULL, 0, 0);
    
    __block NSDate *lastDate = nil;
    __block NSMutableArray *dayMarkers = [[NSMutableArray alloc] init];

    [_measurementData enumerateObjectsUsingBlock:^(id  obj, NSUInteger idx, BOOL *stop) {
                    
        float xRatio = 1.0 - ((maxX - idx) / maxX);
        float yRatio = 1.0 - ((maxY - [obj doubleValue]) / maxY);

        float x = xRatio * NSWidth([self bounds]);
        float y = yRatio * NSHeight([self bounds]);
        
        CGPathAddLineToPoint(linePath, NULL, x, y);

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
    
    CGPathAddLineToPoint(linePath, NULL, NSWidth([self bounds]), 0);
    CGPathCloseSubpath(linePath);
    
    [_graphLayer setPath:linePath];
    [_graphLayer setFillColor:[_graphColor CGColor]];
    [_graphLayer setStrokeColor:[_graphColor CGColor]];
    
    CGPathRelease(linePath);
    
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
    }

    // average line
    if (_showAverage) {
        
        float yRatio = 1.0 - ((maxY - [avgValue doubleValue]) / maxY);
        float y = yRatio * NSHeight([self bounds]);
        
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
}

@end
