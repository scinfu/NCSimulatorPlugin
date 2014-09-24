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

+(NSString*)stringBetweenString:(NSString*)start andString:(NSString *)end withstring:(NSString*)str
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

+ (NSArray*)stringsBetweenString:(NSString*)start andString:(NSString*)end inString:(NSString*)inString
{

    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%@%@",start,end]];
    NSArray *splitString = [inString componentsSeparatedByCharactersInSet:delimiters];
    return splitString;
    
}


+ (void)getUserInfo:(GetUserInfo)block
{
    if([[self class]workspaceDirectoryPath])
    {
        [[self class]runShellCommandCMD:@"/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" withArgs:@[@"-showBuildSettings"] directoryPath:[[self class]workspaceDirectoryPath] completion:^(NSTask *t, NSString *standardOutput, NSString *standardErr) {
            
            NSOperationQueue *queue = [NSOperationQueue new];
            [queue addOperationWithBlock:^{
                
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
                IDERunContextManager * runContextManager = [workspace valueForKey:@"runContextManager"];
                IDEScheme *activeScheme = [runContextManager valueForKey:@"activeRunContext"];
                NSString * buildConfiguration = activeScheme.launchSchemeAction.buildConfiguration;
                buildConfiguration = buildConfiguration ? buildConfiguration : @"Debug";
                NSString *path = [[[BUILD_DIR stringByAppendingPathComponent:buildConfiguration]stringByAppendingString:@"-iphonesimulator"]stringByAppendingPathComponent:INFOPLIST_PATH];
                NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
                if(d == nil)
                {
                    d = [NSDictionary dictionaryWithContentsOfFile:[[[self class]workspaceDirectoryPath] stringByAppendingPathComponent:[dict objectForKey:@"INFOPLIST_FILE"]]];
                    
                    if(d)
                    {
                        for(NSString * key in d.allKeys)
                        {
                            NSString *value = [d objectForKey:key];
                            if([value isKindOfClass:[NSString class]])
                            {
                                NCLog(key , [NSString stringWithFormat:@"value:%@",value]);
                                
                                NSArray *tags = [[self class]stringsBetweenString:@"${" andString:@"}" inString:value];
                                for(NSString * aTag in tags)
                                {
                                    NSString *effectiveName = [dict objectForKey:aTag];
                                    effectiveName = effectiveName ? effectiveName : @"";
                                    NSString * tag = [NSString stringWithFormat:@"${%@}",aTag];
                                    value = [value stringByReplacingOccurrencesOfString:tag withString:effectiveName];
                                }
                                
                                [d setValue:value forKey:key];
                            }
                        }
                    }
                }
                [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                    block(d);
                }];
            }];
            
        }];
    }
    
    
}

+ (void)runShellCommandCMD:(NSString *)command withArgs:(NSArray *)args directoryPath:(NSString *)path completion:(void(^)(NSTask *t, NSString *standardOutput, NSString *standardErr))completion {
    __block NSMutableData *taskOutput = [NSMutableData new];
    __block NSMutableData *taskError  = [NSMutableData new];
    
    NSTask *taskRunner = [NSTask new];
    
    taskRunner.currentDirectoryPath = path;
    taskRunner.arguments  = args;
    taskRunner.launchPath = command;
    
    taskRunner.standardOutput = [NSPipe pipe];
    taskRunner.standardError  = [NSPipe pipe];
    
    [[taskRunner.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        [taskOutput appendData:[file availableData]];
    }];
    
    [[taskRunner.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        [taskError appendData:[file availableData]];
    }];
    
    [taskRunner setTerminationHandler:^(NSTask *t) {
        [t.standardOutput fileHandleForReading].readabilityHandler = nil;
        [t.standardError fileHandleForReading].readabilityHandler  = nil;
        NSString *output = [[NSString alloc] initWithData:taskOutput encoding:NSUTF8StringEncoding];
        NSString *error = [[NSString alloc] initWithData:taskError encoding:NSUTF8StringEncoding];
        if (completion) completion(t, output, error);
    }];
    
    @try {
        [taskRunner launch];
    }
    @catch (NSException *exception) {
         if (completion) completion(nil, nil, @"Error");
    }
}

void NCLog(NSString *tag , NSString *log)
{
//    NSString *path = @"/Users/scinfu/Desktop/log.txt";
//    NSString *myLog = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//    myLog = myLog ? myLog : @"";
//    myLog = [myLog stringByAppendingFormat:@"\n\n\n%@ : %@\n\n\n",tag,log];
//    [myLog writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

//+ (void)doExport:(NSString*)string name:(NSString*)name
//{
//    [string writeToFile:name atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    
//    
//    
////    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
////    // Enable the selection of files in the dialog.
////    [openDlg setCanChooseFiles:NO];
////    // Multiple files not allowed
////    [openDlg setAllowsMultipleSelection:NO];
////    // Can't select a directory
////    [openDlg setCanChooseDirectories:YES];
////    // Display the dialog. If the OK button was pressed,
////    [openDlg setCanCreateDirectories:YES];
////    // process the files.
////    if ( [openDlg runModal] == NSOKButton )
////    {
////        NSString * pathDest =[[openDlg.URL path]stringByAppendingFormat:@"/%@",name];
////        [string writeToFile:pathDest atomically:YES];
////    }
//
//
//
////    NSAlert *alert = [[NSAlert alloc] init];
////    [alert setAlertStyle:NSInformationalAlertStyle];
////    [alert setMessageText:@"ddd"];
////    [alert setInformativeText:string];
////    [alert runModal];
//}



@end
