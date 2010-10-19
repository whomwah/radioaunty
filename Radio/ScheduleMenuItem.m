//
//  ScheduleMenuItem.m
//  Radio
//
//  Created by Duncan Robertson on 15/10/2010.
//  Copyright 2010 Duncan Robertson. All rights reserved.
//

#import "ScheduleMenuItem.h"


@implementation ScheduleMenuItem

@synthesize start;
@synthesize title;
@synthesize currentState;
@synthesize availability;
@synthesize short_synopsis;

- (id)init
{
	if (self = [super init]) {
    self.title = @"";
    self.currentState = @"";
	}
  
	return self;
}

- (void)dealloc
{
	[start release];
  [title release];
  [availability release];
  [short_synopsis release];
  [currentState release];
	
	[super dealloc];
}

- (NSString*)startAsHHMM
{
  if ([start isKindOfClass:[NSDate class]]) {
    return [start descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil]; 
  }
  return @"";
}

- (void)createTooltip
{
  if (!short_synopsis) return;
  
  if (!availability) {
    [self setToolTip:short_synopsis];
    return;
  }
  
  [self setToolTip:[NSString stringWithFormat:@"%@ - %@", availability, short_synopsis]]; 
}

- (void)createLabel
{
  NSString *startStr = [self startAsHHMM];
  NSString *origStr = [NSString stringWithFormat:@"%@  %@ %@", startStr, title, currentState];  
  NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
                                 [origStr stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]]];
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:attrStr];
  
  int slen  = [startStr length];
  int tlen  = [title length];
  int stlen = [currentState length];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont boldSystemFontOfSize:13.3]
              range:NSMakeRange(0, slen)];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:13.6]
              range:NSMakeRange(slen+2, tlen)];
    
  [str addAttribute:NSForegroundColorAttributeName
              value:[NSColor lightGrayColor]
              range:NSMakeRange(3+slen+tlen, stlen)];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:9]
              range:NSMakeRange(3+slen+tlen, stlen)];
  
  [self setAttributedTitle:str];
  [attrStr release];
  [str release];
  
  [self createTooltip];
}

@end
