//
//  ListenMenuItem.m
//  Radio
//
//  Created by Duncan Robertson on 14/10/2010.
//  Copyright 2010 Duncan Robertson. All rights reserved.
//

#import "ListenMenuItem.h"


@implementation ListenMenuItem

@synthesize stationTitle;
@synthesize outletTitle;

- (id)init
{
	if (self = [super init]) {
    [self setEnabled:YES];
	}
  
	return self;
}

- (void)dealloc
{
	[stationTitle release];
  [outletTitle release];
	
	[super dealloc];
}

- (void)setIconForId:(NSString*)key
{
  NSImage *img = [NSImage imageNamed:key];
  [img setSize:NSMakeSize(50.0, 28.0)];
  [self setImage:img]; 
}

/**
 * Attempts to remove BBC from the start of the string as
 * all the stations provided have BBC at the front which
 * seems like to much of the work BBC, ya get me
 **/

-(NSString*)unBBCitizeString:(NSString*)string
{
  if ([string hasPrefix:@"BBC "]) {
    NSRange removeBBC = NSMakeRange(4, [string length]-4);
    return [string substringWithRange:removeBBC];
  } else {
    return string;
  }
}

- (void)titleWithOutlet
{ 
  NSString *ol = [NSString stringWithFormat:@"(%@)", outletTitle];
  
  int tlen = [stationTitle length];
  int olen = [ol length];
  
  NSString *com = [NSString stringWithFormat:@"%@ %@", stationTitle, ol];
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:com];

  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:14]
              range:NSMakeRange(0,tlen)];

  [str addAttribute:NSForegroundColorAttributeName
              value:[NSColor lightGrayColor]
              range:NSMakeRange([com length]-olen, olen)];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:12]
              range:NSMakeRange([com length]-olen, olen)];
  
  [self setAttributedTitle:str];
  
  [str release];
}

- (void)titleWithoutOutlet
{  
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:stationTitle];
  int len = [stationTitle length];
  
  [str addAttribute:NSFontAttributeName
              value:[NSFont userFontOfSize:14]
              range:NSMakeRange(0,len)];
  
  [self setAttributedTitle:str];
  
  [str release];
}

- (void)setStation
{
  self.stationTitle = [self unBBCitizeString:stationTitle];
  self.outletTitle  = [self unBBCitizeString:outletTitle];
  
  if (outletTitle) {
    [self titleWithOutlet];  
  } else {
    [self titleWithoutOutlet];
  }
}

@end
