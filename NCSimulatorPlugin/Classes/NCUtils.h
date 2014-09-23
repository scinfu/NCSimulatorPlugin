//
//  NCUtils.h
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceWindowController;

@interface NCUtils : NSObject

+ (NSString*)simulatorIdentifier;
+ (NSString *)targetDeviceName;

void alert(NSString *title , NSString * string);



+ (void)doHelp;

@end
