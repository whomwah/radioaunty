//
//  MainWindowController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "XMPPCapabilities.h"

@class EmpViewController;
@class BBCSchedule;
@class BBCBroadcast;
@class DockView;
@class LiveTextView;
@class XMPPJID;
@class XMPPCapabilities;
@class XMPPPubSub;

@interface MainWindowController : NSWindowController {
	IBOutlet NSView *drMainView;
  IBOutlet NSToolbar *toolBar;  
  
  LiveTextView *liveTextView;
  
  NSDockTile *dockTile;
  NSDictionary *currentStation;
  NSArray *stations;
  NSString *windowTitle;
  BBCSchedule *currentSchedule;
  BBCBroadcast *currentBroadcast;
  EmpViewController *empViewController;
  NSTimer *scheduleTimer;
  DockView *dockIconView;
  
  BOOL availableForSubscription;
  NSString *anonJID;
  
  XMPPCapabilities *xmppCapabilities;
  XMPPPubSub *pubsub;
}

@property (nonatomic, retain) NSTimer *scheduleTimer;
@property (nonatomic, copy) NSString *windowTitle;
@property (nonatomic, retain) LiveTextView *liveTextView;
@property (nonatomic, retain) BBCSchedule *currentSchedule;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, retain) XMPPPubSub *pubsub;
@property (nonatomic, copy) NSString *anonJID;

- (NSString *)liveOrNotText;
- (void)growl;
- (void)changeDockNetworkIconTo:(NSString *)service;
- (void)stopScheduleTimer;
- (void)startScheduleTimer;
- (void)refreshStation:(id)sender;
- (void)fetchRADIO:(NSDictionary *)station;
- (void)fetchAOD:(id)sender;
- (void)changeStation:(id)sender;
- (void)redrawEmp;
- (void)buildStationsMenu;
- (void)buildScheduleMenu;
- (void)fetchNewSchedule:(id)sender;
- (void)clearMenu:(NSMenu *)menu;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change context:(void *)context;

@end
