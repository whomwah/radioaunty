//
//  AppController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;
@class PreferencesWindowController;

@interface AppController : NSObject {
  IBOutlet NSMenu * listenMenu;
	MainWindowController * drMainWindowController;
  PreferencesWindowController * preferencesWindowController;
}

- (void)buildMenu;
- (IBAction)changeStation:(id)sender;
- (IBAction)refreshStation:(id)sender;
- (IBAction)displayPreferenceWindow:(id)sender;

@end
