//
//  ScheduleMenuListItem.m
//  Radio
//
//  Created by Duncan Robertson on 18/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScheduleMenuListItem.h"


@implementation ScheduleMenuListItem

@synthesize title;

- (id)init
{
	if (self = [super init]) {
    self.title = @"";
	}
  
	return self;
}

- (void)dealloc
{
  [title release];
   
  [super dealloc];
}

- (void)createLabel
{
  NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:title];
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:attrStr];
  
  int slen  = [str length];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont systemFontOfSize:13]
              range:NSMakeRange(0, slen)];
  
  [self setAttributedTitle:str];
  [attrStr release];
  [str release];
}

@end
