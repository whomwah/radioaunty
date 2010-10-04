//
//  Scrobble.m
//  Radio
//
//  Created by Duncan Robertson on 20/09/2010.
//  Copyright 2010 whomwah.com All rights reserved.
//

#import "Scrobble.h"
#import "JSON.h"
#import "GDataHTTPFetcher.h"

#define LFM_HANDSHAKE       @"http://post.audioscrobbler.com/?hs=true&p=%@&c=%@&v=%@&u=%@&t=%@&a=%@&api_key=%@&sk=%@"
#define LFM_NOWPLAYING      @"s=%@&a=%@&t=%@&b=%@&l=%@&n=%@&m=%@"
#define LFM_SCROBBLE        @"s=%@&a[0]=%@&t[0]=%@&i[0]=%@&o[0]=%@&r[0]=%@&l[0]=%@&b[0]=%@&n[0]=%@&m[0]=%@"
#define LFM_REQUEST_TOKEN   @"http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=%@&api_sig=%@&format=json"
#define LFM_REQUEST_SESSION @"http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=%@&token=%@&api_sig=%@&format=json"
#define LFM_AUTH            @"http://www.last.fm/api/auth/?api_key=%@&token=%@"
#define LFM_UNAUTH          @"http://www.last.fm/settings/applications"

enum {
  STATE_STANDBY,
	STATE_NOWPLAYING,
	STATE_SCROBBLE,
  STATE_SCHEDULE_SCROBBLE,
};

@interface Scrobble (PrivateMethods)
- (NSString*)sigForMethod:(NSString*)method withOptions:(NSDictionary*)options;
- (void)scrobble;
- (BOOL)scrobbleActive;
- (void)scrobbleTimerEnded:(id)sender;
- (void)sendNowPlaying;
- (void)scheduleScrobble;
- (void)sendScrobble:(id)sender;
@end

@implementation Scrobble

@synthesize delegate;
@synthesize protocolVersion;
@synthesize clientId;
@synthesize clientVersion;
@synthesize user;
@synthesize apiKey;
@synthesize apiSecret;
@synthesize tmpAuthToken;
@synthesize sessionToken;
@synthesize sessionUser;
@synthesize scrobbleTimer;
@synthesize scrobbleBuffer;
@synthesize handshakeData;
@synthesize scrobbleHistory;

- (id)init
{
  [self dealloc];
  @throw [NSException exceptionWithName:@"DSRBadInitCall" 
                                 reason:@"Dedicated initializer: initWithApiKey:andSessionKey:" 
                               userInfo:nil];
  return nil;
}

- (void)dealloc
{  
  [protocolVersion release];
  [clientId release];
  [clientVersion release];
  [user release];
  [apiKey release];
  [apiSecret release];
  [tmpAuthToken release];
  [sessionUser release];
  [sessionToken release];
  [scrobbleTimer release];
  [scrobbleBuffer release];
  [handshakeData release];
  [scrobbleHistory release];
  
	[super dealloc];
}

/**
 * Sets some defaults used buy both init methods
 **/

- (void)commonInit
{
  protocolVersion       = @"1.2.1";
  clientVersion         = @"1.0";
  self.clientId         = @"tst";
  postHandshake         = STATE_STANDBY;
  self.scrobbleHistory  = [NSMutableArray arrayWithCapacity:1];
}

/**
 * default initializer. requires passing in a valid api key and secret
 **/

- (id)initWithApiKey:(NSString *)apikey andSecret:(NSString *)secret
{
  if (![super init]) return nil;
  
  [self commonInit];
  
  if (!apikey || [apikey isEqual:@""] || !secret || [secret isEqual:@""]) {
    @throw [NSException exceptionWithName:@"DSArgumentError" 
                                   reason:@"initWithApiKey:andSecret: - api_key and secret required" 
                                 userInfo:nil];    
  };
  
  self.apiKey           = apikey; 
  self.apiSecret        = secret;
  
  return self;
}


#pragma mark -
#pragma mark Utilities
#pragma mark -

