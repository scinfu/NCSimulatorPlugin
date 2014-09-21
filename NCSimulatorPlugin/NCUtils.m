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
