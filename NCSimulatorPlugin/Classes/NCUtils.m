//
//  NCUtils.m
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//

#import "NCUtils.h"

#import "IDEKit.h"


@implementation NCUtils

+ (IDEWorkspaceWindowController *)keyWindowController
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    for (IDEWorkspaceWindowController *controller in workspaceWindowControllers) {
        if (controller.window.isKeyWindow) {
            return controller;
        }
    }
    return nil;
}

+ (id)workspaceForKeyWindow
{
    return [[self keyWindowController] valueForKey:@"_workspace"];
}

+ (NSString *)workspaceDirectoryPath {
    id workspace = [self workspaceForKeyWindow];
    NSString *workspacePath = [[workspace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return [workspacePath stringByDeletingLastPathComponent];
}


+ (NSString*)simulatorIdentifier
{
    IDEWorkspace *workspace = [NCUtils workspaceForKeyWindow];
    IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
    IDERunDestination * activeRunDestination = runContextManager.activeRunDestination;
    DVTDevice *targetDevice = activeRunDestination.targetDevice;

    NSString *identifier = nil;
    NSString *pathIdentifier = [[targetDevice.deviceLocation standardizedURL]relativeString];
    NSArray *listItems = [pathIdentifier componentsSeparatedByString:@":"];
    if(listItems.count == 2 && [targetDevice.deviceType.identifier caseInsensitiveCompare:@"Xcode.DeviceType.iPhoneSimulator"] == NSOrderedSame )
    {
        identifier = listItems[1];
    }
    return identifier;
}


+ (NSString *)targetDeviceName
{
    IDEWorkspace *workspace = [NCUtils workspaceForKeyWindow];
    IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
    IDERunDestination * activeRunDestination = runContextManager.activeRunDestination;
    DVTDevice *targetDevice = activeRunDestination.targetDevice;
    NSString * s = targetDevice.name;
    if(s) return s;
    return @"";
}

//+ (void)doB:(NSString*)path
//{
//    
//    IDEWorkspace *workspace = [NCUtils workspaceForKeyWindow];
//    IDEWorkspaceArena * workspaceArena = [workspace workspaceArena];
//    IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
//    IDEScheme *activeScheme = [runContextManager valueForKey:@"activeRunContext"];
//    IDERunDestination * activeRunDestination = runContextManager.activeRunDestination;
//    
//    NSString * buildConfiguration = activeScheme.launchSchemeAction.buildConfiguration;
//    
//    
//    
//    
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert setAlertStyle:NSInformationalAlertStyle];
//    [alert setMessageText:@"help"];
//    [alert setInformativeText:[NSString stringWithFormat:@"%@",activeScheme.launchSchemeAction.]];
//    [alert runModal];
//    
//}


+ (void)doHelp
{
    //@"/Users/scinfu/Desktop/test"
    
    if([[self class]workspaceDirectoryPath])
    {
        [[self class]runShellCommand:@"/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" withArgs:@[@"-showBuildSettings"] directory:[[self class]workspaceDirectoryPath] completion:^(NSTask *t, NSString *standardOutput, NSString *standardErr) {
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{

                NSArray * testArray = [standardOutput componentsSeparatedByString:@"\n"];
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                for (NSString *s in testArray)
                {
                    NSArray *arr = [s componentsSeparatedByString:@" = "];
                    if(arr.count == 2)
                    {
                        NSString *key = [arr[0] stringByReplacingOccurrencesOfString:@" " withString:@""];
                        NSString *value = arr[1];
                        [dict setObject:value forKey:key];
                    }
                }
                
                NSString * BUILD_DIR = [dict objectForKey:@"BUILD_DIR"];
                NSString * INFOPLIST_PATH = [dict objectForKey:@"INFOPLIST_PATH"];

                IDEWorkspace *workspace = [NCUtils workspaceForKeyWindow];
                IDEWorkspaceArena * workspaceArena = [workspace workspaceArena];
                IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
                IDEScheme *activeScheme = [runContextManager valueForKey:@"activeRunContext"];
                IDERunDestination * activeRunDestination = runContextManager.activeRunDestination;
                
                NSString * buildConfiguration = activeScheme.launchSchemeAction.buildConfiguration;
                
                
                NSString *path = [NSString stringWithFormat:@"%@/%@-iphonesimulator/%@",BUILD_DIR,buildConfiguration,INFOPLIST_PATH];
                
                NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
                NSString *bundle = [d objectForKey:@"CFBundleIdentifier"];
                
                
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSInformationalAlertStyle];
                [alert setMessageText:@"help"];
                [alert setInformativeText:[NSString stringWithFormat:@"%@",bundle]];
                [alert runModal];
                
                
            }];

        
        }];
    }
    
    
}

+ (void)runShellCommand:(NSString *)command withArgs:(NSArray *)args directory:(NSString *)directory completion:(void(^)(NSTask *t, NSString *standardOutput, NSString *standardErr))completion {
    __block NSMutableData *taskOutput = [NSMutableData new];
    __block NSMutableData *taskError  = [NSMutableData new];
    
    NSTask *task = [NSTask new];
    
    //  NSLog(@"command directory: %@", directory);
    task.currentDirectoryPath = directory;
    task.launchPath = command;
    task.arguments  = args;
    
    task.standardOutput = [NSPipe pipe];
    task.standardError  = [NSPipe pipe];
    
    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        [taskOutput appendData:[file availableData]];
    }];
    
    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        [taskError appendData:[file availableData]];
    }];
    
    [task setTerminationHandler:^(NSTask *t) {
        [t.standardOutput fileHandleForReading].readabilityHandler = nil;
        [t.standardError fileHandleForReading].readabilityHandler  = nil;
        NSString *output = [[NSString alloc] initWithData:taskOutput encoding:NSUTF8StringEncoding];
        NSString *error = [[NSString alloc] initWithData:taskError encoding:NSUTF8StringEncoding];
        NSLog(@"Shell command output: %@", output);
        NSLog(@"Shell command error: %@", error);
        if (completion) completion(t, output, error);
    }];
    
    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to launch: %@", exception);
    }
}





































//- (NSString *)appName
//{
//    IDEWorkspace *workspace = [NCUtils workspaceForKeyWindow];
//    IDEWorkspaceArena * workspaceArena = [workspace workspaceArena];
//    IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
//    IDEScheme *activeScheme = [runContextManager valueForKey:@"activeRunContext"];
//    IDERunDestination * activeRunDestination = runContextManager.activeRunDestination;
//    return nil;
//}






//#pragma mark - Notification
//- (void)registerNotifications
//{
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//
//    [notificationCenter addObserver:self
//                           selector:@selector(applicationDidFinishLaunching:)
//                               name:NSApplicationDidFinishLaunchingNotification
//                             object:NSApp];
//
//    [notificationCenter addObserver:self
//                           selector:@selector(windowDidUpdate:)
//                               name:NSWindowDidUpdateNotification
//                             object:nil];
//}
//
//- (void)unregisterNotifications
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
//- (void)applicationDidFinishLaunching:(NSNotification *)notification
//{
//    // Application did finish launching is only send once. We do not need it anymore.
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//    [notificationCenter removeObserver:self
//                                  name:NSApplicationDidFinishLaunchingNotification
//                                object:NSApp];
//
//    [self setupMenu];
//}
//
//- (void)windowDidUpdate:(NSNotification *)notification
//{
//    [[FTGEnvironmentManager sharedManager] handleWindowDidUpdate:notification];
//}


@end
