//
//  FZZ_IOSocketDelegate.m
//  Fizz
//
//  Created by Andrew Sweet on 12/20/13.
//  Copyright (c) 2013 Fizz. All rights reserved.
//

#import "FZZSocketIODelegate.h"
#import "FZZ_Reachability.h"
#import "SBJson4.h"
#import "FZZEvent.h"
#import "FZZUser.h"
#import "FZZMessage.h"
#import "FZZAppDelegate.h"
#import "FZZInviteViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

static NSString *FZZ_INCOMING_ON_LOGIN = @"onLogin";
static NSString *FZZ_INCOMING_NEW_FRIEND = @"newFriend";
static NSString *FZZ_INCOMING_NEW_EVENT = @"newEvent";
static NSString *FZZ_INCOMING_ADD_GUEST = @"addGuest";
static NSString *FZZ_INCOMING_REMOVE_GUEST = @"removeGuest";
static NSString *FZZ_INCOMING_NEW_INVITE_LIST = @"newInviteList";
static NSString *FZZ_INCOMING_NEW_MESSAGE = @"newMessage";
static NSString *FZZ_INCOMING_SET_SEAT_CAPACITY = @"setSeatCapacity";
static NSString *FZZ_INCOMING_PRESENT_AT_EVENT_LIST_UPDATES = @"presentAtEventListUpdates";

static BOOL hasMadeDelegate = NO;
static FZZSocketIODelegate *delegate;

static SocketIO *socketIO;

static NSDictionary *incomingEventResponses;

static int reconnectDelay;
static BOOL connected;
static BOOL resignedActive;
static BOOL didAjax;
static NSURLConnection *connection;
static NSMutableData *data;

@interface FZZSocketIODelegate ()

//@property (strong, nonatomic) SocketIO *socketIO;

//@property NSDictionary *incomingEventResponses;

//@property int reconnectDelay;
//@property BOOL connected;
//@property BOOL resignedActive;
////@property (strong, nonatomic) NSString *fizzSessionToken;
//@property BOOL didAjax;
//@property (strong, nonatomic) NSURLConnection *connection;
//@property (strong, nonatomic) NSMutableData *data;

@end

@implementation FZZSocketIODelegate

//@synthesize socketIO, reconnectDelay, connected, incomingEventResponses,
//            didAjax, connection, data, resignedActive;

-(id) init{
    if (hasMadeDelegate){
        return NULL;
    }
    
    self = [super init];
    
    if (self){
        hasMadeDelegate = YES;
        delegate = self;
        reconnectDelay = kFZZDefaultReconnectDelay;
        socketIO = [[SocketIO alloc] initWithDelegate:self];
        connected = NO;
        didAjax = NO;
        resignedActive = NO;
        
        incomingEventResponses = [[NSMutableDictionary alloc] init];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingOnLogin:))
                                  forKey:FZZ_INCOMING_ON_LOGIN];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingNewFriend:))
                                  forKey:FZZ_INCOMING_NEW_FRIEND];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingNewEvent:))
                                  forKey:FZZ_INCOMING_NEW_EVENT];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingAddGuest:))
                                  forKey:FZZ_INCOMING_ADD_GUEST];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingRemoveGuest:))
                                  forKey:FZZ_INCOMING_REMOVE_GUEST];
                                                              
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingNewInviteList:))
                                  forKey:FZZ_INCOMING_NEW_INVITE_LIST];
                                                              
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingNewMessage:))
                                  forKey:FZZ_INCOMING_NEW_MESSAGE];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingSetSeatCapacity:))
                                  forKey:FZZ_INCOMING_SET_SEAT_CAPACITY];
        
        [incomingEventResponses setValue:NSStringFromSelector(@selector(incomingPresentAtEventListUpdates:))
                                  forKey:FZZ_INCOMING_PRESENT_AT_EVENT_LIST_UPDATES];
        
    }
    
    return self;
}

