//
//  Scrobble.h
//  Radio
//
//  Created by Duncan Robertson on 20/09/2010.
//  Copyright 2010 whomwah.com All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@protocol ScrobbleDelegate;

@interface Scrobble : NSObject {
  NSString *protocolVersion;
  NSString *clientId;
  NSString *clientVersion;
  NSString *user;
  NSString *apiKey;
  NSString *apiSecret;
  NSString *tmpAuthToken;
  NSString *sessionToken;
  NSString *sessionUser;
  NSTimer *scrobbleTimer;
  NSDictionary *scrobbleBuffer;
  
  NSMutableArray *scrobbleHistory;

  int postHandshake;
  NSDictionary *handshakeData;
  
  id <ScrobbleDelegate> delegate;
}

@property (nonatomic, assign) id <ScrobbleDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *protocolVersion;
@property (nonatomic, copy, readonly) NSString *clientVersion;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *apiSecret;
@property (nonatomic, copy) NSString *tmpAuthToken;
@property (nonatomic, copy) NSString *sessionToken;
@property (nonatomic, copy) NSString *sessionUser;
@property (nonatomic, retain) NSTimer *scrobbleTimer;
@property (nonatomic, retain) NSDictionary *scrobbleBuffer;
@property (nonatomic, retain) NSDictionary *handshakeData;
@property (nonatomic, retain) NSMutableArray *scrobbleHistory;

- (id)initWithApiKey:(NSString *)apikey andSecret:(NSString *)secret;
- (void)fetchRequestToken;
- (void)fetchWebServiceSession;
- (NSString*)urlToAuthoriseUser;
- (NSString*)urlToUnAuthoriseUser;
- (BOOL)isAuthorised;
- (void)flushBuffer;
- (void)clearBuffer;
- (void)clearSession;
- (void)scrobbleWithParams:(NSDictionary*)params error:(NSError **)errPtr;

@end

@protocol ScrobbleDelegate <NSObject>
@optional
- (void)scrobbleDidGetRequestToken:(Scrobble*)sender;
- (void)scrobble:(Scrobble*)sender didNotGetRequestToken:(NSError*)error;
- (void)scrobbleDidGetSessionToken:(Scrobble*)sender;
- (void)scrobble:(Scrobble*)sender didNotGetSessionToken:(NSError*)error;
- (void)scrobble:(Scrobble*)sender didSendNowPlaying:(NSString*)response;
- (void)scrobble:(Scrobble*)sender didNotSendNowPlaying:(NSError*)error;
- (void)scrobble:(Scrobble*)sender didScrobble:(NSString*)response;
- (void)scrobble:(Scrobble*)sender didNotScrobble:(NSError*)error;
- (void)scrobble:(Scrobble*)sender didNotDoScrobbleHandshake:(NSError*)error;
@end
