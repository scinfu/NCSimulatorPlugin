//
//  NCSimulatorPlugin.m
//  NCSimulatorPlugin
//
//  Created by Nabil Chatbi on 20/09/14.
//  Copyright (c) Nabil Chatbi All rights reserved.
//
#import "NCSimulatorPlugin.h"

#import "IDEFoundation.h"
#import "NCAppFolder.h"
#import "NCUtils.h"



static NCSimulatorPlugin *sharedPlugin;

@interface NCSimulatorPlugin()
{
    NSMenu *simulator ;
    NSMutableArray * applications;
    NCAppFolder *currentApp;
}

@property (nonatomic, strong) NSBundle *bundle;

@property (nonatomic, strong) NSArray *imageExtensions;

@end

static NSString *const kRSImageOptimPlugin        = @"com.pdq.rsimageoptimplugin";
static NSString *const kRSImageOptimPluginAutoKey = @"com.pdq.rsimageoptimplugin.auto";

@implementation NCSimulatorPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}


- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
        applications = [NSMutableArray array];
        
        NSMenu *mainMenu = [NSApp mainMenu];
        // create a new menu and add a new item
        simulator = [[NSMenu alloc] initWithTitle:@"Simulator"];
        // add the newly created menu to the main menu bar
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"Simulator" action:NULL keyEquivalent:@""];
        [newMenuItem setSubmenu:simulator];
        [mainMenu addItem:newMenuItem];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Initialize" action:@selector(userStart) keyEquivalent:@""];
        [item setTarget:self];
        [simulator addItem:item];
    }
    return self;
}

- (void)userStart
{
     __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeMainNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidEndSheetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"IDEBuildOperationDidStopNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ExecutionEnvironmentLastBuildCompletedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"IDEBuildOperationDidGenerateOutputFilesNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"IDECurrentLaunchSessionTargetOutputChanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf refresh:nil];
    }];
    
    
    
    
    
    
    
    
    
    
    [self refresh:nil];
}


- (void)addMenuApp:(NCAppFolder*)app index:(int)i
{
    
}

