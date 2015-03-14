//
//  NCUtils.h
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceWindowController;

typedef void (^GetUserInfo)(NSDictionary* userInfo);

@interface NCUtils : NSObject

+ (NSString*)simulatorIdentifier;
+ (NSString*)targetDeviceName;
+ (void)getUserInfo:(GetUserInfo)block;

void NCLog(NSString *tag , NSString *msg);

@end
