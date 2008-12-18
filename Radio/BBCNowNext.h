//
//  BBCNowNext.h
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BBCNowNext : NSObject {
  NSString * display_title;
  NSString * short_synopsis;
  NSMutableData * receivedData;
}

@property (retain) NSMutableData * receivedData;
@property (retain) NSString * display_title;
@property (retain) NSString * short_synopsis;

- (id)initUsingService:(NSString *)sv outlet:(NSString *)ol;
- (void)fetch:(NSURL *)url;

// delagates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end