/* Check for a network connection. Attempt to connect to network with increasing time intervals. */
+ (void) openConnectionCheckingForInternet{
    FZZ_Reachability *reachability = [FZZ_Reachability reachabilityForInternetConnection];
    
    if ([reachability isReachable]){
        NSLog(@"isReachable");
        
        [delegate openConnection];
    } else {
        NSLog(@"is NOT reachable");
        
        [delegate performSelector:@selector(openConnectionCheckingForInternet) withObject:nil afterDelay:reconnectDelay];
        
        [delegate updateReconnectDelay];
    }
}

/* AJAX */

- (BOOL)ajaxPostRequest{
    NSLog(@"AJAX REQUEST");
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    appDelegate.isConnecting = YES;
    
    NSString *fbToken = [FBSession activeSession].accessTokenData.accessToken;
//    NSString *phoneNumber = [appDelegate userPhoneNumber]; //("+" followed by just digits)
    
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSString *iosToken = [pref objectForKey:@"iosToken"];
    
    NSString *phoneNumber = [pref objectForKey:@"phoneNumber"];
    
//    appDelegate.userPhoneNumber = NULL;
    
    if (fbToken){
        
        NSLog(@"sending AJAX");
        
        // FB Session Token
        NSMutableArray *keys = [[NSMutableArray alloc] initWithObjects:@"fbToken", nil];
        NSMutableArray *objects = [[NSMutableArray alloc] initWithObjects:fbToken, nil];
        
        NSLog(@"fbToken: %@", fbToken);
        
        // Phone Number
        if (phoneNumber != NULL){
            [keys addObject:@"pn"];
            [objects addObject:phoneNumber];
            
            NSLog(@"pn: %@", phoneNumber);
        }
        
        // iOS Token
        if (iosToken != NULL){
            [keys addObject:@"iosToken"];
            [objects addObject:iosToken];
            
            NSLog(@"iosToken: %@", iosToken);
        }
        
        // Version Number
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *version = [info objectForKey:@"CFBundleShortVersionString"];
        
        [keys addObject:@"version"];
        [objects addObject:version];
        
        NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

        SBJson4Writer *writer = [[SBJson4Writer alloc] init];
        
        NSString *jsonString = [writer stringWithObject:jsonDictionary];
        
        NSLog(@"\n\n%@\n\n", jsonString);
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d/iosLogin", kFZZSocketHost, kFZZSocketPort]]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:jsonData];
        
        connection = [[NSURLConnection alloc]
                      initWithRequest:request
                      delegate:delegate
                      startImmediately:NO];
        
        /*[connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                              forMode:NSDefaultRunLoopMode];*/
        
        [connection start];
        appDelegate.hasLoggedIn = YES;
        
        return YES;
    }
    
    return NO;
}

+ (SocketIO *)socketIO{
    return socketIO;
}

//+ (void)logout{
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    
//    NSString *url = [NSString stringWithFormat:@"http://%@:%d/logout", kFZZSocketHost, kFZZSocketPort];
//    
//    [request setHTTPMethod:@"GET"];
//    [request setURL:[NSURL URLWithString:url]];
//    
//    NSError *error = [[NSError alloc] init];
//    NSHTTPURLResponse *responseCode = nil;
//    
//    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
//    
//    if([responseCode statusCode] != 200){
//        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
//        return;
//    }
//    
//    didAjax = NO;
//    NSLog(@"Logged out");
//    
//    
//    NSLog(@"%@",[[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding]);
//}

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten
{
    NSLog(@"didwriteData push");
}
- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    NSLog(@"connectionDidResumeDownloading push");
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
{
    NSLog(@"didfinish push @push %@",data);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    NSLog(@"did send body");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [data setLength:0];
    NSHTTPURLResponse *resp= (NSHTTPURLResponse *) response;
    NSLog(@"got response with status @push %d",[resp statusCode]);
    
    if ([resp statusCode] == 200){
        didAjax = YES;
        [FZZSocketIODelegate openConnectionCheckingForInternet];
    } else {
        // AJAX failed
        
        FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
        
        [appDelegate promptForNewFacebookToken];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
    [data appendData:d];
    
    NSLog(@"recieved data @push %@", data);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"didfinishLoading%@",responseText);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error ", @"")
                                message:[error localizedDescription]
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                      otherButtonTitles:nil] show];
    NSLog(@"failed &push");
}