/**
 * Useful help method that generates an MD5 hash from a string. This is
 * required for the signing of request parameters.
 * from http://www.saobart.com/md5-has-in-objective-c/
 **/

- (NSString*)toMD5:(NSString*)concat
{
  const char *concat_str = [concat UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(concat_str, strlen(concat_str), result);
  NSMutableString *hash = [NSMutableString string];
  for (int i = 0; i < 16; i++) {
    [hash appendFormat:@"%02X", result[i]];
  }
  return [hash lowercaseString];  
}

/**
 * the 2.0 api expects you to provide a signature in all request. This consists
 * of concatinated string of all key-value pairs, along with the secret. Finally
 * this information should be returned as an MD5 hash.
 **/

- (NSString*)sigForMethod:(NSString*)method withOptions:(NSDictionary*)options
{
  if (!method || [method isEqual:@""]) {
    @throw [NSException exceptionWithName:@"DSArgumentError" 
                                   reason:@"sigForMethod:withOptions:options - Method required" 
                                 userInfo:nil];
  }
  
  NSMutableDictionary *opts = [[NSMutableDictionary alloc] initWithCapacity:2];
  
  if (options) [opts setDictionary:options];
  [opts setObject:method forKey:@"method"];
  [opts setObject:self.apiKey forKey:@"api_key"];
  
  NSArray *keys = [[opts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];  
  NSMutableString *result = [NSMutableString stringWithCapacity:[self.apiKey length]];
  
  for (NSString *key in keys) {
    [result appendString:[NSString stringWithFormat:@"%@%@", key, [opts objectForKey:key]]];
  }
  
  [result appendString:self.apiSecret];
  
  [opts release];

  return [self toMD5:result];
}

/**
 * Decide whether we think this session is authorised based on the existence
 * of a session token.
 **/

- (BOOL)isAuthorised
{
  if (sessionToken != nil && ![sessionToken isEqual:@""]) {
    return YES;
  }
  
  return NO;
}

/**
 * returns a url to where the user can un-authorise their application. This page
 * displays all applications that are linked to their lastfm account
 **/

- (NSString*)urlToUnAuthoriseUser
{
  return LFM_UNAUTH;
}

/**
 * using the temp auth token, returns a url to where you actually link your
 * application to your lastfm account.
 **/

- (NSString*)urlToAuthoriseUser
{
  if (!tmpAuthToken) {
    @throw [NSException exceptionWithName:@"DSTokenError" 
                                   reason:@"urlToAuthoriseUser - No auth token found" 
                                 userInfo:nil];
  }
  
  return [NSString stringWithFormat:LFM_AUTH, apiKey, tmpAuthToken];
}


#pragma mark -
#pragma mark Authentication methods
#pragma mark -

/**
 * Part one of authentication. This methods makes a request to the 
 * lastfm api and returns a request token to use further on in the 
 * authentication process.
 **/

- (void)fetchRequestToken
{
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"auth.getToken" withOptions:nil]; 
  
  // build the final url
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:LFM_REQUEST_TOKEN, self.apiKey, sig]];
  
  // build our request and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher* tokenFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
  
  // send the request
  [tokenFetcher beginFetchWithDelegate:self
                     didFinishSelector:@selector(tokenFetcher:finishedWithData:)
                       didFailSelector:@selector(tokenFetcher:failedWithError:)];  
}

- (void)tokenFetcher:(GDataHTTPFetcher *)tokenFetcher failedWithError:(NSError *)error
{
  [[self delegate] scrobble:self didNotGetRequestToken:error];
}

- (void)tokenFetcher:(GDataHTTPFetcher *)tokenFetcher finishedWithData:(NSData *)retrievedData
{
  // create a JSON parser
  SBJSON *parser = [[SBJSON alloc] init];
  
  // fetch the result as a string
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  
  // parse the json string
  self.tmpAuthToken = [[parser objectWithString:result_string error:nil] objectForKey:@"token"];
  
  // we're done with the parser
  [parser release];
  [result_string release];
  
  // pass the delegate the token
  [[self delegate] scrobbleDidGetRequestToken:self];
}

