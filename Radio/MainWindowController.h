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
  NSString *windowTitle;
	IBOutlet NSView *mainView;
  IBOutlet NSToolbar *toolBar;  

  NSArray *stations;
  NSDictionary *currentStation;
  BBCBroadcast *currentBroadcast;
  NSTimer *scheduleTimer;
  NSMutableArray *schedules;
  
  EmpViewController *empViewController;
  DockView *dockIconView;
  
  NSString *anonJID;
  XMPPCapabilities *xmppCapabilities;
  XMPPPubSub *pubsub;
  NSMutableArray *subscriptions;
  LiveTextView *liveTextView;
}

@property (nonatomic, retain) NSTimer *scheduleTimer;
@property (nonatomic, copy) NSString *windowTitle;
@property (nonatomic, retain) LiveTextView *liveTextView;
@property (nonatomic, retain) NSMutableArray *schedules;
@property (nonatomic, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, retain) XMPPPubSub *pubsub;
@property (nonatomic, copy) NSString *anonJID;
@property (nonatomic, retain) NSDictionary *currentStation;

- (void)growl;
- (void)changeDockNetworkIconTo:(NSString *)service;
- (void)stopScheduleTimer;
- (void)startScheduleTimer;
- (BBCSchedule*)currentSchedule;
- (void)refreshStation:(id)sender;
- (void)fetchRADIO:(NSDictionary *)station;
- (void)fetchAOD:(id)sender;
- (void)changeStation:(id)sender;
- (void)redrawEmp;
- (void)buildStationsMenu;
- (void)buildSchedule;
- (void)prepareSchedules:(id)sender;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                        change:(NSDictionary *)change context:(void *)context;

@end