// Handle basic authentication challenge if needed
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"credentials requested");
    NSString *username = @"username";
    NSString *password = @"password";
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}


- (void) openConnection{
    resignedActive = NO;
    
    if (didAjax){
        [socketIO connectToHost:kFZZSocketHost onPort:kFZZSocketPort];
    } else {
        if (![delegate ajaxPostRequest]){
            // Get the fb token and post an AJAX Request Again
        }
    }
}

/* Connect */

- (void) socketIODidConnect:(SocketIO *)socket{
    connected = YES;
    NSLog(@"\n[socketIO] Connection Opened\n");
    reconnectDelay = kFZZDefaultReconnectDelay;
}

/* Disconnect */

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
    connected = NO;
    NSLog(@"\n[socketIO] Connection Disconnected\n");
    if (!resignedActive){ NSLog(@"\n[socketIO] Attempting to Reconnect\n");
        [delegate performSelector:@selector(reconnect) withObject:nil afterDelay:reconnectDelay];
    }
}

- (void) updateReconnectDelay{
    // Ramp up how often you try to reconnect from every 5 seconds to every 5 minutes
    if (reconnectDelay < kFZZMaximumReconnectDelay){
        reconnectDelay += ((reconnectDelay / 20) + 1) * 5;
        
        reconnectDelay = MIN(reconnectDelay, kFZZMaximumReconnectDelay);
    }
}

- (void) reconnect{
    [socketIO disconnect];
    [FZZSocketIODelegate openConnectionCheckingForInternet];
    NSLog(@"OPENCONN 2");
}

+ (void) willResignActive{
    resignedActive = YES;
    
    if (connected){
        [socketIO disconnect];
        connected = NO;
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:delegate];
        reconnectDelay = kFZZDefaultReconnectDelay;
    }
}

/* Recieve */

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet{
    NSLog(@"Message recieved: %@", packet.data);
}

// All messages recieved should be events
- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet{
    NSLog(@"JSON recieved: %@", packet.data);
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet{
    NSLog(@"Event recieved: %@", packet.data);
    
    NSDictionary *event = packet.dataAsJSON;
    
    NSString *eventName = [event objectForKey:@"name"];
    
    NSString *functionName = [incomingEventResponses objectForKey:eventName];
    
    if (functionName != nil){
        NSArray *args = [event objectForKey:@"args"];
        
        SEL function = NSSelectorFromString(functionName);
        
        SuppressPerformSelectorLeakWarning(
            [delegate performSelectorInBackground:function withObject:args];
        );
    }
}

- (void)incomingOnLogin:(NSArray *)args{
    {
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isConnecting = NO;
    }
    
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSDictionary *userJSON = [json objectForKey:@"me"];
    NSArray *friendListJSON = [json objectForKey:@"friendList"];
    NSArray *blackListJSON = [json objectForKey:@"blackList"];
    NSArray *eventListJSON = [json objectForKey:@"eventList"];
    NSString *fbAccessToken = [json objectForKey:@"fbToken"];
    
    // User (me)
    
    FZZUser *me = [FZZUser parseJSON:userJSON];
    
    [FZZUser setMeAs:me];
    
    // User Array (friends)
    NSArray *friends = [FZZUser parseUserJSONFriendList:friendListJSON];
    
    NSArray *blackList = [FZZUser parseUserJSONBlackList:blackListJSON];
    
    [FZZInviteViewController updateFriends];
    
    // Events
    NSArray *events = [FZZEvent parseEventJSONList:eventListJSON];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate updateEvents:events];
//    [appDelegate updateFriendsWithFriendsList:friends AndBlackList:blackList];
    
    // Facebook Access Token
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    [pref setObject:fbAccessToken forKey:@"fbToken"];
    
}

