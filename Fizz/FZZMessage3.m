//
//  FZZMessage3.m
//  Fizz
//
//  Created by Andrew Sweet on 12/20/13.
//  Copyright (c) 2013 Fizz. All rights reserved.
//

#import "FZZMessage3.h"
#import "FZZEvent.h"
#import "FZZUser.h"
#import "FZZCoordinate.h"
#import "FZZSocketIODelegate.h"

static NSString *FZZ_NEW_MESSAGE = @"newMessage";

@interface FZZMessage3 ()

//@property (strong, nonatomic) NSNumber *messageID;

//@property (strong, nonatomic) NSString *text;
//@property (strong, nonatomic) FZZCoordinate *marker;

@property (strong, nonatomic) NSDate *creationTime;

@end

@implementation FZZMessage3

@dynamic messageID;
@dynamic text;
@dynamic timestamp;
@dynamic marker;
@dynamic event;
@dynamic user;

//@synthesize user, text, event, messageID;

-(id)initWithMID:(NSNumber *)mID User:(FZZUser *)inputUser AndText:(NSString *)inputText ForEvent:(FZZEvent *)inputEvent{
    self = [super init];
    
//    self = (FZZMessage3 *)[FZZDataStore insertNewObjectForEntityForName:@"FZZMessage3"];
    
    if (self){
        self.messageID = mID;
        self.user   = inputUser;
        self.text   = inputText;
        self.marker = nil;
        self.event  = inputEvent;
    }
    
    return self;
}

-(id)initWithMID:(NSNumber *)mID User:(FZZUser *)inputUser AndMarker:(FZZCoordinate *)marker ForEvent:(FZZEvent *)inputEvent{
    self = [super init];
    
//    self = (FZZMessage3 *)[FZZDataStore insertNewObjectForEntityForName:@"FZZMessage3"];
    
    if (self){
        self.messageID = mID;
        self.user   = inputUser;
        self.text   = nil;
        self.marker = marker;
        self.event  = inputEvent;
    }
    
    return self;
}

-(NSDate *)creationTime{
    return self.creationTime;
}

-(void)setCreationTime:(NSDate *)creationTime{
    self.creationTime = creationTime;
}

-(FZZUser *)user{
    return self.user;
}

-(BOOL)isServerMessage{
    return self.user == NULL;
}

-(NSString *)text{
    return self.text;
}

-(FZZCoordinate *)marker{
    return self.marker;
}

-(void)setMarker:(FZZCoordinate *)marker{
    self.marker = marker;
}

+(void)socketIONewMessage:(NSString *)text
                 ForEvent:(FZZEvent *)event
          WithAcknowledge:(SocketIOCallback)function{
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    /* eid : int */
    [json setObject:[event eventID] forKey:@"eid"];
    
    /* message : string */
    [json setObject:text forKey:@"text"];
    
    [[FZZSocketIODelegate socketIO] sendEvent:FZZ_NEW_MESSAGE withData:json andAcknowledge:function];
}

+(FZZMessage3 *)parseJSON:(NSDictionary *)messageJSON{
    if (messageJSON == NULL){
        return NULL;
    }
    
    // Message ID
    NSNumber *mid = [messageJSON objectForKey:@"mid"];
    
    // Event ID (Event this message belongs to)
    FZZEvent *event;
    {
        NSNumber *eid = [messageJSON objectForKey:@"eid"];
        event = [FZZEvent eventWithEID:eid];
    }
    
    // User ID of the message poster
    FZZUser *user;
    
    {
        NSNumber *uid = [messageJSON objectForKey:@"uid"];
        
        switch ([uid integerValue]) {
            case -1:
                user = NULL;
                break;
                
            default:
                user = [FZZUser userWithUID:uid];
                break;
        }
    }
    
    // Text of the message sent
    NSString *text = [messageJSON objectForKey:@"text"];
    
    FZZCoordinate *marker;
    
    if (!text){
        marker = [FZZCoordinate parseJSON:[messageJSON objectForKey:@"latlng"]];
    }
    
    // When this message was created
    NSDate *creationTime;
    {
        NSNumber *creationTimeNum = [messageJSON objectForKey:@"creationTime"];
        creationTime = [NSDate dateWithTimeIntervalSince1970:[creationTimeNum integerValue]];
    }
    
    FZZMessage3 *message;
    
    // Message can either contain a marker or text
    if (text){
        message = [[FZZMessage3 alloc] initWithMID:mid
                                             User:user
                                          AndText:text
                                         ForEvent:event];
    } else {
        message = [[FZZMessage3 alloc] initWithMID:mid
                                             User:user
                                        AndMarker:marker
                                         ForEvent:event];
    }
    
    message.creationTime = creationTime;
    
    return message;
}

+(NSArray *)parseMessageJSONList:(NSArray *)messageListJSON{
    if (messageListJSON == NULL){
        return NULL;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithArray:messageListJSON];
    
    [messageListJSON enumerateObjectsUsingBlock:^(id messageJSON, NSUInteger index, BOOL *stop) {
        FZZMessage3 *message = [FZZMessage3 parseJSON:messageJSON];
        [result setObject:message atIndexedSubscript:index];
    }];
    
    return result;
}

- (NSDictionary *)jsonDict{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:self.messageID forKey:@"mid"];
    [dict setObject:self.event.eventID forKey:@"eid"];
    [dict setObject:self.user.userID forKey:@"uid"];
    
    NSNumber *creationTime = [NSNumber numberWithInt:[self.creationTime timeIntervalSince1970]];
    
    [dict setObject:creationTime forKey:@"creationTime"];
    
    if (self.text){
        [dict setObject:self.text forKey:@"text"];
    }
    
    if (self.marker){
        [dict setObject:[self.marker jsonDict] forKey:@"marker"];
    }
    
    return dict;
}

-(NSDate *)timestamp{
    return self.creationTime;
}

-(FZZEvent *)event{
    return self.event;
}

-(NSNumber *)messageID{
    return self.messageID;
}

@end
