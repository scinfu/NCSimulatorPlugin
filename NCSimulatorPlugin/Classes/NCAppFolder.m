//
//  NCAppFolder.m
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//

#import "NCAppFolder.h"
#import "NCUtils.h"



@implementation NCAppFolder


- (instancetype)initWithSimulatonIndetifier:(NSString *)identifier application:(NSString*)applicationIdentifier
{
    self = [super init];
    if(self)
    {
        _simulatorIdentifier = identifier;
        _applicationIdentifier = applicationIdentifier;
    }
    if([self bundleIdentifier] && [self bundleIdentifier].length > 0)
    {
        
        return self;
    }
    return nil;
}


+ (BOOL)ios7Vesion:(NSString*)simulatorIdentifier
{
    NSString * path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/device.plist",simulatorIdentifier];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString * runtime = [dictionary objectForKey:@"runtime"];
    NSString *ext = runtime.pathExtension;
    
    NSComparisonResult result = [@"iOS-8-0" caseInsensitiveCompare:ext];
    
    
    
    if(result  ==  NSOrderedDescending)
        return YES;
    
    if(result  ==  NSOrderedSame || result ==  NSOrderedAscending)
    {
        return NO ;
    }
    return NO;
}


- (NSString*)bundleIdentifier
{
    if([[self class] ios7Vesion:self.simulatorIdentifier])
    {
        NSString * path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Applications/%@",self.simulatorIdentifier,self.applicationIdentifier];
        NSString * exec = nil ;
        NSArray *contentUUID = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:nil];
        if(contentUUID.count == 0) return nil;
        
        NSArray *files = [contentUUID filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.app'"]];
        if(files.count == 0) return nil;
        exec = files[0];
        if(exec == nil) return nil ;

        NSString *plistPath = [[path stringByAppendingPathComponent:exec]stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        if(info == nil) return nil;

        NSString *bundleIdentifier = [info objectForKey:@"CFBundleIdentifier"];
        return bundleIdentifier;
    }
    else
    {
        return [NCAppFolder bundleIdentifier:self.simulatorIdentifier application:self.applicationIdentifier];
    }
}

- (NSString*)documentsPath
{
    if([[self class] ios7Vesion:self.simulatorIdentifier])
    {
        return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Applications/%@",self.simulatorIdentifier,self.applicationIdentifier];
    }
    else
    {
        NSString * docContainer = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application",self.simulatorIdentifier];
        NSArray *array = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:docContainer error:nil];
        for(NSString * applicationIdentifier in array)
        {
            NSString * path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@/.com.apple.mobile_container_manager.metadata.plist",self.simulatorIdentifier,applicationIdentifier];
            
            NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path]];
            if(dictionary)
            {
                NSString * b1 = [dictionary objectForKey:@"MCMMetadataIdentifier"];
                NSString * b2 = self.bundleIdentifier;
                if([b1 isEqualToString:b2])
                {
                    return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application/%@",self.simulatorIdentifier,applicationIdentifier];
                }
            }
            
        }
    }
    
    return nil;
}


- (NSString*)applicationPath
{
    if([[self class] ios7Vesion:self.simulatorIdentifier])
    {
        return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Applications/%@",self.simulatorIdentifier,self.applicationIdentifier];
    }
    else
    {
        return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@",self.simulatorIdentifier,self.applicationIdentifier];
    }
}






- (void)openDocumentsDirectory
{
    NSURL *URL = [NSURL fileURLWithPath:[self documentsPath] isDirectory:YES];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (void)openApplicationDirectory
{
    NSURL *URL = [NSURL fileURLWithPath:[self applicationPath] isDirectory:YES];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}








+ (NSArray*)applicationsforSimulator:(NSString*)deviceIdentifier
{
    NSMutableArray *apps = [NSMutableArray array];
    if([[self class]ios7Vesion:deviceIdentifier])
    {
        NSString * path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Applications",deviceIdentifier];
        NSArray *array = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:nil];
        for(NSString * uuid in array)
        {
            NCAppFolder *app = [[NCAppFolder alloc]initWithSimulatonIndetifier:deviceIdentifier application:uuid];
            if(app)
                [apps addObject:app];
        }
    }
    else
    {
        NSArray * applications = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:[NCAppFolder applicationsPath:deviceIdentifier] error:nil];
        for(NSString * applicationIdentifier in applications)
        {
            NCAppFolder *app = [[NCAppFolder alloc]initWithSimulatonIndetifier:deviceIdentifier application:applicationIdentifier];
            if(app)
                [apps addObject:app];
        }
    }
    return apps;
}




+ (NSString*)bundleIdentifier:(NSString*)simulatorIdentifier application:(NSString*)applicationIdentifier
{
    NSString *path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@/.com.apple.mobile_container_manager.metadata.plist",
                      simulatorIdentifier,applicationIdentifier];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path]];
    if(dictionary)
    {
        return [dictionary objectForKey:@"MCMMetadataIdentifier"];
    }
    return nil;
}

+ (NSString*)applicationsPath:(NSString*)simulatorIdentifier
{
    return  [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application",simulatorIdentifier];
}















@end
