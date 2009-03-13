//
//  PreferencesWindowController.m
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "PreferencesWindowController.h"

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
	NSLog(@"Preferences Nib file loaded");
}

- (void)windowWillClose:(NSNotification *)notification
{
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
