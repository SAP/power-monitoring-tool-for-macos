/*
     Constants.h
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

#define kMTMeasurementFilePath                  @"/Users/Shared/Power Monitor/measurements.pwrdata"
#define kMTJournalFilePath                      @"/Users/Shared/Power Monitor/journal.plist"
#define kMTMeasurementTimePeriod                24
#define kMTMeasurementInterval                  5
#define kMTGraphUpdateInterval                  60
#define kMTCurrentPowerUpdateInterval           10
#define kMTDaemonPlistName                      @"corp.sap.PowerMonitorDaemon.plist"
#define kMTErrorDomain                          @"corp.sap.PowerMonitor.ErrorDomain"
#define kMTDaemonMachServiceName                @"corp.sap.PowerMonitor.xpc"
#define kMTGitHubURL                            @"https://github.com/SAP/power-monitoring-tool-for-macos"

// NSUserDefaults
#define kMTDefaultsShowCarbonKey                @"ShowCarbon"
#define kMTDefaultsCarbonRegionsKey             @"CarbonRegions"
#define kMTDefaultsGraphShowAverageKey          @"ShowAverage"
#define kMTDefaultsGraphShowDayMarkersKey       @"ShowDayMarkers"
#define kMTDefaultsGraphMarkPowerNapsKey        @"MarkPowerNaps"
#define kMTDefaultsSettingsSelectedTabKey       @"SettingsSelectedTab"
#define kMTDefaultsGraphFillColorKey            @"GraphFillColor"
#define kMTDefaultsGraphPowerNapFillColorKey    @"GraphPowerNapFillColor"
#define kMTDefaultsGraphPositionLineColorKey    @"GraphPositionLineColor"
#define kMTDefaultsGraphAverageColorKey         @"GraphAverageLineColor"
#define kMTDefaultsGraphDayMarkerColorKey       @"GraphDayMarkerColor"
#define kMTDefaultsCarbonAPITypeKey             @"CarbonAPIType"
#define kMTDefaultsRunInBackgroundKey           @"RunInBackground"
#define kMTDefaultsTodayValuesOnlyKey           @"TodayValuesOnly"
#define kMTDefaultsUpdateCarbonKey              @"UpdateCarbon"
#define kMTDefaultsElectricityPriceKey          @"ElectricityPrice"
#define kMTDefaultsAltElectricityPriceKey       @"AltElectricityPrice"
#define kMTDefaultsShowPriceKey                 @"ShowPrice"
#define kMTDefaultsShowSleepIntervalsKey        @"ShowSleepIntervals"
#define kMTDefaultsMeasurementStartDateKey      @"MeasurementStartDate"
#define kMTDefaultsLogFollowCursorKey           @"LogFollowCursor"
#define kMTDefaultsLogFilterEnabledKey          @"LogFilterEnabled"
#define kMTDefaultsLogDetailsEnabledKey         @"LogDetailsEnabled"
#define kMTDefaultsLogDividerPositionKey        @"LogSplitViewDividerPosition"
#define kMTDefaultsJournalExportFormatKey       @"JournalExportFormat"
#define kMTDefaultsJournalExportCSVHeaderKey    @"JournalWriteCSVHeader"
#define kMTDefaultsJournalExportSummarizeKey    @"JournalExportSummarize"
#define kMTDefaultsJournalExportDurationKey     @"JournalExportDuration"
#define kMTDefaultsJournalSummaryEnabledKey     @"JournalSummaryEnabled"
#define kMTDefaultsJournalDividerPositionKey    @"JournalSplitViewDividerPosition"

// CFPreferences
#define kMTDaemonPreferenceDomain               CFSTR("corp.sap.PowerMonitorDaemon")
#define kMTPrefsEnableJournalKey                CFSTR("EnableJournal")
#define kMTPrefsJournalAutoDeleteKey            CFSTR("JournalEntriesAutoDelete")
#define kMTPrefsIgnorePowerNapsKey              CFSTR("IgnorePowerNaps")
#define kMTPrefsUseAltPriceKey                  CFSTR("UseAltPrice")
#define kMTPrefsAltPriceScheduleKey             CFSTR("AltPriceSchedule")

// NSNotification
#define kMTNotificationNameCarbonValue              @"corp.sap.PowerMonitor.CarbonFootprintValue"
#define kMTNotificationNamePowerStats               @"corp.sap.PowerMonitor.PowerStats"
#define kMTNotificationNameCurrentPowerValue        @"corp.sap.PowerMonitor.CurrentPowerValue"
#define kMTNotificationNamePowerTimeStamp           @"corp.sap.PowerMonitor.PowerTimeStamp"
#define kMTNotificationNameLogMessage               @"corp.sap.PowerMonitor.LogMessage"
#define kMTNotificationNameReloadDataFile           @"corp.sap.PowerMonitor.ReloadDataFile"
#define kMTNotificationNameShowConsole              @"corp.sap.PowerMonitor.ShowConsole"
#define kMTNotificationNameShowGraphWindow          @"corp.sap.PowerMonitor.ShowGraphWindow"
#define kMTNotificationNameGraphMouseEntered        @"corp.sap.PowerMonitor.GraphView.MouseEntered"
#define kMTNotificationNameGraphMouseExited         @"corp.sap.PowerMonitor.GraphView.MouseExited"
#define kMTNotificationNameGraphPositionUpdated     @"corp.sap.PowerMonitor.GraphView.PositionUpdated"
#define kMTNotificationNameGraphPinChanged          @"corp.sap.PowerMonitor.GraphView.PinChanged"
#define kMTNotificationNameGraphShowDetail          @"corp.sap.PowerMonitor.GraphView.ShowDetail"
#define kMTNotificationNameGraphReloadData          @"corp.sap.PowerMonitor.GraphView.ReloadData"
#define kMTNotificationNameJournalUpdateSummary     @"corp.sap.PowerMonitor.Journal.UpdateSummary"
#define kMTNotificationNameDaemonConfigDidChange    @"corp.sap.PowerMonitorDaemon.Configuration.DidChange"

// NSNotification user info keys
#define kMTNotificationKeyCarbonValue           @"CarbonValue"
#define kMTNotificationKeyAveragePowerValue     @"AveragePowerValue"
#define kMTNotificationKeyConsumptionValue      @"ConsumptionValue"
#define kMTNotificationKeyCurrentPowerValue     @"CurrentPowerValue"
#define kMTNotificationKeyPowerTimeStamp        @"PowerTimeStamp"
#define kMTNotificationKeyLogMessage            @"LogMessage"
#define kMTNotificationKeyGraphPosition         @"MeasurementAtCurrentPosition"
#define kMTNotificationKeyGraphData             @"GraphData"
#define kMTNotificationKeyPreferenceChanged     @"PreferenceKeyChanged"

// pwrdata file format
#define kMTFileHeaderSignature                  "pwrdata"
#define kMTFileHeaderVersion                    2

// keys for dicts to populate NSPopupButton (general settings -> enable Power Nap)
#define kMTPopupMenuEntryLabelKey               @"label"
#define kMTPopupMenuEntryPowerNapKey            @"powerNap"

// MTToolbarItem
#define MTToolbarGraphAverageLineItemIdentifier @"MTToolbarGraphAverageLineItem"
#define MTToolbarGraphDayMarkerItemIdentifier   @"MTToolbarGraphDayMarkerItem"
#define MTToolbarGraphPowerNapItemIdentifier    @"MTToolbarGraphPowerNapItem"
#define MTToolbarGraphInspectorItemIdentifier   @"MTToolbarGraphInspectorItem"
#define MTToolbarConsoleReloadItemIdentifier    @"MTToolbarConsoleReloadItem"
#define MTToolbarConsoleFollowLogItemIdentifier @"MTToolbarConsoleFollowLogItem"
#define MTToolbarConsoleInfoItemIdentifier      @"MTToolbarConsoleInfoItem"
#define MTToolbarConsoleFilterItemIdentifier    @"MTToolbarConsoleFilterItem"
#define MTToolbarConsoleSaveItemIdentifier      @"MTToolbarConsoleSaveItem"
#define MTToolbarConsoleSearchItemIdentifier    @"MTToolbarConsoleSearchItem"
