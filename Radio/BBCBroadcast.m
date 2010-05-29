//
//  BBCBroadcast.m
//  Radio
//
//  Created by Duncan Robertson on 27/05/2010.
//  Copyright 2010 Whomwah.com. All rights reserved.
//


#import "BBCBroadcast.h"
#import "ISO8601DateFormatter.h"

@implementation BBCBroadcast

@synthesize short_synopsis;
@synthesize pid;
@synthesize type;
@synthesize end;
@synthesize start;
@synthesize display_titles;
@synthesize media;


#pragma mark -
#pragma mark Designated initialiser
#pragma mark -

- (id)initWithDictionary:(NSDictionary *)broadcast
{
  if (![super init]) return nil;
  
  if (!broadcast) {
    @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                   reason:@"You must pass in broadcast data" 
                                 userInfo:nil];
  }
  
  ISO8601DateFormatter *formatDate = [[ISO8601DateFormatter alloc] init];
  
  duration    = [[broadcast objectForKey:@"duration"] intValue];
  self.end    = [formatDate dateFromString:[broadcast objectForKey:@"end"]];
  self.start  = [formatDate dateFromString:[broadcast objectForKey:@"start"]];
  is_blanked  = [[broadcast objectForKey:@"is_blanked"] intValue];
  is_repeat   = [[broadcast objectForKey:@"is_repeat"] intValue];  
  
  // create a shortcut
  NSDictionary *prog = [broadcast objectForKey:@"programme"];
  
  self.display_titles = [prog objectForKey:@"display_titles"];
  self.media =          [prog objectForKey:@"media"];
  self.pid   =          [prog objectForKey:@"pid"];
  self.short_synopsis = [prog objectForKey:@"short_synopsis"];
  self.type  =          [prog objectForKey:@"type"];  
  
  [formatDate release];
  
  return self; 
}


#pragma mark -
#pragma mark memory management
#pragma mark -

- (void)dealloc
{
  [short_synopsis release];
  [pid release];
  [type release];
  [end release];
  [start release];
  [display_titles release];
  [media release];
	
  [super dealloc];
}


#pragma mark -
#pragma mark helpers
#pragma mark -

- (NSString *)programme_url
{
  return [NSString stringWithFormat:@"http://bbc.co.uk/programmes/%@", self.pid];
}


@end
