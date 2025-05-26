/*
     MTSystemInfo.m
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

#import "MTSystemInfo.h"
#import "IOPMLibPrivate.h"
#import <libproc.h>
#import <ServiceManagement/SMAppService.h>

@implementation MTSystemInfo

typedef struct {
  uint32_t  key;
  char      unused0[24];
  uint32_t  size;
  char      unused1[10];
  char      command;
  char      unused2[5];
  float     value;
  char      unused3[28];
} AppleSMCData;

+ (NSArray *)processList
{
    NSMutableArray *processList = [[NSMutableArray alloc] init];
    
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
    bzero(pids, sizeof(pids));
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) { continue; }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        
        if (strlen(pathBuffer) > 0) {
            NSString *processPath = [NSString stringWithUTF8String:pathBuffer];
            NSString *processName = [processPath lastPathComponent];
            [processList addObject:processName];
        }
    }
    
    return processList;
}

+ (float)rawSystemPower
{
    float returnValue = 0;
    
    io_service_t smc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    
    if (smc) {
        
        io_connect_t conn = IO_OBJECT_NULL;
        IOReturn result = IOServiceOpen(smc, mach_task_self(), 1, &conn);
        
        if (result == kIOReturnSuccess && conn != IO_OBJECT_NULL) {
            
            AppleSMCData inStruct, outStruct;
            size_t outStructSize = sizeof(AppleSMCData);

            bzero(&inStruct, sizeof(AppleSMCData));
            bzero(&outStruct, sizeof(AppleSMCData));
            
            inStruct.command = 5; // read command
            inStruct.size = 4;
            inStruct.key = ('P' << 24) + ('S' << 16) + ('T' << 8) + 'R';
            
            result = IOConnectCallStructMethod(conn, 2, &inStruct, sizeof(AppleSMCData), &outStruct, &outStructSize);
            IOServiceClose(conn);

            if (result == kIOReturnSuccess) { returnValue = outStruct.value; }
        }
    }
    
    return returnValue;
}

+ (BOOL)deviceSupportsPowerNap
{
    return (IOPMFeatureIsAvailable(CFSTR(kIOPMSleepServicesKey), NULL) ||
            IOPMFeatureIsAvailable(CFSTR(kIOPMDarkWakeBackgroundTaskKey), NULL) ||
            IOPMFeatureIsAvailable(CFSTR(kIOPMPowerNapSupportedKey), NULL)) ? YES : NO;
}

+ (void)powerNapStatusWithCompletionHandler:(void (^) (BOOL enabled, BOOL aconly))completionHandler
{
    BOOL enabled = NO;
    BOOL aconly = NO;
    
    if ([self deviceSupportsPowerNap]) {
        
        CFNumberRef resultRef = NULL;
        IOPMCopyPMSetting(CFSTR(kIOPMDarkWakeBackgroundTaskKey), CFSTR(kIOPMACPowerKey), (CFTypeRef *)&resultRef);
        
        if (resultRef != NULL) {
                
            int result = 0;
            CFNumberGetValue(resultRef, kCFNumberSInt32Type, &result);
            
            if (result == 1) {
                
                enabled = YES;
                
                CFNumberRef batt_resultRef = NULL;
                IOPMCopyPMSetting(CFSTR(kIOPMDarkWakeBackgroundTaskKey), CFSTR(kIOPMBatteryPowerKey), (CFTypeRef *)&batt_resultRef);
                
                if (batt_resultRef != NULL) {
                        
                    int batt_result = 0;
                    CFNumberGetValue(batt_resultRef, kCFNumberSInt32Type, &batt_result);
                    if (batt_result == 0) { aconly = YES; }
                    
                    CFRelease(batt_resultRef);
                }
            }
        
            CFRelease(resultRef);
        }
    }
        
    if (completionHandler) { completionHandler(enabled, aconly); }
}

+ (BOOL)enablePowerNap:(BOOL)enable acPowerOnly:(BOOL)aconly
{
    IOReturn status = kIOReturnError;
    
    if ([self deviceSupportsPowerNap]) {
        
        // get the current pm settings
        NSDictionary *currentSettings = CFBridgingRelease(IOPMCopyActivePMPreferences());
        
        if (currentSettings) {
            
            // create a mutable copy
            NSMutableDictionary *mutableSettings = [currentSettings mutableCopy];
            
            if (mutableSettings) {
                
                NSMutableDictionary *batterySettings = [mutableSettings objectForKey:@kIOPMBatteryPowerKey];
                NSMutableDictionary *acPowerSettings = [mutableSettings objectForKey:@kIOPMACPowerKey];
                
                int pn = (enable) ? 1 : 0;

                if (batterySettings) { [batterySettings setValue:[NSNumber numberWithInt:(aconly) ? 0 : pn] forKey:@kIOPMDarkWakeBackgroundTaskKey]; }
                if (acPowerSettings) { [acPowerSettings setValue:[NSNumber numberWithInt:pn] forKey:@kIOPMDarkWakeBackgroundTaskKey]; }
                status = IOPMSetPMPreferences((__bridge CFDictionaryRef)(mutableSettings));
            }            
        }
    }
        
    return (status == kIOReturnSuccess) ? YES : NO;
}

+ (BOOL)hasBattery
{
    BOOL returnValue = NO;
    
    CFTypeRef ps_info = NULL;
    CFArrayRef ps_list = NULL;
    CFDictionaryRef one_ps = NULL;
    
    ps_info = IOPSCopyPowerSourcesInfo();
    
    if (ps_info) {
        
        ps_list = IOPSCopyPowerSourcesList(ps_info);
        
        if (ps_list) {
            
            for (int i = 0; i < CFArrayGetCount(ps_list); i++) {
                
                one_ps = IOPSGetPowerSourceDescription(ps_info, CFArrayGetValueAtIndex(ps_list, i));
                
                if (one_ps) {
                    
                    CFStringRef ps_type = CFDictionaryGetValue(one_ps, CFSTR(kIOPSTypeKey));
                    
                    if (ps_type && CFStringCompare(ps_type, CFSTR(kIOPSInternalBatteryType), 0) == kCFCompareEqualTo) {
                        returnValue = YES;
                        break;
                    }

                } else {
                    break;
                }
            }
            
            CFRelease(ps_list);
        }
        
        CFRelease(ps_info);
    }
    
    return returnValue;
}

+ (NSArray*)processesPreventingSleep
{
    NSMutableArray *processes = nil;
    
    // get available assertions
    CFDictionaryRef state = NULL;
    IOReturn ret = IOPMCopyAssertionsStatus(&state);
    
    if (ret == kIOReturnSuccess && state) {
        
        NSDictionary *stateDict = CFBridgingRelease(state);
        
        int noIdleLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertionTypeNoIdleSleep] intValue];
        int userIdleLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertionTypePreventUserIdleSystemSleep] intValue];
        int bgTaskLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertionTypeBackgroundTask] intValue];
        int pushTaskLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertionTypeApplePushServiceTask] intValue];
        int preventSleepLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertionTypePreventSystemSleep] intValue];
        int proxyLevel = [[stateDict objectForKey:(NSString*)kIOPMAssertInternalPreventSleep] intValue];
        
        if (noIdleLevel != kIOPMAssertionLevelOff ||
            preventSleepLevel != kIOPMAssertionLevelOff ||
            bgTaskLevel != kIOPMAssertionLevelOff ||
            pushTaskLevel != kIOPMAssertionLevelOff ||
            userIdleLevel != kIOPMAssertionLevelOff)
        {
            
            CFDictionaryRef pids = NULL;
            ret = IOPMCopyAssertionsByProcess(&pids);
            
            if (ret == kIOReturnSuccess && pids) {
                
                NSDictionary *pidDict = CFBridgingRelease(pids);
                processes = [[NSMutableArray alloc] init];
                
                for (NSString *pidString in [pidDict allKeys]) {
                    
                    NSInteger pid = [pidString integerValue];
                    
                    if (pid > 0) {
                        
                        NSArray *assertionsArray = [pidDict objectForKey:pidString];

                        for (NSDictionary *assertionDict in assertionsArray) {
                            
                            int level = [[assertionDict objectForKey:(NSString*)kIOPMAssertionLevelKey] intValue];
                            
                            if (level == kIOPMAssertionLevelOn) {
                                
                                NSString *assertionType = [assertionDict objectForKey:(NSString*)kIOPMAssertionTypeKey];
                            
                                if ([assertionType isEqualToString:(NSString*)kIOPMAssertionTypePreventUserIdleSystemSleep] ||
                                    (preventSleepLevel && [assertionType isEqualToString:(NSString*)kIOPMAssertionTypePreventSystemSleep]) ||
                                    (bgTaskLevel && [assertionType isEqualToString:(NSString*)kIOPMAssertionTypeBackgroundTask]) ||
                                    (pushTaskLevel && [assertionType isEqualToString:(NSString*)kIOPMAssertionTypeApplePushServiceTask]) ||
                                    (proxyLevel && [assertionType isEqualToString:(NSString*)kIOPMAssertInternalPreventSleep])) {
                                    
                                    [processes addObject:assertionDict];
                                }
                            }
                        }
                        
                    }
                }
                
            }
        }
    }
    
    return processes;
}

+ (BOOL)loginItemEnabled
{
    SMAppService *loginItem = [SMAppService mainAppService];
    BOOL isEnabled = ([loginItem status] == SMAppServiceStatusEnabled) ? YES : NO;
    
    return isEnabled;
}

+ (BOOL)enableLoginItem:(BOOL)enable
{
    BOOL success = NO;
    
    SMAppService *loginItem = [SMAppService mainAppService];
    
    if (enable) {
        success = [loginItem registerAndReturnError:nil];
    } else {
        success = [loginItem unregisterAndReturnError:nil];
    }
    
    return success;
}

+ (NSDictionary*)externalPowerAdapterDetails
{
    NSDictionary *adapterDetails = nil;
    CFDictionaryRef external_ps = NULL;
    external_ps = IOPSCopyExternalPowerAdapterDetails();
    
    if (external_ps) {
        adapterDetails = CFBridgingRelease(external_ps);
    }
    
    return adapterDetails;
}

+ (NSArray*)powerSourcesInfo
{
    NSMutableArray *returnValue = [[NSMutableArray alloc] init];
    
    CFTypeRef ps_info = NULL;
    CFArrayRef ps_list = NULL;
    
    ps_info = IOPSCopyPowerSourcesInfo();
    
    if (ps_info) {
        
        ps_list = IOPSCopyPowerSourcesList(ps_info);

        if (ps_list) {
            
            for (int i = 0; i < CFArrayGetCount(ps_list); i++) {
                
                CFDictionaryRef one_ps = NULL;
                one_ps = IOPSGetPowerSourceDescription(ps_info, CFArrayGetValueAtIndex(ps_list, i));
                if (one_ps) { [returnValue addObject:(__bridge NSDictionary*)(one_ps)]; }
            }
            
            CFRelease(ps_list);
        }
        
        CFRelease(ps_info);
    }
    
    return returnValue;
}

@end
