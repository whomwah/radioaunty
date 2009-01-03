//
//  BBCSchedule.m
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "BBCSchedule.h"
#import "NSString-Utilities.h"

#define API_URL @"http://www.bbc.co.uk/%@programmes/schedules%@.xml";

@implementation BBCSchedule

@synthesize receivedData;
@synthesize displayTitle;
@synthesize displaySynopsis;
@synthesize lastUpdated;
@synthesize service;
@synthesize broadcasts;
@synthesize currentBroadcast;

-(id)init
{
  [self dealloc];
  @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                 reason:@"Initialize BBCSchedule with initUsingService:outlet:" 
                               userInfo:nil];
  return nil;
}

- (id)initUsingService:(NSString *)sv outlet:(NSString *)ol;
{
  if (![super init])
    return nil;
  
  outletKey = ol;
  serviceKey = sv;
    
  [self fetch:[self buildUrl]];
  
  return self;
}

- (NSURL *)buildUrl
{
  NSString *api = API_URL;
  NSString *serviceStr = @"", *outletStr = @"", *urlStr;

  if (outletKey)
    outletStr = [NSString stringWithFormat:@"/%@", outletKey];
  
  if (serviceKey)
    serviceStr = [NSString stringWithFormat:@"%@/", serviceKey];
  
  urlStr = [NSString stringWithFormat:api, serviceStr, outletStr];
  NSLog(@"URL: %@", urlStr);
  return [NSURL URLWithString:urlStr];
}

- (void)fetch:(NSURL *)url
{
  NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];

  NSURLConnection * theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
  if (theConnection) {
    self.receivedData = [[NSMutableData data] retain];
  } else {
    // inform the user that the download could not be made
    NSLog(@"download failed!");
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [receivedData setLength:0];
  expectedLength = [response expectedContentLength];
  [self setDisplayTitle:@"Loading Schedule..."];
  NSLog(@"Yay, we got a response");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [receivedData appendData:data];
  float percentComplete = ([receivedData length]/expectedLength)*100.0;
  
  [self setDisplayTitle:[NSString stringWithFormat:@"Loading Schedule %1.0f%%", percentComplete]];
  NSLog(@"data is being fetched: %1.0f%%", percentComplete);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [connection release];
  [receivedData release];
  
  NSLog(@"Connection failed! Error - %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"Finished! Received %d bytes of data", [receivedData length]);
  NSError *error;
  
  NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:receivedData options:0 error:&error];
  
  if (error != nil) {
    NSLog(@"An Error occured reading the schedule: %@", error);
  }
  
  xmlDocument = doc;
  [self setServiceData];
  [self setBroadcastData];
  [self setDisplayTitle:[self serviceDisplayTitle]];
  [self setLastUpdated:[NSDate date]];
  
  [doc release];
  [connection release];
  [receivedData release];
}

- (void)setServiceData
{
  NSError *error;
  NSArray *data = [xmlDocument nodesForXPath:@".//schedule/service[@type=\"radio\"]" error:&error];
  
  if (error != nil)
    NSLog(@"An Error occured: %@", error);
  
  NSXMLNode *node = [data objectAtIndex:0];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringForXPath:@"title" ofNode:node], @"serviceTitle",
                      [NSString stringForXPath:@"@key" ofNode:node], @"serviceKey",
                      [NSString stringForXPath:@"outlet/title" ofNode:node], @"outletTitle",
                      [NSString stringForXPath:@"outlet/@key" ofNode:node], @"outletKey",
                      nil];
  service = dict;
}

- (NSString *)serviceDisplayTitle
{
  if ([service valueForKey:@"outletTitle"] == nil)
    return [service valueForKey:@"serviceTitle"]; 
    
  return [NSString stringWithFormat:@"%@ %@", 
          [service valueForKey:@"serviceTitle"],
          [service valueForKey:@"outletTitle"]];
}

#pragma mark broadcasts

- (void)setBroadcastData
{
  NSError *error;
  NSArray *data = [xmlDocument nodesForXPath:@".//schedule/*/broadcasts/broadcast" error:&error];
  
  if (error != nil)
    NSLog(@"An Error occured: %@", error);
  
  NSEnumerator *enumerator = [data objectEnumerator];
  NSMutableArray *temp = [NSMutableArray array];
  
  for (NSXMLNode *broadcast in enumerator) {
    NSXMLNode *prog = [[broadcast nodesForXPath:@".//programme[@type=\"episode\"]" 
                                        error:nil] objectAtIndex:0];
    NSDictionary *broadcastDict = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSString stringForXPath:@"display_titles/title" ofNode:prog], @"displayTitle",
      [NSString stringForXPath:@"display_titles/subtitle" ofNode:prog], @"displaySubTitle",
      [NSString stringForXPath:@"short_synopsis" ofNode:prog], @"shortSynopsis",
      [NSString stringForXPath:@"pid" ofNode:prog], @"pid",
      [NSString stringForXPath:@"duration" ofNode:broadcast] , @"duration",
      [self fetchDateForXPath:@"start" withNode:broadcast], @"start",
      [self fetchDateForXPath:@"end" withNode:broadcast], @"end",
      [self fetchDateForXPath:@"media[@format=\"audio\"]/expires" withNode:prog], @"available",
      [NSString stringForXPath:@"media[@format=\"audio\"]/availability" ofNode:prog], @"availableText",
      nil];
    
    [temp addObject:broadcastDict];
  }
  
  [self setBroadcasts:temp];
  [self setCurrentBroadcastData];
}

- (void)setCurrentBroadcastData
{
  NSEnumerator *enumerator = [broadcasts objectEnumerator];
  NSDate *now = [NSDate date];
  [self setCurrentBroadcast:nil];
  
  for (NSDictionary *broadcast in enumerator) {
    NSDate *start = [broadcast valueForKey:@"start"];
    NSDate *end = [broadcast valueForKey:@"end"];
    if (([now compare:start] == NSOrderedDescending) && ([now compare:end] == NSOrderedAscending)) {
      [self setCurrentBroadcast:broadcast];
      NSLog(@"setCurrentBroadcast: %@", currentBroadcast);
      break;
    }
  }
}

- (NSDate *)fetchDateForXPath:(NSString *)string withNode:(NSXMLNode *)node
{
  NSString *stringValue = [NSString stringForXPath:string ofNode:node];
  
  if (stringValue == nil)
    return nil;
  
  NSDate *date = [NSDate dateWithNaturalLanguageString:stringValue]; 
  return date;
}

@end
