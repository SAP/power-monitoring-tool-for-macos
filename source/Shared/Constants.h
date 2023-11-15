/*
     Constants.h
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

#define kMTMeasurementFilePath                  @"/Users/Shared/Power Monitor/measurements.pwrdata"
#define kMTMeasurementTimePeriod                24
#define kMTMeasurementInterval                  5
#define kMTGraphUpdateInterval                  60
#define kMTCurrentPowerUpdateInterval           10
#define kMTDaemonPlistName                      @"corp.sap.PowerMonitorDaemon.plist"
#define kMTErrorDomain                          @"corp.sap.PowerMonitor.ErrorDomain"
#define kMTGitHubURL                            @"https://github.com/SAP/power-monitoring-tool-for-macos"

#define kMTDefaultsShowCarbonKey                @"ShowCarbon"
#define kMTDefaultsCarbonRegionsKey             @"CarbonRegions"
#define kMTDefaultsGraphShowAverageKey          @"ShowAverage"
#define kMTDefaultsGraphShowDayMarkersKey       @"ShowDayMarkers"
#define kMTDefaultsSettingsSelectedTabKey       @"SettingsSelectedTab"
#define kMTDefaultsGraphFillColorKey            @"GraphFillColor"
#define kMTDefaultsGraphAverageColorKey         @"GraphAverageLineColor"
#define kMTDefaultsGraphDayMarkerColorKey       @"GraphDayMarkerColor"
#define kMTDefaultsCarbonAPITypeKey             @"CarbonAPIType"
#define kMTDefaultsRunInBackgroundKey           @"RunInBackground"

#define kMTNotificationNameCarbonValue          @"corp.sap.PowerMonitor.CarbonFootprintValue"
#define kMTNotificationNameAveragePowerValue    @"corp.sap.PowerMonitor.AveragePowerValue"
#define kMTNotificationNameCurrentPowerValue    @"corp.sap.PowerMonitor.CurrentPowerValue"

#define kMTNotificationKeyCarbonValue          @"CarbonValue"
#define kMTNotificationKeyAveragePowerValue    @"AveragePowerValue"
#define kMTNotificationKeyCurrentPowerValue    @"CurrentPowerValue"