/**
 * When combined with the tmp auth token and other required params
 * we can now attempt to fetch a session token we can use for all
 * our API calls.
 **/

- (void)fetchWebServiceSession
{                         
  // create an options dictionary
  NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                        self.tmpAuthToken, @"token",
                        nil];
  
  // create the signature using the options
  NSString *sig = [self sigForMethod:@"auth.getSession" withOptions:opts]; 
  
  // create the final url
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:LFM_REQUEST_SESSION, 
                                     self.apiKey, self.tmpAuthToken, sig]];
  
  // create a request object and fetcher
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher* sessionFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
  
  // make the request
  [sessionFetcher beginFetchWithDelegate:self
                       didFinishSelector:@selector(sessionFetcher:finishedWithData:)
                         didFailSelector:@selector(sessionFetcher:failedWithError:)];
  
  // clear the tmp auth token
  tmpAuthToken = nil;
}

- (void)sessionFetcher:(GDataHTTPFetcher *)tokenFetcher failedWithError:(NSError *)error
{
  [[self delegate] scrobble:self didNotGetSessionToken:error];
}

- (void)sessionFetcher:(GDataHTTPFetcher *)tokenFetcher finishedWithData:(NSData *)retrievedData
{
  SBJSON *parser = [[SBJSON alloc] init];
  
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  NSDictionary *results = [[parser objectWithString:result_string error:nil] objectForKey:@"session"];
  sessionToken = [[results objectForKey:@"key"] retain];
  sessionUser = [[results objectForKey:@"name"] retain];
  
  [parser release];
  [result_string release];
  
  [[self delegate] scrobbleDidGetSessionToken:self];
}


#pragma mark -
#pragma mark Scrobble methods
#pragma mark -

/**
 * Returns YES if the track in the buffer has been there for over 2 minutes.
 * This is a crude workround of the fact that we don't currently get any duration
 * information from livetext about the track playing, so we have to make a call
 * ourselves on whether to play the track. Hopefully, we can start to get duration
 * information in the future.
 **/

- (BOOL)playingLongEnough
{
  NSDate *started = [scrobbleBuffer objectForKey:@"timestamp"];
  
  if (!started) {
    return NO;
  }
  
  return (fabs([started timeIntervalSinceDate:[NSDate date]]) > 120);
}

/**
 * Returns YES if it looks like we have track information available to scrobble.
 * This is the case if the timer and buffer are not empty and are valid.
 **/

- (BOOL)scrobbleActive
{
  return (scrobbleTimer && [scrobbleTimer isValid] && scrobbleBuffer) ? YES : NO;
}

/**
 * Checks to see if we have any active information, and also whether that
 * information has been there for over 2 minutes. If so, it will scrobble it.
 * NOTE. When scrobbling livetext nowplaying information, we don't have any
 * track duration information. It makes it impossible to know how much of a
 * record has been played, so we have to hardcode a threshhold.
 *
 * After the above, this method also clears the buffer. 
 **/

- (void)flushBuffer
{    
  if ([self scrobbleActive] && [self playingLongEnough]) {
    [self sendScrobble:nil];
    [self clearBuffer];
  }
}

/**
 * Invalidates and clears the timer, and also clears the buffer
 **/

- (void)clearBuffer
{  
  if (scrobbleTimer != nil) {
    if ([scrobbleTimer isValid]) [scrobbleTimer invalidate];
    self.scrobbleTimer = nil;
  }
  
  self.scrobbleBuffer = nil;
}

/**
 * Clear the session. Basically this is what you call if you are
 * unauthorising, and want to clear everything
 **/

- (void)clearSession
{
  [self clearBuffer];
  self.sessionToken = nil;
  self.sessionUser = nil;
  self.handshakeData = nil;
  postHandshake = STATE_STANDBY;
}


#pragma mark -
#pragma mark scrobble methods
#pragma mark -

/**
 * A handshake is required for a scrobble session in the 1.2.1 version of the API.
 * This requires sending of a bunch of data, and getting back a token to use on
 * future submissions, as well as the urls to send submissions and now playing data
 **/

