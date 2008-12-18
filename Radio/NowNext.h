//
//  NowNext.h
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NowNext : NSObject {
  NSString * title;
  NSString * description;
  NSMutableData * receivedData;
}

@property (retain) NSMutableData * receivedData;
@property (retain) NSString * title;
@property (retain) NSString * description;

- (void)fetchUsing:(NSURL *)url;

// delagates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end
