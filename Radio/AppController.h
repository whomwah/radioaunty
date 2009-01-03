//
//  AppController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class MainWindowController;
@class PreferencesWindowController;

@interface AppController : NSObject <GrowlApplicationBridgeDelegate> {
	MainWindowController *drMainWindowController;
  PreferencesWindowController *preferencesWindowController;
}

- (IBAction)refreshStation:(id)sender;
- (IBAction)displayPreferenceWindow:(id)sender;

@end
