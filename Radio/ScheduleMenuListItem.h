//
//  ScheduleMenuListItem.h
//  Radio
//
//  Created by Duncan Robertson on 18/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ScheduleMenuListItem : NSMenuItem {
  NSString *title;
}

@property (nonatomic, copy) NSString *title;

- (void)createLabel;

@end
