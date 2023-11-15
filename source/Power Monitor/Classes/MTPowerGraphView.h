/*
     MTPowerGraphView.h
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

#import <Cocoa/Cocoa.h>
#import "MTPowerMeasurementArray.h"

/*!
 @class         MTPowerGraphView
 @abstract      This class defines the view for the power graph.
*/

@interface MTPowerGraphView : NSView

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

@end
