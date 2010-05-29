//
//  BBCService.m
//  Radio
//
//  Created by Duncan Robertson on 27/05/2010.
//  Copyright 2010 Whomwah.com. All rights reserved.
//

#import "BBCService.h"


@implementation BBCService

@synthesize key;
@synthesize title;
@synthesize type;
@synthesize outlet;

#pragma mark -
#pragma mark Designated initialiser
#pragma mark -

- (id)initWithDictionary:(NSDictionary *)service
{
  if (![super init]) return nil;
  
  if (!service) {
    @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                   reason:@"You must pass in service data" 
                                 userInfo:nil];
  }
  
  self.key = [service objectForKey:@"key"];
  self.title = [service objectForKey:@"title"];
  self.type = [service objectForKey:@"type"];
  self.outlet = [service objectForKey:@"outlet"];
  
  return self;
}


#pragma mark -
#pragma mark memory management
#pragma mark -

- (void)dealloc
{
  [key release];
  [title release];
  [type release];
  [outlet release];
	
  [super dealloc];
}


#pragma mark -
#pragma mark Pretty description
#pragma mark -

- (NSString*)description
{
  return [NSString stringWithFormat:@"{\n\tkey:\t%@\n\ttitle:\t%@\n\ttype:\t%@\n\toutlet:\t%@}",
          self.key, self.title, self.type, self.outlet];
}


#pragma mark -
#pragma mark Helpers
#pragma mark -

- (NSString *)display_title
{
  if (self.outlet) {
    return [self.outlet objectForKey:@"title"];
  } else {
    return self.title;
  }
}


@end
