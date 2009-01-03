//
//  MainWindowController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

extern NSString * const DSRDefaultStation;
extern NSString * const DSRStations;

@class EmpViewController;
@class BBCSchedule;

@interface MainWindowController : NSWindowController {
  NSDockTile        *dockTile;
	IBOutlet NSView   *drMainView;
  NSDictionary      *currentStation;
  NSArray           *stations;
  BBCSchedule       *currentSchedule;
  EmpViewController *drEmpViewController;
}

@property (retain) NSDictionary *currentStation;
@property (retain) BBCSchedule *currentSchedule;
@property (retain) NSArray *stations;
@property (retain) NSDockTile *dockTile;

- (void)setAndLoadStation:(NSDictionary *)station;
- (void)changeStation:(id)sender;
- (void)fetchAOD:(id)sender;
- (void)buildStationsMenu;
- (void)buildScheduleMenu;
- (void)clearMenu:(NSMenu *)menu;
- (void)registerCurrentScheduleAsObserverForKey:(NSString *)key;
- (void)unregisterCurrentScheduleForChangeNotificationForKey:(NSString *)key;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