- (void)doHandShake
{
  NSDate *now = [NSDate date];
  NSString *timestamp = [NSString stringWithFormat:@"%0.0f", [now timeIntervalSince1970]];
  NSString *token = [self toMD5:[NSString stringWithFormat:@"%@%@", self.apiSecret, timestamp]]; 
  
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:LFM_HANDSHAKE, 
                                     self.protocolVersion, 
                                     self.clientId,
                                     self.clientVersion,
                                     self.sessionUser,
                                     timestamp,
                                     token,
                                     self.apiKey,
                                     self.sessionToken
                                     ]];
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher* handshakeFetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
  
  [handshakeFetcher beginFetchWithDelegate:self
                         didFinishSelector:@selector(handshakeFetcher:finishedWithData:)
                           didFailSelector:@selector(handshakeFetcher:failedWithError:)];
}

- (void)handshakeFetcher:(GDataHTTPFetcher *)tokenFetcher failedWithError:(NSError *)error
{
  self.handshakeData = nil;
  postHandshake      = STATE_STANDBY;
  
  [[self delegate] scrobble:self didNotDoScrobbleHandshake:error];
}

- (void)handshakeFetcher:(GDataHTTPFetcher *)tokenFetcher finishedWithData:(NSData *)retrievedData
{
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
  NSArray   *result_array = [result_string componentsSeparatedByString:@"\n"];
 
  if ([[result_array objectAtIndex:0] isEqual:@"OK"]) {
    self.handshakeData = [NSDictionary dictionaryWithObjectsAndKeys:
                          [result_array objectAtIndex:1], @"sessionID",
                          [result_array objectAtIndex:2], @"nowplayingURL",
                          [result_array objectAtIndex:3], @"submissionURL",
                          nil];
  }
  
  [result_string release];
  
  if (postHandshake == STATE_NOWPLAYING) {
    [self sendNowPlaying];
  } else if (postHandshake == STATE_SCHEDULE_SCROBBLE) {
    [self scheduleScrobble];
  } else if (postHandshake == STATE_SCROBBLE) {
    [self sendScrobble:nil];
  }
}

/**
 * Here we send the now playing data, and set the timer that will
 * actually submit the scrobble data. The timer is based on one of lastfm's
 * submission critera (the track must have been played for a duration of at 
 * least 240 seconds)
 **/

- (void)scheduleScrobble
{
  if (!handshakeData) {
    postHandshake = STATE_SCHEDULE_SCROBBLE;
    [self doHandShake];
    return;
  }
  
  [self sendNowPlaying];
  
  NSDictionary *info = [NSDictionary dictionaryWithDictionary:self.scrobbleBuffer];
  self.scrobbleTimer = [NSTimer scheduledTimerWithTimeInterval:240.0 // 4 minutes
                                                        target:self
                                                      selector:@selector(sendScrobble:)
                                                      userInfo:info
                                                       repeats:NO];
}

- (void)sendNowPlaying
{  
  // check we don't need to do the handshake
  if (!handshakeData) {
    postHandshake = STATE_NOWPLAYING;
    [self doHandShake];
    return;
  }
  
  NSString *a = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                    (CFStringRef)[scrobbleBuffer objectForKey:@"artist"], NULL, 
                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
  
  NSString *t = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                    (CFStringRef)[scrobbleBuffer objectForKey:@"track"], NULL,
                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
  
  NSString *params = [NSString stringWithFormat:LFM_NOWPLAYING, 
                      [handshakeData objectForKey:@"sessionID"], 
                      a, t, @"", @"", @"", @""];
  [a release];
  [t release];
  
  NSURL *url = [NSURL URLWithString:[handshakeData objectForKey:@"nowplayingURL"]];  
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher *sendNowPlaying = [GDataHTTPFetcher httpFetcherWithRequest:request];
  [sendNowPlaying setPostData:[params dataUsingEncoding:NSUTF8StringEncoding]];
  [sendNowPlaying beginFetchWithDelegate:self
                       didFinishSelector:@selector(sendNowPlaying:finishedWithData:)
                         didFailSelector:@selector(sendNowPlaying:failedWithError:)];
  NSLog(@"Sending Now Playing");
}

