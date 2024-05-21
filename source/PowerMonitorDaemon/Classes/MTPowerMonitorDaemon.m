/*
     MTPowerMonitorDaemon.m
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

#import "MTPowerMonitorDaemon.h"
#import "MTPowerMeasurement.h"
#import "MTPowerMeasurementWriter.h"
#import "MTPowerMeasurementReader.h"
#import "MTPowerMeasurementArray.h"
#import "MTSystemInfo.h"
#import "MTPowerJournal.h"
#import "Constants.h"
#import <os/log.h>

@interface MTPowerMonitorDaemon ()
@property (atomic, strong, readwrite) NSXPCListener *listener;
@property (nonatomic, strong, readwrite) NSTimer *measurementTimer;
@property (nonatomic, strong, readwrite) MTPowerMeasurementWriter *pMWriter;
@property (nonatomic, strong, readwrite) MTSleepWatcher *watcher;
@property (nonatomic, strong, readwrite) MTPowerJournal *powerJournal;
@property (assign) NSTimeInterval currentDayStart;
@property (assign) BOOL isDarkWake;
@property (assign) BOOL resetMeasurements;
@end

@implementation MTPowerMonitorDaemon

- (instancetype)init
{
    self = [super init];
    
    if (self) {
                
        _listener = [[NSXPCListener alloc] initWithMachServiceName:kMTDaemonMachServiceName];
        [_listener setDelegate:self];
        [_listener resume];
        
        _powerJournal = [[MTPowerJournal alloc] initWithFileAtPath:kMTJournalFilePath];
    }
    
    return self;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    BOOL acceptConnection = NO;
    
    if (listener == _listener && newConnection != nil) {
        
        NSXPCInterface *exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PowerMonitorDaemonProtocol)];
        [newConnection setExportedInterface:exportedInterface];
        [newConnection setExportedObject:self];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        [newConnection setInvalidationHandler:^{
                      
            [newConnection setInvalidationHandler:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                os_log(OS_LOG_DEFAULT, "SAPCorp: %{public}@ invalidated", newConnection);
            });
        }];
#pragma clang diagnostic pop
        
        // Resuming the connection allows the system to deliver more incoming messages.
        [newConnection resume];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            os_log(OS_LOG_DEFAULT, "SAPCorp: %{public}@ established", newConnection);
        });
        
        acceptConnection = YES;
    }

    return acceptConnection;
}

- (BOOL)startMonitoring
{
    BOOL success = NO;
    
    _pMWriter = [[MTPowerMeasurementWriter alloc] initWithFileAtPath:kMTMeasurementFilePath
                                                 maximumMeasurements:kMTMeasurementTimePeriod * 60 * (60 / kMTMeasurementInterval)];
    if (_pMWriter) {
        
#ifdef DEBUG
        printf("Power monitoring started…\n");
#endif
        success = YES;
        
        // if journal is enabled, check our measurements and make sure, measurements
        // older than today, are in the journal
        
        _watcher = [[MTSleepWatcher alloc] initWithDelegate:self];
        [_watcher startWatching];
        
        _isDarkWake = ([[_watcher currentEvent] type] == MTPowerEventTypeDarkWake) ? YES : NO;
        
        // get the latest measurement to adjust file location
        __block NSInteger bufferIndex = [_pMWriter currentBufferIndex];
        
        // start measuring…
        _measurementTimer = [NSTimer scheduledTimerWithTimeInterval:kMTMeasurementInterval
                                                            repeats:YES
                                                              block:^(NSTimer *timer) {
            if (self->_resetMeasurements) {
                
                bufferIndex = 0;
                NSMutableData *zeroData = [[NSMutableData alloc] initWithLength:[[self->_pMWriter measurementData] length]];
                [[self->_pMWriter measurementData] replaceMappedBytesInRange:NSMakeRange(bufferIndex, [[self->_pMWriter measurementData] length])
                                                                   withBytes:[zeroData bytes]];
                self->_resetMeasurements = NO;
            }
            
            NSDate *newDate = [NSDate date];
            NSDate *newDayStartDate = [[NSCalendar currentCalendar] startOfDayForDate:newDate];
            NSTimeInterval newDayStart = [newDayStartDate timeIntervalSince1970];
            
            if (![self powerNapsIgnored] || !self->_isDarkWake) {
            
                // get current system power
                float powerValue = [MTSystemInfo rawSystemPower];
            
                if (powerValue > 0) {
                                        
                    // write data
                    MeasurementStruct data;
                    data.timestamp = CFSwapInt64HostToBig([newDate timeIntervalSince1970]);
                    data.value = CFSwapInt32HostToBig(*(int*)(&powerValue));
                    data.darkwake = self->_isDarkWake;
                    [[self->_pMWriter measurementData] replaceMappedBytesInRange:NSMakeRange(bufferIndex, sizeof(data)) withBytes:&data];
#ifdef DEBUG
                    printf("System power (%lu): %f W\n", bufferIndex / sizeof(data), powerValue);
#endif
                    if (bufferIndex + sizeof(data) >= [[self->_pMWriter measurementData] length]) {
                        bufferIndex = 0;
                    } else {
                        bufferIndex += sizeof(data);
                    }
                }
                
                if (!self->_currentDayStart || self->_currentDayStart < newDayStart) {
                    
                    self->_currentDayStart = newDayStart;
                    
                    // check if our journal is up to date
                    [self journalEnabledWithReply:^(BOOL enabled, BOOL forced) {
                        
                        __block BOOL journalUpdated = NO;
                        
                        if (enabled) {
                            
                            MTPowerMeasurementReader *pmReader = [[MTPowerMeasurementReader alloc] initWithData:[self->_pMWriter measurementData]];
                            NSDictionary *groupedMeasurements = [[pmReader allMeasurements] measurementsGroupedByDay];
                            
                            for (NSString *aKey in [groupedMeasurements allKeys]) {
                                
                                NSTimeInterval interval = [aKey doubleValue];
                                
                                // we ignore today's measurements and only go ahead, if the
                                // journal does not contain an entry for the day
                                if  (interval != self->_currentDayStart && ![self->_powerJournal entryWithTimeStamp:interval]) {
                                    
                                    NSArray *measurementGroup = [groupedMeasurements objectForKey:aKey];
                                    NSArray *awakeMeasurements = [measurementGroup awakeMeasurements];
                                    NSArray *powerNapMeasurements = [measurementGroup powerNapMeasurements];
                                    
                                    MTPowerJournalEntry *journalEntry = [[MTPowerJournalEntry alloc] initWithTimeIntervalSince1970:interval];
                                    [journalEntry setDurationAwake:[awakeMeasurements totalTime]];
                                    [journalEntry setConsumptionTotal:[[measurementGroup averagePower] doubleValue]];
                                    [journalEntry setDurationPowerNap:[powerNapMeasurements totalTime]];
                                    [journalEntry setConsumptionPowerNap:[[powerNapMeasurements averagePower] doubleValue]];
                                    
                                    [[self->_powerJournal allEntries] addObject:journalEntry];
                                    
                                    journalUpdated = YES;
                                }
                            }
                        }
                        
                        // delete outdated entries
                        [self journalAutoDeletionIntervalWithReply:^(NSInteger interval, BOOL forced) {
                            
                            NSDate *lastValidDate = nil;
                            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];

                            if (interval == 1) {

                                [dateComponents setMonth:-1];
                                lastValidDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents
                                                                                              toDate:newDayStartDate
                                                                                             options:0
                                ];
                                
                            } else if (interval == 2) {
                                
                                [dateComponents setMonth:-6];
                                lastValidDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents 
                                                                                              toDate:newDayStartDate
                                                                                             options:0
                                ];
                                
                            } else if (interval == 3) {
                                
                                [dateComponents setYear:-1];
                                lastValidDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents 
                                                                                              toDate:newDayStartDate
                                                                                             options:0
                                ];
                            }
                                
                            if (lastValidDate) {
                                
                                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp < %lf", [lastValidDate timeIntervalSince1970]];
                                NSArray *filteredArray = [[self->_powerJournal allEntries] filteredArrayUsingPredicate:predicate];
                                
                                if ([filteredArray count] > 0) {
                                    
                                    [[self->_powerJournal allEntries] removeObjectsInArray:filteredArray];
                                    journalUpdated = YES;
                                }
                            }
                            
                            if (journalUpdated) { [self->_powerJournal synchronize]; }
                        }];
                    }];
                }
            }
        }];

    } else {

        fprintf(stderr, "ERROR! Failed to access buffer file: %s\n", [kMTMeasurementFilePath UTF8String]);
    }
    
    return success;
}

- (BOOL)stopMonitoring
{
    [_measurementTimer invalidate];
    _measurementTimer = nil;
    _pMWriter = nil;
    
    BOOL success = [_watcher stopWatching];
    
#ifdef DEBUG
    printf("Power monitoring stopped\n");
#endif
    
    return success;
}

- (BOOL)powerNapsIgnored
{
    BOOL ignored = NO;
    
    CFPropertyListRef property = CFPreferencesCopyValue(kMTPrefsIgnorePowerNapsKey, kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
    
    if (property) {
        ignored = CFBooleanGetValue(property);
        CFRelease(property);
    }
    
    return ignored;
}

#pragma mark exported methods

- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *endpoint))reply
{
    reply([_listener endpoint]);
}

- (void)logEntriesSinceDate:(NSDate*)date completionHandler:(void (^)(NSArray<OSLogEntry*> *entries))completionHandler
{
    OSLogStore *logStore = [OSLogStore storeWithScope:OSLogStoreSystem error:nil];
    
    OSLogPosition *position = (date) ? [logStore positionWithDate:date] : nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subsystem == %@ AND category IN %@",
                              @"com.apple.powerd",
                              [NSArray arrayWithObjects:
                                    @"assertions",
                                    @"coreSmartPowerNap",
                                    @"lowPowerMode",
                                    @"pmSettings",
                                    @"sleepWake",
                                    @"systemLoad",
                                    @"wakeRequests",
                                    nil
                              ]
    ];
    
    OSLogEnumerator *logEnumerator = [logStore entriesEnumeratorWithOptions:0
                                                                   position:position
                                                                  predicate:predicate
                                                                      error:nil];
    completionHandler([logEnumerator allObjects]);
}

- (void)deleteMeasurementsWithCompletionHandler:(void (^)(void))completionHandler
{
    _resetMeasurements = YES;
    [_measurementTimer fire];
    
    completionHandler();
}

- (void)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly completionHandler:(void (^)(BOOL success))completionHandler
{
    BOOL success = [MTSystemInfo enablePowerNap:enable acPowerOnly:aconly];
    completionHandler(success);
}

- (void)setJournalEnabled:(BOOL)enabled completionHandler:(void (^)(BOOL success))completionHandler
{
    // set the value
    CFPreferencesSetValue(kMTPrefsEnableJournalKey, (__bridge CFPropertyListRef)([NSNumber numberWithBool:enabled]), kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
        
    // read the value and compare it
    // with the value we set
    [self journalEnabledWithReply:^(BOOL isEnabled, BOOL isForced) {
        
        completionHandler((enabled == isEnabled) ? YES : NO);
    }];
}

- (void)journalEnabledWithReply:(void (^)(BOOL enabled, BOOL forced))reply
{
    BOOL isEnabled = NO;
    BOOL isForced = CFPreferencesAppValueIsForced(kMTPrefsEnableJournalKey, kMTDaemonPreferenceDomain);
    
    CFPropertyListRef property = CFPreferencesCopyValue(kMTPrefsEnableJournalKey, kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
    
    if (property) {
        isEnabled = CFBooleanGetValue(property);
        CFRelease(property);
    }
    
    reply(isEnabled, isForced);
}

- (void)setJournalAutoDeletionInterval:(NSInteger)interval completionHandler:(void (^)(BOOL success))completionHandler
{
    // set the value
    CFPreferencesSetValue(kMTPrefsJournalAutoDeleteKey, (__bridge CFPropertyListRef)([NSNumber numberWithInteger:interval]), kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
        
    // read the value and compare it
    // with the value we set
    [self journalAutoDeletionIntervalWithReply:^(NSInteger storedInterval, BOOL isForced) {
        
        completionHandler((interval == storedInterval) ? YES : NO);
    }];
}

- (void)journalAutoDeletionIntervalWithReply:(void (^)(NSInteger interval, BOOL forced))reply
{
    NSInteger interval = 0;
    BOOL isForced = CFPreferencesAppValueIsForced(kMTPrefsJournalAutoDeleteKey, kMTDaemonPreferenceDomain);
    
    CFPropertyListRef property = CFPreferencesCopyValue(kMTPrefsJournalAutoDeleteKey, kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
    
    if (property) {
        
        if (CFGetTypeID(property) == CFNumberGetTypeID()) {
            CFNumberGetValue((CFNumberRef)property, kCFNumberNSIntegerType, &interval);
        }
        
        CFRelease(property);
    }
    
    reply(interval, isForced);
}

- (void)setIgnorePowerNaps:(BOOL)ignore completionHandler:(void (^)(BOOL success))completionHandler
{
    // set the value
    CFPreferencesSetValue(kMTPrefsIgnorePowerNapsKey, (__bridge CFPropertyListRef)([NSNumber numberWithBool:ignore]), kMTDaemonPreferenceDomain, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
        
    // read the value and compare it
    // with the value we set
    [self powerNapsIgnoredWithReply:^(BOOL isIgnored, BOOL isForced) {
        
        completionHandler((ignore == isIgnored) ? YES : NO);
    }];
}

- (void)powerNapsIgnoredWithReply:(void (^)(BOOL ignored, BOOL forced))reply
{
    BOOL isForced = CFPreferencesAppValueIsForced(kMTPrefsIgnorePowerNapsKey, kMTDaemonPreferenceDomain);
    reply([self powerNapsIgnored], isForced);
}

#pragma mark MTSleepWatcherDelegate methods

- (void)powerEvent:(MTPowerEvent *)event willChangeType:(MTPowerEventType)type
{
    _isDarkWake = (type == MTPowerEventTypeDarkWake) ? YES : NO;
}

- (void)powerEventDidEnd:(MTPowerEvent *)event
{
    return;
}

- (void)powerEventDidStart:(MTPowerEvent *)event
{
    _isDarkWake = ([event type] == MTPowerEventTypeDarkWake) ? YES : NO;
}

@end
