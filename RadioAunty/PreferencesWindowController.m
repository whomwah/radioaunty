//
//  PreferencesWindowController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "PreferencesWindowController.h"

NSString * const DSRCheckForUpdates = @"CheckForUpdates";
NSString * const DSRDefaultStation = @"DefaultStation";

@implementation PreferencesWindowController

- (id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) {
		return nil;
	}
	
	return self;
}

- (void)windowDidLoad
{
	NSLog(@"Nib file loaded");
  [checkbox setState:[self checkForUpdates]];
}

- (BOOL)checkForUpdates
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  return [defaults integerForKey:DSRCheckForUpdates];
}

- (int)defaultStation
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  return [defaults integerForKey:DSRDefaultStation];
}

- (IBAction)changeCheckForDefaults:(id)sender
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSLog(@"Changing default update state to: %d", [checkbox state]);
  [defaults setBool:[checkbox state] forKey:DSRCheckForUpdates];
}

- (IBAction)changeDefaultStation:(id)sender
{
  // needs implimenting
}

@end
