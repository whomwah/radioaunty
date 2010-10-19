//
//  ListenMenuItem.h
//  Radio
//
//  Created by Duncan Robertson on 14/10/2010.
//  Copyright 2010 Duncan Robertson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ListenMenuItem : NSMenuItem {
  NSString *stationTitle;
  NSString *outletTitle;
}

@property (nonatomic, copy) NSString *stationTitle;
@property (nonatomic, copy) NSString *outletTitle;

- (void)setIconForId:(NSString*)key;
- (void)setStation;

@end
