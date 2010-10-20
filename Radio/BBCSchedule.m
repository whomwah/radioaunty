//
//  BBCSchedule.m
//  Radio
//
//  Created by Duncan Robertson on 27/05/2010.
//  Copyright 2010 Whomwah.com. All rights reserved.
//

#import "BBCSchedule.h"
#import "BBCService.h"
#import "BBCBroadcast.h"
#import "JSON.h"
#import "GDataHTTPFetcher.h"

#define API_URL @"http://www.bbc.co.uk/%@programmes/schedules%@%@.json";

@implementation BBCSchedule

@synthesize broadcasts;
@synthesize service;
@synthesize date;
@synthesize serviceKey;
@synthesize outletKey;

- (id)init
{
  [self dealloc];
  @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                 reason:@"Initialize BBCSchedule with initUsingService:outlet:" 
                               userInfo:nil];
  return nil;
}


- (void)dealloc
{
  [broadcasts release];
  [service release];
  [date release];
  [serviceKey release];
  [outletKey release];
  
	[super dealloc];
}


- (id)initUsingNetwork:(NSString *)network andOutlet:(NSString *)outlet
{
  if (![super init]) return nil;
  
  self.outletKey  = outlet; 
  self.serviceKey = network;
  self.date = [NSDate date];
  
  return self;
}


- (NSURL *)constructUrl
{  
  NSString *outletStr = outletKey ? [NSString stringWithFormat:@"/%@", outletKey] : @"";
  NSString *serviceStr = serviceKey ? [NSString stringWithFormat:@"%@/", serviceKey] : @"";  
  NSString *dateStr = date ? [date descriptionWithCalendarFormat:@"/%Y/%m/%d" timeZone:nil locale:nil] : @"";  
  NSString *api_url = API_URL;
  NSString *url_str = [NSString stringWithFormat:api_url, serviceStr, outletStr, dateStr];
  
  return [NSURL URLWithString:url_str];
}

- (BBCSchedule *)fetchScheduleForDate:(NSDate *)scheduleDate
{
  self.date = scheduleDate;
  [self fetch:[self constructUrl]];
  return self;
}


- (BBCSchedule *)fetch
{
  [self fetch:[self constructUrl]];
  return self;
}


- (BBCSchedule *)refreshDateAndFetch
{
  self.date = [NSDate date];
  [self fetch:[self constructUrl]];
  return self;
}

- (void)fetch:(NSURL *)url
{  
  DLog(@"schedule: %@", [url absoluteURL]);
  NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];
  GDataHTTPFetcher* myFetcher = [GDataHTTPFetcher httpFetcherWithRequest:theRequest];
  
  // try again if the connection fails
  [myFetcher setIsRetryEnabled:YES];
  [myFetcher setMaxRetryInterval:60.0]; // in seconds

  // make the request
  [myFetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(myFetcher:finishedWithData:)
                    didFailSelector:@selector(myFetcher:failedWithError:)];
}


- (void)myFetcher:(GDataHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData
{  
  // Create SBJSON object to parse JSON
  SBJSON *parser = [[SBJSON alloc] init];
	
  // pass the data into a string
  NSString *json_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  
  // parse the JSON string into an object - assuming json_string is a NSString of JSON data
  NSDictionary *data = [parser objectWithString:json_string error:nil];
  
  // fetch out the schedule
  NSDictionary *schedule = [data objectForKey:@"schedule"];
 
  // first create the service
  BBCService *ser = [[BBCService alloc] initWithDictionary:[schedule objectForKey:@"service"]];
  self.service = ser;
  [ser release];
    
  // create a tmp array to store the broadcasts
  NSArray *tmp_broadcasts = [[schedule objectForKey:@"day"] objectForKey:@"broadcasts"];
  NSMutableArray *bcs = [NSMutableArray arrayWithCapacity:[tmp_broadcasts count]];
  
  // loop through and create broadcasts
  for (NSDictionary *b in tmp_broadcasts) {
    BBCBroadcast *bc = [[BBCBroadcast alloc] initWithDictionary:b];
    
    [bcs addObject:bc];
    [bc release];
  }
  
  // do it like this for key value observing
  self.broadcasts = bcs;
  
  [parser release];
  [json_string release];
}


- (void)myFetcher:(GDataHTTPFetcher *)fetcher failedWithError:(NSError *)error
{
  DLog(@"Connection failed with Error - %@", [error localizedDescription]);
}


#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (NSString *)broadcastDisplayTitleForIndex:(int)index
{
  BBCBroadcast *bc = [self.broadcasts objectAtIndex:index];
  
  return [NSString stringWithFormat:@"%@ - %@", 
          service.title, [bc.display_titles objectForKey:@"title"]];
}


- (NSString *)currentBroadcastDisplayTitle
{
  if (self.current_broadcast) {
    int index = [broadcasts indexOfObject:self.current_broadcast];
    return [self broadcastDisplayTitleForIndex:index];
  } else {
    return service.title; 
  }
}



- (BBCBroadcast *)current_broadcast
{
  NSDate *now = [NSDate date];
  
  for (BBCBroadcast *broadcast in broadcasts) {
    if (([now compare:broadcast.start] == NSOrderedDescending) && 
        ([now compare:broadcast.end] == NSOrderedAscending)) {
      return broadcast;
    }
  }
  
  return nil;
}

- (BBCBroadcast *)next_broadcast
{
  int index = [broadcasts indexOfObject:self.current_broadcast];
  
  if (index != NSNotFound && index+1 <= [broadcasts count]) {
    index++;
  }
  
  return [broadcasts objectAtIndex:index];
}

- (BBCBroadcast *)previous_broadcast
{
  int index = [broadcasts indexOfObject:self.current_broadcast];
  
  if (index != NSNotFound && index-1 >= 0) {
    index++;
  }
  
  return [broadcasts objectAtIndex:index];
}





@end
