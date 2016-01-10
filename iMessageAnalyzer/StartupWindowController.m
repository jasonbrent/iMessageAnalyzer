//
//  StartupWindowController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/10/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "StartupWindowController.h"

@interface StartupWindowController ()

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) StartupViewController *startupViewController;

@property (strong, nonatomic) NSString *messagesPath;
@property (strong, nonatomic) NSString *iPhonePath;

@end

@implementation StartupWindowController

- (instancetype) initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.startupViewController = [[StartupViewController alloc] initWithNibName:@"StartupViewController" bundle:[NSBundle mainBundle]];
        
        self.messagesPath = [NSString stringWithFormat:@"/Users/%@/Library/Messages", NSUserName()];
        self.iPhonePath = [NSString stringWithFormat:@"/Users/%@/Library/Application Support/MobileSync/Backup", NSUserName()];
    }
    
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:@"iMessage Analyzer"];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    
    [self.startupViewController setDelegate:self];
    [self.window setContentViewController:self.startupViewController];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

- (void) didWishToExit
{
    [NSApp terminate:self];
}

- (void) didWishToContinue
{
    NSString *description = [NSString stringWithFormat:@"Choose the source from which to analyze your messages:\n\nThe default Mac Messages.app: %@\n\nThe most recent iPhone backup: %@\n", self.messagesPath, self.iPhonePath];
    
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:@"Choose Messages database source"];
    [prompt setInformativeText:description];
    [prompt addButtonWithTitle:@"Messages.app"];
    [prompt addButtonWithTitle:@"iPhone backup"];
    
    [prompt beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        switch (response) {
            case NSAlertFirstButtonReturn:
                [self messagesDataSource];
                break;
            case NSAlertSecondButtonReturn:
                [self iPhoneDataSource];
                break;
            default:
                break;
        }
    }];
}

- (void) messagesDataSource
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *pathForFile = [NSString stringWithFormat:@"%@/chat.db", self.messagesPath];
    
    if ([fileManager fileExistsAtPath:pathForFile]){
        
        NSString *newFileLocation = [NSString stringWithFormat:@"%@/chat_on_%f.db", self.messagesPath, [[NSDate date] timeIntervalSinceReferenceDate]];
        
        NSError *error;
        [fileManager copyItemAtPath:pathForFile toPath:newFileLocation error:&error];
        
        if(error) {
            [self showErrorPrompt:@"Error making a backup of chat.db" informationText:[NSString stringWithFormat:@"We were not able to make a backup of your Messages.db\n%@", [error description]]];
        }
        else {
            //Good to go
        }
        
    }
    else {
        [self showErrorPrompt:@"Error finding chat.db" informationText:[NSString stringWithFormat:@"Error finding Mac's Messages.app chat database at %@. \n\nMaybe Messages.app is not synced with an iCloud account", pathForFile]];
    }
}

- (void) showErrorPrompt:(NSString*)messageText informationText:(NSString*)informationText
{
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:messageText];
    [prompt setInformativeText:informationText];
    [prompt addButtonWithTitle:@"Return to main screen"];
    [prompt beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void) iPhoneDataSource
{
    NSString *fileName = @"3d0d7e5fb2ce288813306e4d4636395e047a3d28";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
    [directoryPanel setCanChooseDirectories:YES];
    [directoryPanel setCanChooseFiles:NO];
    [directoryPanel setCanHide:NO];
    [directoryPanel setCanCreateDirectories:NO];
    [directoryPanel setTitle:@"Choose the iPhone backup"];
    [directoryPanel setMessage:@"Open the directory of the iPhone backup to analyze"];
    [directoryPanel setDirectoryURL:[NSURL fileURLWithPath:self.iPhonePath]];
    
    if([directoryPanel runModal] == NSModalResponseOK) {
        NSArray *files = [directoryPanel URLs];
        
        if(files.count == 0) {
            [self showErrorPrompt:@"No backups found" informationText:@"No backups found in this directory"];
            return;
        }
        
        NSString *filePath = [((NSURL*) files[0]) path];
        if([filePath isEqualToString:self.iPhonePath]) {
            [self showErrorPrompt:@"No backup was chosen" informationText:@"No backup was chosen"];
            return;
        }
        
        NSString *iPhoneBackup = [NSString stringWithFormat:@"%@/%@", filePath, fileName];
        if([fileManager fileExistsAtPath:iPhoneBackup]) {
            NSString *newFileLocation = [NSString stringWithFormat:@"%@/chat_on_%f.db", self.iPhonePath, [[NSDate date] timeIntervalSinceReferenceDate]];
            
            NSError *error;
            [fileManager copyItemAtPath:iPhoneBackup toPath:newFileLocation error:&error];
            if(error) {
                [self showErrorPrompt:@"Error making a backup of iPhone chat" informationText:[NSString stringWithFormat:@"We were not able to make a backup of your Messages.db\n%@", [error description]]];
            }
            else {
                //Good to go
            }
        }
        else {
            [self showErrorPrompt:@"iPhone backup not found" informationText:@"Either the iPhone's text message backups were not found in this directory or they were encrypted. When syncing or backing up with iTunes, disable encryption"];
            return;
        }
        
        
    }
}

- (void) mainWindow
{
    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
}

@end
