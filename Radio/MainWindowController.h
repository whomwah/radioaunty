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
@class BBCNowNext;

@interface MainWindowController : NSWindowController {
	IBOutlet NSView * drMainView;
  BBCNowNext * drNowNext;
  EmpViewController * drEmpViewController;
  NSDictionary * currentStation;
  NSArray * stations;
}

@property (retain) NSDictionary * currentStation;
@property (retain) NSArray * stations;
@property (retain) BBCNowNext * drNowNext;

- (NSDictionary *)findStationForId:(int)key;
- (void)setAndLoadStation:(NSDictionary *)station;
- (void)setNowPlaying;

@end
