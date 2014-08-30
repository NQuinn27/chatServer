//
//  CAViewController.m
//  chatApp
//
//  Created by Niall Quinn on 30/08/2014.
//  Copyright (c) 2014 Niall Quinn. All rights reserved.
//

#import "CAViewController.h"

@interface CAViewController () {
    NSString *userName;
    BOOL currentUser;
}

@end

@implementation CAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupToJoin];
    [self initNetworkCommunication];
    messages = [[NSMutableArray alloc] init];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupToJoin {
    [chatsView setHidden:YES];
    [sendButton setHidden:YES];
    [chatTextField setHidden:YES];
}

- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", 80, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

- (IBAction)joinChat:(id)sender {
    
    userName = inputNameField.text;
    
	NSString *response  = [NSString stringWithFormat:@"iam:%@", inputNameField.text];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
    
    [chatTextField setHidden:NO];
    [sendButton setHidden:NO];
    [chatsView setHidden:NO];
    
    [joinButton setHidden:YES];
    [inputNameField setHidden:YES];
    
}

- (IBAction)sendMessage:(id)sender {
    NSString *response  = [NSString stringWithFormat:@"msg:%@", chatTextField.text];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
    [chatTextField setText:@""];
}

- (void) messageReceived:(NSString *)message {
    
    NSArray *lines = [message componentsSeparatedByString: @":"];
    NSMutableString *result = [[NSMutableString alloc] init];
    if ([lines[0] isEqualToString:userName]) {
        //Its me
        [result appendString:@"user:"];
    }
    [result appendString:message];
    [messages addObject:result];
    [tView reloadData];
    
    NSIndexPath *topIndexPath =
    [NSIndexPath indexPathForRow:messages.count-1
                       inSection:0];
    [tView scrollToRowAtIndexPath:topIndexPath
                      atScrollPosition:UITableViewScrollPositionMiddle
                              animated:YES];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"ChatCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *s = (NSString *) [messages objectAtIndex:indexPath.row];
    
    if ([[s substringWithRange:NSMakeRange(0, 5)] isEqualToString:@"user:"]) {
        [cell.textLabel setTextAlignment:NSTextAlignmentRight];
        [cell setBackgroundColor:[UIColor greenColor]];
        s = [s substringFromIndex:5];
    }
    
    cell.textLabel.text = s;
    
    return cell;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return messages.count;
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            [self messageReceived:output];
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        default:
            NSLog(@"Unknown event");
    }
    
}



@end
