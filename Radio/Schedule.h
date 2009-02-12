//
//  Schedule.h
//  Radio
//
//  Created by Duncan Robertson on 18/12/2008.
//  Copyright 2008 Whomwah. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Service;
@class Broadcast;

@interface Schedule : NSObject {
  float expectedLength;
  
  NSMutableData *receivedData;
  NSXMLDocument *xmlDocument;
  
  NSDate *lastUpdated;
  NSString *serviceKey;
  NSString *outletKey;
  NSString *displayTitle;
  NSString *displaySynopsis;
  NSArray *broadcasts;
  
  Broadcast *currentBroadcast;
  Service *service;
}

@property (nonatomic, copy) NSString *displayTitle;
@property (nonatomic, copy) NSString *displaySynopsis;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSArray *broadcasts;
@property (nonatomic, retain) Broadcast *currentBroadcast;
@property (nonatomic, retain) Service *service;

- (id)initUsingService:(NSString *)sv outlet:(NSString *)ol;
- (NSURL *)buildUrl;
- (void)fetch:(NSURL *)url;

- (void)setServiceData;
- (void)setBroadcastData;
- (void)setCurrentBroadcastData;

// delagates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end
