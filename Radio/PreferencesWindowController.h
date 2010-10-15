//
//  PreferencesWindowController.h
//  RadioAunty
//
//  Created by Duncan Robertson on 11/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Scrobble;

@interface PreferencesWindowController : NSWindowController {
  Scrobble *scrobbler;
  IBOutlet NSButton *authButton;
  IBOutlet NSTextField *lastFMLabel;
  IBOutlet NSButton *lastFMEnabled;
  IBOutlet NSOutlineView *outlineView;
  IBOutlet NSTabView *tabView;
  
  NSArray *radioServices;
  NSMutableDictionary *radioServicesFavs;
}

@property (nonatomic, retain) Scrobble *scrobbler;
@property (nonatomic, retain) NSButton *authButton;
@property (nonatomic, retain) NSTextField *lastFMLabel;
@property (nonatomic, retain) NSButton *lastFMEnabled;
@property (nonatomic, retain) NSArray *radioServices;
@property (nonatomic, retain) NSMutableDictionary *radioServicesFavs;

- (IBAction)authorise:(id)sender;
- (IBAction)scrobbleState:(id)sender;

@end
