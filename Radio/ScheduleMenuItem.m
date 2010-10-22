//
//  ScheduleMenuItem.m
//  Radio
//
//  Created by Duncan Robertson on 15/10/2010.
//  Copyright 2010 Duncan Robertson. All rights reserved.
//

#import "ScheduleMenuItem.h"


@implementation ScheduleMenuItem

@synthesize startDate;
@synthesize titleString;
@synthesize currentState;
@synthesize availability;
@synthesize short_synopsis;

- (id)init
{
	if (self = [super init]) {
    self.titleString = @"";
    self.currentState = @"";
	}
  
	return self;
}

- (void)dealloc
{
	[startDate release];
  [titleString release];
  [availability release];
  [short_synopsis release];
  [currentState release];
	
	[super dealloc];
}

- (NSString*)startAsHHMM
{
  if ([startDate isKindOfClass:[NSDate class]]) {
    return [startDate descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil]; 
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
  NSString *startString = [self startAsHHMM];
  NSString *origStr = [NSString stringWithFormat:@"%@  %@ %@", startString, self.titleString, self.currentState];  
  NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
                                 [origStr stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]]];
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:attrStr];

  NSUInteger slen  = [startString length];
  NSUInteger tlen  = [self.titleString length];
  NSUInteger stlen = [self.currentState length];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont boldSystemFontOfSize:13.3]
              range:NSMakeRange(0, slen)];  
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:13.6]
              range:NSMakeRange(slen, [str length]-slen)];

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
