/*
     MTPowerGraphView.h
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

#import <Cocoa/Cocoa.h>
#import "MTPowerMeasurementArray.h"

/*!
 @class         MTPowerGraphView
 @abstract      This class defines the view for the power graph.
*/

@interface MTPowerGraphView : NSView <CALayerDelegate>

/*!
 @property      measurementData
 @abstract      A property to store the measurements to display.
 @discussion    The value of this property is NSArray.
*/
@property (nonatomic, strong, readwrite) NSArray<MTPowerMeasurement*> *measurementData;

/*!
 @property      showAverage
 @abstract      A property to specify if the average line should be displayed or not.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL showAverage;

/*!
 @property      showDayMarkers
 @abstract      A property to specify if day markers should be displayed or not.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL showDayMarkers;

/*!
 @property      showPowerNaps
 @abstract      A property to specify if Power Naps should be displayed or not.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL showPowerNaps;

/*!
 @property      allowPinning
 @abstract      A property to specify if a value in the graph can be pinned (by clicking on it) or not.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL allowPinning;

/*!
 @property      isPinned
 @abstract      This property returns if the graph has a value pinned or not.
 @discussion    The value of this property is boolean.
*/
@property (readonly) BOOL isPinned;

/*!
 @property      pinnedPosition
 @abstract      This property returns the graph's pinned position.
 @discussion    The value of this property is NSPoint.
*/
@property (readonly) NSPoint pinnedPosition;

/*!
 @property      pinnedMeasurement
 @abstract      This property returns the measurement for the graph's pinned position.
 @discussion    The value of this property is MTPowerMeasurement.
*/
@property (nonatomic, strong, readonly) MTPowerMeasurement *pinnedMeasurement;

/*!
 @property      allowToolTip
 @abstract      A property to specify if a tooltip should be displayed next to the position line or not.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL allowToolTip;

/*!
 @property      postPositionChangedNotification
 @abstract      A property indicating whether the view posts notifications when the mouse pointer
                position in its frame rectangle changes.
 @discussion    The value of this property is boolean.
*/
@property (assign) BOOL postPositionChangedNotification;

/*!
 @property      graphColor
 @abstract      A property to specify the color of the graph.
 @discussion    The value of this property is NSColor.
*/
@property (nonatomic, strong, readwrite) NSColor *graphColor;

/*!
 @property      averageLineColor
 @abstract      A property to specify the color of the average line.
 @discussion    The value of this property is NSColor.
*/
@property (nonatomic, strong, readwrite) NSColor *averageLineColor;

/*!
 @property      dayMarkerColor
 @abstract      A property to specify the color of the day markers.
 @discussion    The value of this property is NSColor.
*/
@property (nonatomic, strong, readwrite) NSColor *dayMarkerColor;

/*!
 @property      powerNapColor
 @abstract      A property to specify the color of the Power Nap intervals.
 @discussion    The value of this property is NSColor.
*/
@property (nonatomic, strong, readwrite) NSColor *powerNapColor;

/*!
 @property      positionLineColor
 @abstract      A property to specify the color of the position line.
 @discussion    The value of this property is NSColor.
*/
@property (nonatomic, strong, readwrite) NSColor *positionLineColor;

/*!
 @method        showMeasurement:withTooltip:
 @abstract      Marks a measurement in the graph by drawing a position line. In addition to this the value
                and timestamp can also displayed in a tooltip that appears near the line.
 @param         measurement The MTPowerMeasurement object to be displayed in the graph
 @param         tooltip A boolean indicating if the measurement value and timestamp should be displayed in a tooltip.
 @discussion    Returns YES if the given measurement has been found and the position line could be displayed,
                otherwise returns NO.
*/
- (BOOL)showMeasurement:(MTPowerMeasurement*)measurement withTooltip:(BOOL)tooltip;

/*!
 @method        showsPosition
 @abstract      Indicates if the position line is shown or not.
 @discussion    Returns YES if the position line is shown, otherwise returns NO.
*/
- (BOOL)showsPosition;

/*!
 @method        setView:
 @abstract      Set the view to a given view.
*/
- (void)setView:(MTPowerGraphView*)view;

@end
