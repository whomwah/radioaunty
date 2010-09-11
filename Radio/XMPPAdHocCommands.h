//
//  XMPPAdHocCommands.h
//  Radio
//

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