-(void)setMenuItems:(NSDictionary*)userInfo {
    
    NSString *bundle = [userInfo objectForKey:@"CFBundleIdentifier"];
    NSString *appName = [userInfo objectForKey:@"CFBundleName"];
    
    NSMenu *menu = simulator;
    
    if(menu)
    {
        NSMutableArray * itemsToRemove = [NSMutableArray array];
        for( NSMenuItem *item in [menu itemArray] )
        {
            [itemsToRemove addObject:item];
        }
        
        for( NSMenuItem * item in itemsToRemove ){
            [menu removeItem:item];
        }
    }
    
    
    NSString *name = [NCUtils targetDeviceName] ;
    
    if(name == nil || name.length == 0)
        name = @"No device found";
    else
        name = [NSString stringWithFormat:@"%@",name];
    
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
    [simulator addItem:item];
    
    
    NSMenuItem * separatorItem = [NSMenuItem separatorItem];
    [simulator addItem:separatorItem];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:@selector(refresh:) keyEquivalent:@""];
    [item setTarget:self];
    [simulator addItem:item];
    
    
    separatorItem = [NSMenuItem separatorItem];
    [simulator addItem:separatorItem];
    
    
    NSString * simulatorIdentifier = [NCUtils simulatorIdentifier];
    
    if(simulatorIdentifier)
    {
        NSArray *items = [NCAppFolder applicationsforSimulator:simulatorIdentifier];
        [applications removeAllObjects];
        [applications addObjectsFromArray:items];
        
        
        // find current bundle identifier in array apps and create a menu
        int i = 0;
        for(NCAppFolder *app in applications)
        {
            if([app.bundleIdentifier isEqualToString:bundle])
            {
                separatorItem = [NSMenuItem separatorItem];
                [simulator addItem:separatorItem];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Current App" action:NULL keyEquivalent:@""];
                [simulator addItem:item];
                
                NSMenu *submenu = [[NSMenu alloc] initWithTitle:@""];
                // add the newly created menu to the main menu bar
                NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:appName?appName:[app bundleIdentifier] action:NULL keyEquivalent:@""];
                [newMenuItem setSubmenu:submenu];
                [simulator addItem:newMenuItem];
                
                
                NSMenuItem *goToDocuments = [[NSMenuItem alloc] initWithTitle:@"Go To Documents" action:@selector(goToDocuments:) keyEquivalent:@""];
                [goToDocuments setTarget:self];
                [goToDocuments setTag:i];
                [submenu addItem:goToDocuments];
                
                
                if([NCAppFolder ios7Vesion:app.simulatorIdentifier] == NO)
                {
                    NSMenuItem *goToApplication = [[NSMenuItem alloc] initWithTitle:@"Go To Application" action:@selector(goToApplication:) keyEquivalent:@""];
                    [goToApplication setTarget:self];
                    [goToApplication setTag:i];
                    [submenu addItem:goToApplication];
                }
                
                break;
            }
        }
        
        
        // separator for Other apps
        separatorItem = [NSMenuItem separatorItem];
        [simulator addItem:separatorItem];
        
        item = [[NSMenuItem alloc] initWithTitle:@"Other Apps" action:NULL keyEquivalent:@""];
        [simulator addItem:item];
        
        
        i = 0;
        for(NCAppFolder *app in applications)
        {
            if(bundle == nil || ![app.bundleIdentifier isEqualToString:bundle])
            {
                NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"a menu"];
                // add the newly created menu to the main menu bar
                NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:[app bundleIdentifier] action:NULL keyEquivalent:@""];
                [newMenuItem setSubmenu:submenu];
                [simulator addItem:newMenuItem];
                
                
                NSMenuItem *goToDocuments = [[NSMenuItem alloc] initWithTitle:@"Go To Documents" action:@selector(goToDocuments:) keyEquivalent:@""];
                [goToDocuments setTarget:self];
                [goToDocuments setTag:i];
                [submenu addItem:goToDocuments];
                
                
                if([NCAppFolder ios7Vesion:app.simulatorIdentifier] == NO)
                {
                    NSMenuItem *goToApplication = [[NSMenuItem alloc] initWithTitle:@"Go To Application" action:@selector(goToApplication:) keyEquivalent:@""];
                    [goToApplication setTarget:self];
                    [goToApplication setTag:i];
                    [submenu addItem:goToApplication];
                }
            }
            i++;
        }
    }
    
}

-(void)refresh:(id)sender
{
    __weak typeof(self)weakSelf = self;
    [NCUtils getUserInfo:^(NSDictionary *userInfo)
     {
         [weakSelf setMenuItems:userInfo];
     }];
}


-(void)goToDocuments:(NSMenuItem*)sender {
    NCAppFolder * app = [applications objectAtIndex:sender.tag];
    [app openDocumentsDirectory];
}


-(void)goToApplication:(NSMenuItem*)sender {
    NCAppFolder * app = [applications objectAtIndex:sender.tag];
    [app openApplicationDirectory];
}








//- (IBAction)doExport:(NSString*)string name:(NSString*)name
//{
//    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
//    // Enable the selection of files in the dialog.
//    [openDlg setCanChooseFiles:NO];
//    // Multiple files not allowed
//    [openDlg setAllowsMultipleSelection:NO];
//    // Can't select a directory
//    [openDlg setCanChooseDirectories:YES];
//    // Display the dialog. If the OK button was pressed,
//    [openDlg setCanCreateDirectories:YES];
//    // process the files.
//    if ( [openDlg runModal] == NSOKButton )
//    {
//        NSString * pathDest =[[openDlg.URL path]stringByAppendingFormat:@"/%@.txt",name];
//        [string writeToFile:pathDest atomically:YES];
//    }
//    
//    
//    
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert setAlertStyle:NSInformationalAlertStyle];
//    [alert setMessageText:@"ddd"];
//    [alert setInformativeText:string];
//    [alert runModal];
//}



@end
