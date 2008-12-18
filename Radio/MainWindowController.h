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
@class NowNext;

@interface MainWindowController : NSWindowController {
	IBOutlet NSView * drMainView;
  EmpViewController * drEmpViewController;
  NSString * wTitle;
  NSDictionary * currentStation;
  NSArray * stations;
  NowNext * drNowNext;
}

@property (retain) NSString * wTitle;
@property (retain) NSDictionary * currentStation;
@property (retain) NSArray * stations;

- (NSDictionary *)findStationForId:(int)key;
- (void)setAndLoadStation:(NSDictionary *)station;

@end
