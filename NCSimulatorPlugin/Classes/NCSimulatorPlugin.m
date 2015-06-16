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
    NSMenuItem * refreshItem;
    NSOperationQueue *queue;
    NSOperationQueue *queueVersion;
    
    NSMenuItem * versionItem;
    BOOL initialized;
    NSString *currentVersion;
    NSString * currentAppVersionString;
    NSString *masterVersion;
    NSString *masterAppVersionString;
    
}

@property (nonatomic, strong) NSBundle *bundle;

@property (nonatomic, strong) NSArray *imageExtensions;

@end

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

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(menuDidChange:)
                                                     name: NSMenuDidChangeItemNotification
                                                   object: nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) menuDidChange: (NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSMenuDidChangeItemNotification
                                                  object: nil];

    if (![self hasMenu]) {
        [self createMenu];
        [self chackUpdate];
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(menuDidChange:)
                                                 name: NSMenuDidChangeItemNotification
                                               object: nil];
}

- (void)createMenu
{
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



    NSMenuItem *separatorItem = [NSMenuItem separatorItem];
    [simulator addItem:separatorItem];


    NSDictionary *currentD = [_bundle infoDictionary];
    currentVersion = [currentD valueForKey:@"CFBundleVersion"];
    currentAppVersionString = [currentD valueForKey:@"CFBundleShortVersionString"];
    NSString *v = [NSString stringWithFormat:@"NCSimulator Version %@(%@)",currentAppVersionString,currentVersion];
    versionItem = [[NSMenuItem alloc] initWithTitle:v action:@selector(goToGitHub:) keyEquivalent:@""];
    [versionItem setTarget:self];
    [simulator addItem:versionItem];
}

- (void)userStart
{
    NSLog(@"Start NCSimulatorPlugin");
     __weak typeof(self)weakSelf = self;
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//        [weakSelf refresh:nil];
//    }];
//    
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

-(BOOL)hasMenu
{
    NSMenuItem *menu = [[NSApp mainMenu] itemWithTitle:@"Simulator"];
    return (menu != nil);
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
    [item setEnabled:NO];
    [simulator addItem:item];
    
    
    
    refreshItem = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:@selector(refresh:) keyEquivalent:@""];
    [refreshItem setTarget:self];
    [simulator addItem:refreshItem];
    
    
    NSString * simulatorIdentifier = [NCUtils simulatorIdentifier];
    NSMenuItem * separatorItem ;
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
                [item setEnabled:NO];
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
        [item setEnabled:NO];
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
    
    separatorItem = [NSMenuItem separatorItem];
    [simulator addItem:separatorItem];
    [simulator addItem:versionItem];
    
}

-(void)refresh:(id)sender
{
    
    if(queue == nil)
    {
        queue = [[NSOperationQueue  alloc]init];
        queue.maxConcurrentOperationCount = 1;
    }
    
    if(queue.operationCount > 0)
    {
        [queue cancelAllOperations];
    }
    

    [refreshItem setTitle:@"Refreshing..."];
    
    [queue addOperationWithBlock:^{
        __weak typeof(self)weakSelf = self;
        [NCUtils getUserInfo:^(NSDictionary *userInfo)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [refreshItem setTitle:@"Refresh"];
                 [weakSelf setMenuItems:userInfo];
                 [weakSelf chackUpdate];
             });
         }];
    }];
    
    [self chackUpdate];
}

- (void)chackUpdate
{
    if(queueVersion == nil)
    {
        queueVersion = [[NSOperationQueue alloc]init];
        queueVersion.maxConcurrentOperationCount = 1;
    }
    
    if(queueVersion.operationCount == 0)
    {
        if(masterVersion == nil)
        {
            [queueVersion addOperationWithBlock:^{
                NSURL *url = [NSURL URLWithString:@"https://github.com/scinfu/NCSimulatorPlugin/raw/master/NCSimulatorPlugin/NCSimulatorPlugin-Info.plist"];
                NSDictionary *masterD = [[NSDictionary alloc]initWithContentsOfURL:url];
                
                masterVersion = [masterD valueForKey:@"CFBundleVersion"];
                masterAppVersionString = [masterD valueForKey:@"CFBundleShortVersionString"];
                if(masterVersion)
                {
                    NCLog(@"Master Version: ", masterVersion);
                    if([currentVersion caseInsensitiveCompare:masterVersion] == NSOrderedAscending)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *v = [NSString stringWithFormat:@"An update is available Version %@(%@)",masterAppVersionString,masterVersion];
                            [versionItem setTitle:v];
                        });
                        
                    }
                }
                
            }];
        }
    }
}


-(void)goToDocuments:(NSMenuItem*)sender {
    @try {
        NCAppFolder * app = [applications objectAtIndex:sender.tag];
        [app openDocumentsDirectory];
    }
    @catch (NSException *exception) {
        NCLog(@"NSException",exception.description);
    }
    @finally {
        
    }
    
}


-(void)goToApplication:(NSMenuItem*)sender {
    
    @try {
        NCAppFolder * app = [applications objectAtIndex:sender.tag];
        [app openApplicationDirectory];
    }
    @catch (NSException *exception) {
        NCLog(@"NSException",exception.description);
    }
    @finally {
        
    }
}


-(void)goToGitHub:(NSMenuItem*)sender {
    
    NSURL *URL = [NSURL URLWithString:@"https://github.com/scinfu/NCSimulatorPlugin"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
    
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