- (void)incomingNewEvent:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSDictionary *eventJSON = [json objectForKey:@"event"];
    
    // Event
    FZZEvent *event = [FZZEvent parseJSON:eventJSON];
    
    NSArray *eventArray = [[NSArray alloc] initWithObjects:event, nil];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate updateEvents:eventArray];
}

- (void)incomingAddGuest:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSNumber *eventID = [json objectForKey:@"eid"];
    NSNumber *userID  = [json objectForKey:@"uid"];
    
    // Event
    FZZEvent *event = [FZZEvent eventWithEID:eventID];
    
    // User (guest)
    FZZUser  *user  = [FZZUser userWithUID:userID];
    
    [event updateAddGuest:user];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.esvc updateEvent:event];
}

- (void)incomingNewFriend:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSDictionary *userJSON = [json objectForKey:@"user"];
    
    // User (new friend)
    
    FZZUser *user = [FZZUser parseJSON:userJSON];
    [FZZUser addFriends:[NSArray arrayWithObject:user]];
}
                                                              
- (void)incomingNewInviteList:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    // Event ID
    NSNumber *eventID = [json objectForKey:@"eid"];
    NSArray *inviteListJSON = [json objectForKey:@"inviteList"];
    
    // Friends
    NSArray *invited = [FZZUser parseUserJSONList:inviteListJSON];
    
    FZZEvent *event = [FZZEvent eventWithEID:eventID];
    
    [event updateInvites:invited];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.esvc updateEvent:event];
}
                                                              
- (void)incomingSetSeatCapacity:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    // Event ID
    NSNumber *eventID = [json objectForKey:@"eid"];
    
    // Num Seats
    NSNumber *numSeats = [json objectForKey:@"seats"];
    
    FZZEvent *event = [FZZEvent eventWithEID:eventID];
    
    [event updateNumberOfSeats:numSeats];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [appDelegate.esvc updateEvent:event];
}

- (void)incomingPresentAtEventListUpdates:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    // Event ID
    NSNumber *eventID = [json objectForKey:@"eid"];
    
    // List of Users who have just arrived at the event
    NSArray *arrivingList = [json objectForKey:@"arrivingList"];
    
    // List of Users who have just left from the event
    NSArray *leavingList = [json objectForKey:@"leavingList"];
    
    // Event
    FZZEvent *event = [FZZEvent eventWithEID:eventID];
    
    [event updateAddAtEvent:arrivingList];
    [event updateRemoveAtEvent:leavingList];
}

- (void)incomingRemoveGuest:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSNumber *eventID = [json objectForKey:@"eid"];
    NSNumber *userID  = [json objectForKey:@"uid"];
    
    // Event
    FZZEvent *event = [FZZEvent eventWithEID:eventID];
    
    // User to remove
    FZZUser  *user  = [FZZUser userWithUID:userID];
    
    [event updateRemoveGuest:user];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.esvc updateEvent:event];
}

- (void)incomingNewMessage:(NSArray *)args{
    NSDictionary *json  = [args objectAtIndex:0];
    
    NSDictionary *messageJSON = [json objectForKey:@"message"];
    
    // New Message
    FZZMessage *message = [FZZMessage parseJSON:messageJSON];
    
    [[message event] updateAddMessage:message];
    
    FZZAppDelegate *appDelegate = (FZZAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [appDelegate.esvc addIncomingMessageForEvent:[message event]];
}

//- (void)incomingNewUserLocationList:(NSArray *)args{
//    NSDictionary *json  = [args objectAtIndex:0];
//    
//    NSDictionary *userLocationJSON = [json objectForKey:@"userLocation"];
//    
//    NSNumber *uid = [userLocationJSON objectForKey:@"uid"];
//    
//    FZZUser *user = [FZZUser userWithUID:uid];
//    
//    NSDictionary *latlngJSON = [userLocationJSON objectForKey:@"latlng"];
//    
//    FZZCoordinate *coord = [FZZCoordinate parseJSON:latlngJSON];
//}


/* Send */

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet{
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
    NSLog(@"\n[socketIO] Error: %@\n", error);
}

+ (BOOL) isConnectionOpen{
    return connected;
}


@end
