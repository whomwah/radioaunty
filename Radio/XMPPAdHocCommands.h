//
//  XMPPAdHocCommands.h
//  Radio
//

/*
 TODO - Impliment the Ad-Hoc Commands work
 
 XMPPAdHocCommands *ahc = [[XMPPAdHocCommands alloc] initWithStream:[self xmppStream]];
 XMPPJID *jid = [XMPPJID jidWithString:@"tv@xmpp.local"];
 [ahc addCommandWithNode:@"station"          andName:@"Switch to station <key>"             andJID:jid];
 [ahc addCommandWithNode:@"station-up"       andName:@"Switch to next station"              andJID:jid];
 [ahc addCommandWithNode:@"station-down"     andName:@"Switch to previous station"          andJID:jid];
 [ahc addCommandWithNode:@"station-now"      andName:@"What's on the current station now"   andJID:jid];
 [ahc addCommandWithNode:@"station-next"     andName:@"What's on the current station next"  andJID:jid];
 [ahc addCommandWithNode:@"station-list"     andName:@"List all available stations"         andJID:jid];
 [ahc addCommandWithNode:@"station-schedule" andName:@"Schedule for station <key>"          andJID:jid];
 [ahc addDelegate:self];
 */

#import <Foundation/Foundation.h>
#import "XMPPModule.h"

@class XMPPStream;
@class XMPPIQ;
@class XMPPJID;

@interface XMPPAdHocCommands : XMPPModule
{
  NSMutableDictionary *commands;
}

@property (nonatomic, readonly) NSMutableDictionary *commands;

- (id)initWithStream:(XMPPStream *)xmppStream;
- (void)addCommandWithNode:(NSString*)node andName:(NSString*)name andJID:(XMPPJID *)jid;
- (void)removeCommandWithNode:(NSString*)node andJID:(XMPPJID *)jid;
- (void)clearCommands;
- (NSXMLElement*)commandListFromJID:(XMPPJID *)jid;

@end

@protocol XMPPAdHocCommandsDelegate
@optional

// A delegate method that exposes any command calls
//
// <iq type='set' to='responder@domain' id='exec1'>
//   <command xmlns='http://jabber.org/protocol/commands' node='list' action='execute'/>
// </iq>

- (void)xmppAdHocCommands:(XMPPAdHocCommands *)sender didReceiveCommand:(NSString*)command forIQ:(XMPPIQ *)iq;

@end

