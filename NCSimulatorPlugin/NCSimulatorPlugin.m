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
    NSArray * applications;
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
        
        NSMenu *mainMenu = [NSApp mainMenu];
        // create a new menu and add a new item
        simulator = [[NSMenu alloc] initWithTitle:@"Simulator"];
        // add the newly created menu to the main menu bar
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"Simulator Sub Menu" action:NULL keyEquivalent:@""];
        [newMenuItem setSubmenu:simulator];
        [mainMenu addItem:newMenuItem];
        [self setMenuItems];
        
        
        __weak typeof(self)weakSelf = self;        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidUpdateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [weakSelf refresh:nil];
        }];
        
    }
    return self;
}

-(void)setMenuItems {
    
    
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
        name = @"Refresh";
    else
        name = [NSString stringWithFormat:@"Refesh %@",name];
    
    
    NSMenuItem *goToDocuments = [[NSMenuItem alloc] initWithTitle:name action:@selector(refresh:) keyEquivalent:@""];
    [goToDocuments setTarget:self];
    [simulator addItem:goToDocuments];
    
    
    NSMenuItem * separatorItem = [NSMenuItem separatorItem];
    [simulator addItem:separatorItem];
    
    
    NSString * simulatorIdentifier = [NCUtils simulatorIdentifier];
    
    if(simulatorIdentifier)
    {
        applications = [NCAppFolder applicationsforSimulator:simulatorIdentifier];
        int i = 0;
        for(NCAppFolder *app in applications)
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
            
            
            
            NSMenuItem *goToApplication = [[NSMenuItem alloc] initWithTitle:@"Go To Application" action:@selector(goToApplication:) keyEquivalent:@""];
            [goToApplication setTarget:self];
            [goToApplication setTag:i];
            [submenu addItem:goToApplication];
            
            i++;
        }
    }
}

-(void)refresh:(id)sender
{
    [self setMenuItems];
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
