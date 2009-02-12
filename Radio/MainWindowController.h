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
extern NSString * const DSRQuality;

@class EmpViewController;
@class Schedule;

@interface MainWindowController : NSWindowController {
  NSDockTile        *dockTile;
  NSView            *dockView;
	IBOutlet NSView   *drMainView;
  NSDictionary      *currentStation;
  NSArray           *stations;
  Schedule          *currentSchedule;
  EmpViewController *drEmpViewController;
}

@property (nonatomic, retain) NSView *dockView;
@property (nonatomic, retain) NSDictionary *currentStation;
@property (nonatomic, retain) EmpViewController *drEmpViewController;
@property (nonatomic, retain) Schedule *currentSchedule;
@property (nonatomic, retain) NSArray *stations;

- (void)setAndLoadStation:(NSDictionary *)station;
- (void)changeStation:(id)sender;
- (void)fetchAOD:(id)sender;
- (void)redrawEmp;
- (void)resizeEmpTo:(NSSize)size;
- (void)buildStationsMenu;
- (void)buildScheduleMenu;
- (void)buildDockTileForKey:(NSString *)key;
- (void)clearMenu:(NSMenu *)menu;
- (void)registerCurrentScheduleAsObserverForKey:(NSString *)key;
- (void)unregisterCurrentScheduleForChangeNotificationForKey:(NSString *)key;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
