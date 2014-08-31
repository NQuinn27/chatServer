//
//  CAViewController.m
//  chatApp
//
//  Created by Niall Quinn on 30/08/2014.
//  Copyright (c) 2014 Niall Quinn. All rights reserved.
//

#import "CAViewController.h"

/*Set the IP Address of the ROUTER here to use on device
 It will work between different devices on the same network
 change to localhost to use the simulator on machine only
 */
#define CURRENT_ROUTER_IP @"192.168.1.105"

@interface CAViewController () {
    NSString *userName;
    BOOL currentUser;
    NSIndexPath *editingIndexPath;
}

@end

@implementation CAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupToJoin];
    [self initNetworkCommunication];
    messages = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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
    //Set up the streams
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    //Pair stream with socket to host
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)CURRENT_ROUTER_IP, 90, &readStream, &writeStream);
    
    //Cast the streams to the instance variables
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    //Setup self as the delegate
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    //Put the streams into the run loop for listening
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    //Open the streams
    [inputStream open];
    [outputStream open];
}

- (IBAction)joinChat:(id)sender {
    
    //Join the chat as a new user
    //TODO - check if username is taken
    
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
    
    //Send message over the output stream
    NSString *response  = [NSString stringWithFormat:@"msg:%@", chatTextField.text];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
    [chatTextField setText:@""];
}

- (void) messageReceived:(NSString *)message {
    //Message recieved on the input stream
    
    NSArray *lines = [message componentsSeparatedByString: @":"];
    NSMutableString *result = [[NSMutableString alloc] init];
    if ([lines[0] isEqualToString:userName]) {
        //Its me
        [result appendString:@"user:"];
    }
    [result appendString:message];
    [messages addObject:result];
    [tView reloadData];
    
    editingIndexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
    
    [tView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - UITableViewDelegate

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
    } else {
        [cell setBackgroundColor:[UIColor blueColor]];
        [cell.textLabel setTextColor:[UIColor whiteColor]];
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

#pragma mark - Stream Delegate

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

#pragma mark - KeyboardWillShow - KeyboardWillHide

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    tView.contentInset = contentInsets;
    tView.scrollIndicatorInsets = contentInsets;
    [tView scrollToRowAtIndexPath:editingIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    tView.contentInset = UIEdgeInsetsZero;
    tView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

@end
