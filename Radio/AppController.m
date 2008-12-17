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

@synthesize repeatingTimer;

+ (void)initialize
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
  NSString * errorDesc = nil;
  NSPropertyListFormat format;
  NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"Stations" ofType:@"plist"];
  NSData * plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
  NSDictionary * temp = (NSDictionary *)[NSPropertyListSerialization
                                         propertyListFromData:plistXML
                                         mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                         format:&format errorDescription:&errorDesc];
  if (!temp) {
    NSLog(errorDesc);
    [errorDesc release];
  }
  
  [defaultValues setObject:[temp objectForKey:@"DefaultStation"] forKey:DSRDefaultStation];
  [defaultValues setObject:[temp objectForKey:@"Stations"] forKey:DSRStations];
  
  [defaults registerDefaults:defaultValues];
  NSLog(@"registered defaults: %@", defaultValues);
}

- (void)awakeFromNib
{
  drMainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[[drMainWindowController window] makeMainWindow];
	[[drMainWindowController window] makeKeyAndOrderFront:self];
  
  [self buildMenu];
  [GrowlApplicationBridge setGrowlDelegate:self];
  [drMainWindowController setAndLoadStation:[[NSUserDefaults standardUserDefaults] dictionaryForKey:DSRDefaultStation]]; 
  
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                    target:self 
                                                  selector:@selector(pollNowPlaying:)
                                                  userInfo:nil
                                                   repeats:YES];
  self.repeatingTimer = timer;
}

- (void)pollNowPlaying:(id)sender
{
  NSLog(@"Checking for new nowplaying data");
}

- (void)dealloc
{
	[drMainWindowController release];
	[super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
  return YES;
}

- (IBAction)changeStation:(id)sender
{
  NSDictionary * station = [drMainWindowController findStationForId:[sender tag]];
  NSString * title = [station valueForKey:@"label"];
  
  [drMainWindowController setWTitle:title];
  [[[sender menu] itemWithTitle:[[drMainWindowController currentStation] valueForKey:@"label"]] setState:NSOffState];
  
  [sender setState:NSOnState];
  [drMainWindowController setAndLoadStation:station];
  NSLog(@"changing to: %@", title);
}

- (IBAction)refreshStation:(id)sender
{
  [drMainWindowController setAndLoadStation:[drMainWindowController currentStation]];
}

#pragma mark Build Listen menu

-(void)buildMenu
{
  NSEnumerator * enumerator = [[drMainWindowController stations] objectEnumerator];
  
  for (NSDictionary * station in enumerator) {  
    NSMenuItem * newItem;    
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[station valueForKey:@"label"] 
                                                                   action:@selector(changeStation:) 
                                                            keyEquivalent:@""];
    if ([[[NSUserDefaults standardUserDefaults] dictionaryForKey:DSRDefaultStation] isEqual:station]) {
      [newItem setState:NSOnState]; 
    }
    [newItem setEnabled:YES];
    [newItem setTag:[[station valueForKey:@"id"] intValue]];
    [newItem setTarget:self];
    [listenMenu addItem:newItem];
    [newItem release];
  }
  
  NSLog(@"Listen menu completed: %@", listenMenu);
}

#pragma mark PreferencesWindowController

- (void)displayPreferenceWindow:(id)sender
{
	if (!preferencesWindowController) {
    preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
	[preferencesWindowController showWindow:self];
}


@end
