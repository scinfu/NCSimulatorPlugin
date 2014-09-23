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


- (NSString*)bundleIdentifier
{
    return [NCAppFolder bundleIdentifier:self.simulatorIdentifier application:self.applicationIdentifier];
}

- (NSString*)documentsPath
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
    return nil;
}


- (NSString*)applicationPath
{
    return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Bundle/Application/%@",self.simulatorIdentifier,self.applicationIdentifier];
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
    NSArray * applications = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:[NCAppFolder applicationsPath:deviceIdentifier] error:nil];
    NSMutableArray *apps = [NSMutableArray array];
    for(NSString * applicationIdentifier in applications)
    {
        NCAppFolder *app = [[NCAppFolder alloc]initWithSimulatonIndetifier:deviceIdentifier application:applicationIdentifier];
        if(app)
           [apps addObject:app];
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
