//
//  FZZMessage3.h
//  Fizz
//
//  Created by Andrew Sweet on 12/20/13.
//  Copyright (c) 2013 Fizz. All rights reserved.
//

/*
 
 Unlike FZZEvent's and FZZUser's, FZZMessage3's are not stored within the FZZMessage3 class, and should instead be maintained as an array of messages externally. This is due to the fact that while a FZZUser is found in multiple events, a FZZMessage3 will only ever be found in one event.
 
 Send messages from this class with the [SocketIONewMessage:... ForEvent:... WithAcknowledge:...] call
 
 WithAcknowledge should generally accept a null object. Whatever SocketIOCallback function is passed to that parameter will be called when the socket object is successfully sent. It may actually be when a callback from the server occurs; I believe it to be the first, and so I don't think it's nearly as useful.
 
 */

@class FZZEvent;
@class FZZUser;
@class FZZCoordinate;

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocketIO.h"

@interface FZZMessage3 : NSManagedObject

@property (retain, nonatomic) NSNumber *messageID;
@property (retain, nonatomic) NSString *text;
@property (retain, nonatomic) NSDate *timestamp;
@property (retain, nonatomic) FZZCoordinate *marker;
@property (retain, nonatomic) FZZEvent *event;
@property (retain, nonatomic) FZZUser  *user;

-(FZZEvent *)event;
-(FZZUser *)user;
-(NSString *)text;
-(FZZCoordinate *)marker;
-(NSDate *)timestamp;
-(NSNumber *)messageID;

-(BOOL)isServerMessage;

-(id)initWithMID:(NSNumber *)mID User:(FZZUser *)inputUser AndText:(NSString *)inputText ForEvent:(FZZEvent *)inputEvent;

+(void)socketIONewMessage:(NSString *)message
                 ForEvent:(FZZEvent *)event
          WithAcknowledge:(SocketIOCallback)function;

+(FZZMessage3 *)parseJSON:(NSDictionary *)messageJSON;
+(NSArray *)parseMessageJSONList:(NSArray *)messageListJSON;

@end
