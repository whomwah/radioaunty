//
//  PreferencesWindowController.h
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const DSRCheckForUpdates;
extern NSString * const DSRDefaultStation;

@interface PreferencesWindowController : NSWindowController {

  IBOutlet NSButton * checkbox;
  IBOutlet NSPopUpButton * stationsList;
  
}

- (BOOL)checkForUpdates;
- (int)defaultStation;
- (IBAction)changeCheckForDefaults:(id)sender;
- (IBAction)changeDefaultStation:(id)sender;

@end
