//
//  ScheduleMenuItem.h
//  Radio
//
//  Created by Duncan Robertson on 15/10/2010.
//  Copyright 2010 Duncan Robertson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ScheduleMenuItem : NSMenuItem {
  NSDate   *startDate;
  NSString *titleString;
  NSString *availability;
  NSString *short_synopsis;
  NSString *currentState;
}

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSString *availability;
@property (nonatomic, copy) NSString *short_synopsis;
@property (nonatomic, copy) NSString *currentState;

- (void)createLabel;

@end