- (void)sendNowPlaying:(GDataHTTPFetcher *)sendNowPlaying failedWithError:(NSError *)error
{
  [[self delegate] scrobble:self didNotSendNowPlaying:error];
}

- (void)sendNowPlaying:(GDataHTTPFetcher *)sendNowPlaying finishedWithData:(NSData *)retrievedData
{  
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];  
  NSArray   *result_array = [result_string componentsSeparatedByString:@"\n"];
  
  if ([[result_array objectAtIndex:0] isEqual:@"OK"]) {
    [[self delegate] scrobble:self didSendNowPlaying:[result_array objectAtIndex:0]];    
  }
  
  [result_string release];
}

- (void)sendScrobble:(id)sender
{
  if (!handshakeData) {
    postHandshake = STATE_SCROBBLE;
    [self doHandShake];
    return;
  }
  
  NSDictionary *opts = sender ? [sender userInfo] : self.scrobbleBuffer;
  
  NSString *a = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                    (CFStringRef)[scrobbleBuffer objectForKey:@"artist"], NULL, 
                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
  
  NSString *t = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                    (CFStringRef)[scrobbleBuffer objectForKey:@"track"], NULL,
                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
  
  NSString *timestamp = [NSString stringWithFormat:@"%0.0f", [[opts objectForKey:@"timestamp"] timeIntervalSince1970]];
  NSString *params = [NSString stringWithFormat:LFM_SCROBBLE,
                      [handshakeData objectForKey:@"sessionID"], 
                      a, t, timestamp, @"R", @"", @"", @"", @"", @""];
  
  [a release];
  [t release];
  
  NSURL *url = [NSURL URLWithString:[handshakeData objectForKey:@"submissionURL"]];  
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  GDataHTTPFetcher *sendSubmission = [GDataHTTPFetcher httpFetcherWithRequest:request];
  [sendSubmission setPostData:[params dataUsingEncoding:NSUTF8StringEncoding]];
  [sendSubmission beginFetchWithDelegate:self
                       didFinishSelector:@selector(sendSubmission:finishedWithData:)
                         didFailSelector:@selector(sendSubmission:failedWithError:)];
  
  NSLog(@"Sending Scrobble");
  
  [self clearBuffer];
}

- (void)sendSubmission:(GDataHTTPFetcher *)sendNowPlaying failedWithError:(NSError *)error
{
  [[self delegate] scrobble:self didNotScrobble:error];
}

- (void)sendSubmission:(GDataHTTPFetcher *)sendNowPlaying finishedWithData:(NSData *)retrievedData
{  
  NSString *result_string = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];  
  NSArray   *result_array = [result_string componentsSeparatedByString:@"\n"];
  
  if ([[result_array objectAtIndex:0] isEqual:@"OK"]) {
    [[self delegate] scrobble:self didScrobble:[result_array objectAtIndex:0]];    
  }
  
  [result_string release];
}

- (void)scrobbleWithParams:(NSDictionary*)params error:(NSError **)errPtr
{
  if (![self isAuthorised] && errPtr)
  {
    NSString *errMsg = @"Attempting to scrobble when not authorised";
    NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    
    *errPtr = [NSError errorWithDomain:@"Scrobble" code:-1 userInfo:info];
    
    return;
  }
  
  if (!params && errPtr)
  {
    NSString *errMsg = @"Attempting to scrobble without providing any parameters";
    NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    
    *errPtr = [NSError errorWithDomain:@"Scrobble" code:-1 userInfo:info];
    
    return;
  }
  
  [self flushBuffer];
  
  NSMutableDictionary *buffer = [[NSMutableDictionary alloc] initWithCapacity:1];
  [buffer addEntriesFromDictionary:params];
  [buffer setObject:[NSDate date] forKey:@"timestamp"];
  self.scrobbleBuffer = buffer;
  [scrobbleHistory addObject:buffer];
  [buffer release];
  
  [self scheduleScrobble];
  
  //NSLog(@"history: %@", scrobbleHistory);
}

@end