//
//  BBCSchedule.m
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "BBCSchedule.h"

@implementation BBCSchedule

@synthesize receivedData;
@synthesize display_title;
@synthesize short_synopsis;

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
  
  NSString * outlet;
  NSString * service = sv;
    
  if (ol) {
    outlet = [NSString stringWithFormat:@"%@/", ol];
  } else {
    outlet = @"";
  }
    
  NSString * urlString = [NSString stringWithFormat:@"http://www.bbc.co.uk/%@/programmes/schedules/%@upcoming.xml", service, outlet];
  NSLog(@"NowNext: %@", urlString);
  [self fetch:[NSURL URLWithString:urlString]];
  
  return self;
}

- (void)fetch:(NSURL *)url
{
  // create the request
  NSURLRequest * theRequest = [NSURLRequest requestWithURL:url
                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                           timeoutInterval:60.0];
  // create the connection with the request
  // and start loading the data
  NSURLConnection * theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
  if (theConnection) {
    // Create the NSMutableData that will hold
    // the received data
    // receivedData is declared as a method instance elsewhere
    self.receivedData = [[NSMutableData data] retain];
  } else {
    // inform the user that the download could not be made
    NSLog(@"download failed!");
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [receivedData appendData:data];
  NSLog(@"data fetched");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [connection release];
  [receivedData release];
  
  // inform the user
  NSLog(@"Connection failed! Error - %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  // do something with the data
  NSLog(@"Succeeded! Received %d bytes of data", [receivedData length]);
  
  NSError * error;
  NSXMLDocument * doc;
  NSArray * dTitle;
  NSArray * dSynopsis;
  
  doc = [[NSXMLDocument alloc] initWithData:receivedData options:0 error:&error];
  
  dTitle = [doc nodesForXPath:@".//now/broadcast/*/display_titles/title" error:&error];
  if ([dTitle count] > 0) {
    self.display_title = [[dTitle objectAtIndex:0] stringValue];
  }
  
  dSynopsis = [doc nodesForXPath:@".//now/broadcast/*/short_synopsis" error:&error];
  if ([dSynopsis count] > 0) {
    self.short_synopsis = [[dSynopsis objectAtIndex:0] stringValue];
  }
  
  // release the connection, and the data object
  [doc release];
  [connection release];
  [receivedData release];
}

@end
