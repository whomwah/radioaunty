//
//  AppController.m
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "AppController.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"

@implementation AppController

+ (void)initialize
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  NSString *errorDesc = nil;
  NSPropertyListFormat format;
  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Stations" ofType:@"plist"];
  NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
  NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                         propertyListFromData:plistXML
                                         mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                         format:&format 
                                         errorDescription:&errorDesc];
  if (!temp) {
    NSLog(errorDesc);
    [errorDesc release];
  }
  
  [defaultValues setObject:[temp objectForKey:@"Stations"] forKey:DSRStations];
  [defaultValues setObject:[temp objectForKey:@"DefaultStation"] forKey:DSRDefaultStation];
  [defaults registerDefaults:defaultValues];
}

- (void)awakeFromNib
{
  [GrowlApplicationBridge setGrowlDelegate:self];
  drMainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[[drMainWindowController window] makeMainWindow];
	[[drMainWindowController window] makeKeyAndOrderFront:self];
}

- (void)dealloc
{
	[drMainWindowController release];
	[super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
  return YES;
}

- (IBAction)refreshStation:(id)sender
{
  [drMainWindowController setAndLoadStation:[drMainWindowController currentStation]];
}

- (void)displayPreferenceWindow:(id)sender
{
	if (!preferencesWindowController) {
    preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
	[preferencesWindowController showWindow:self];
}

@end
