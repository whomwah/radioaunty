//
//  MainWindowController.h
//  Radio
//
//  Created by Duncan Robertson on 15/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const DSRDefaultStation;
extern NSString * const DSRStations;

@class EmpViewController;
@class BBCSchedule;

@interface MainWindowController : NSWindowController {
	IBOutlet NSView * drMainView;
  BBCSchedule * bbcSchedule;
  EmpViewController * drEmpViewController;
  NSDictionary * currentStation;
  NSArray * stations;
}

@property (retain) NSDictionary * currentStation;
@property (retain) NSArray * stations;
@property (retain) BBCSchedule * bbcSchedule;

- (NSDictionary *)findStationForId:(int)key;
- (void)setAndLoadStation:(NSDictionary *)station;
- (void)setNowPlaying;

@end
