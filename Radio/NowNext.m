//
//  NowNext.m
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import "NowNext.h"


@implementation NowNext

@synthesize receivedData;
@synthesize title;
@synthesize description;

- (id)init
{
  [super init];	
	return self;
}

- (void)fetchUsing:(NSURL *)url
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
  
  // release the connection, and the data object
  [connection release];
  [receivedData release];
}

@end
