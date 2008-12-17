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
	NSLog(@"Nib file loaded");
}

@end
