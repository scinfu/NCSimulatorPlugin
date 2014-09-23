//
//  NCAppFolder.h
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCAppFolder : NSObject

- (instancetype)initWithSimulatonIndetifier:(NSString *)identifier application:(NSString*)applicationIdentifier;

@property(nonatomic,readonly) NSString * simulatorIdentifier;
@property(nonatomic,readonly) NSString * applicationIdentifier;

- (NSString*)bundleIdentifier;
- (NSString*)documentsPath;
- (NSString*)applicationPath;


- (void)openDocumentsDirectory;
- (void)openApplicationDirectory;

+ (NSArray*)applicationsforSimulator:(NSString*)deviceIdentifier;



@end
