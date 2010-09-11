//
//  XMPPAdHocCommands.h
//  Radio
//

#import "XMPPAdHocCommands.h"
#import "XMPP.h"

#define INTEGRATE_WITH_CAPABILITIES 1

#if INTEGRATE_WITH_CAPABILITIES
#import "XMPPCapabilities.h"
#endif

@implementation XMPPAdHocCommands

@synthesize commands;

- (id)initWithStream:(XMPPStream *)aXmppStream
{
	if ((self = [super initWithStream:aXmppStream]))
	{
    commands = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		
#if INTEGRATE_WITH_CAPABILITIES
		[xmppStream autoAddDelegate:self toModulesOfClass:[XMPPCapabilities class]];
#endif
	}
	return self;
}

- (void)dealloc
{
#if INTEGRATE_WITH_CAPABILITIES
	[xmppStream removeAutoDelegate:self fromModulesOfClass:[XMPPCapabilities class]];
#endif
  
  [commands release];
	
	[super dealloc];
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
  
	if ([iq isGetIQ])
	{
    
    // the namespace will be #info or #items
    // so make sure we know which one it is
    
    NSXMLElement *cmd = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"];
    
    if (!cmd) {
      cmd = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/disco#info"];
    }
    
    if (!cmd) return NO;

    NSString *node  = [[cmd attributeForName:@"node"] stringValue];
    NSString *key = [NSString stringWithFormat:@"%@-%@", node, [[iq from] bare]];
    NSString *xmlns = [cmd xmlns];

    NSXMLElement *query;
    XMPPIQ *iqnode;
    
    // if the request is asking for a command list
    //
    // <iq type='get' from='requester@domain' to='responder@domain'>
    //   <query xmlns='http://jabber.org/protocol/disco#items' node='http://jabber.org/protocol/commands'/>
    // </iq>
    //
    
		if ([xmlns isEqualToString:@"http://jabber.org/protocol/disco#items"] == YES &&
        [node isEqualToString:@"http://jabber.org/protocol/commands"] == YES)
		{
      
      //
      // <iq type='result' to='requester@domain' from='responder@domain'>
      //   <query xmlns='http://jabber.org/protocol/disco#items' node='http://jabber.org/protocol/commands'>
      //     <item jid='responder@domain' node='list' name='List Service Configurations'/>
      //     <item jid='responder@domain' node='config' name='Configure Service'/>
      //     <item jid='responder@domain' node='reset' name='Reset Service Configuration'/>
      //     <item jid='responder@domain' node='start' name='Start Service'/> 
      //   </query>
      // </iq>
      
      query = [self commandListFromJID:[iq from]];
       
      iqnode = [XMPPIQ iqWithType:@"result" to:[iq from]];
      [iqnode addChild:query];
      
      [sender sendElement:iqnode];

			return YES;
    
    // is the request asking for more command information
    //
    // <iq type='get' from='requester@domain' to='responder@domain'>
    //   <query xmlns='http://jabber.org/protocol/disco#info' node='config'/>
    // </iq>
    //
      
		}
    else if ([xmlns isEqualToString:@"http://jabber.org/protocol/disco#info"] == YES &&
             [commands objectForKey:key])
    {
      
      //
      // <iq type='result' to='requester@domain' from='responder@domain'>
      //   <query xmlns='http://jabber.org/protocol/disco#info' node='config'>
      //     <identity name='Configure Service' category='automation' type='command-node'/>
      //     <feature var='http://jabber.org/protocol/commands'/>
      //     <feature var='jabber:x:data'/>
      //   </query>
      //  </iq>
      //
            
      query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#info"];
      [query addAttributeWithName:@"node" stringValue:node];
      
      NSXMLElement *identity = [NSXMLElement elementWithName:@"identity"];
      [identity addAttributeWithName:@"category"  stringValue:@"automation"];
      [identity addAttributeWithName:@"type"  stringValue:@"command-node"];
      [identity addAttributeWithName:@"name"  stringValue:[commands objectForKey:key]];
      [query addChild:identity];

      NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
      [feature addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/commands"];
      [query addChild:feature];
      
      feature = [NSXMLElement elementWithName:@"feature"];
      [feature addAttributeWithName:@"var" stringValue:@"jabber:x:data"];
      [query addChild:feature];
      
      iq = [XMPPIQ iqWithType:@"result" to:[iq from]];
      [iq addChild:query];
      
      [sender sendElement:iq];
      
			return YES;
    }
  
	} 
  else if ([iq isSetIQ])
  {
    
    //
    //  <iq type='set' to='responder@domain' id='exec1'>
    //    <command xmlns='http://jabber.org/protocol/commands' node='list' action='execute'/>
    //  </iq>
    //
    
    NSXMLElement *action = [iq elementForName:@"command" xmlns:@"http://jabber.org/protocol/commands"];
    NSString *command  = [[action attributeForName:@"node"] stringValue];
    NSString *commandKey = [NSString stringWithFormat:@"%@-%@", command, [[iq from] bare]];
    
    // it looks like someones trying to execute a command
    // lets check the command exists and is understood
    
    if (action && command && [commands objectForKey:commandKey])
    {
      [multicastDelegate xmppAdHocCommands:self didReceiveCommand:command forIQ:iq];
      
      return YES;
    }
  }
  
	return NO;
}


- (void)addCommandWithNode:(NSString*)node andName:(NSString*)name andJID:(XMPPJID *)jid
{
  NSString *key = [NSString stringWithFormat:@"%@-%@", node, [jid bare]];
  
  if (![commands objectForKey:key]) {
    [commands setObject:name forKey:key];
  }
}


- (void)removeCommandWithNode:(NSString*)node andJID:(XMPPJID *)jid
{
  NSString *key = [NSString stringWithFormat:@"%@-%@", node, [jid bare]];
  
  [commands removeObjectForKey:key];
}


- (void)clearCommands
{
  [commands removeAllObjects];
}


- (NSXMLElement*)commandListFromJID:(XMPPJID *)jid
{
  //   <query xmlns='http://jabber.org/protocol/disco#items' node='http://jabber.org/protocol/commands'>
  //     <item jid='responder@domain' node='list' name='List Service Configurations'/>
  //     <item jid='responder@domain' node='config' name='Configure Service'/>
  //     <item jid='responder@domain' node='reset' name='Reset Service Configuration'/>
  //     <item jid='responder@domain' node='start' name='Start Service'/> 
  //   </query>
  
  NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
  [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
  [query addAttributeWithName:@"node"  stringValue:@"http://jabber.org/protocol/commands"];
  
  for (NSString *key in commands) {  
    
    NSXMLElement *el = [NSXMLElement elementWithName:@"item"];
    [el addAttributeWithName:@"jid"  stringValue:[jid full]];
    [el addAttributeWithName:@"node" stringValue:key];
    [el addAttributeWithName:@"name" stringValue:[commands objectForKey:key]];
    
    [query addChild:el];
  }
  
  return query;
}


#if INTEGRATE_WITH_CAPABILITIES
/**
 * If an XMPPCapabilites instance is used we want to advertise our support for ad-hoc commands.
 **/
- (void)xmppCapabilities:(XMPPCapabilities *)sender willSendMyCapabilities:(NSXMLElement *)query
{
	// <query xmlns="http://jabber.org/protocol/disco#info">
	//   ...
	//   <feature var='http://jabber.org/protocol/commands'/>
	//   ...
	// </query>
	
	NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
	[feature addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/commands"];
	
	[query addChild:feature];
}
#endif

@end
