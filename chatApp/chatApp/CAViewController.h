//
//  CAViewController.h
//  chatApp
//
//  Created by Niall Quinn on 30/08/2014.
//  Copyright (c) 2014 Niall Quinn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CAViewController : UIViewController <NSStreamDelegate, UITableViewDelegate, UITableViewDataSource> {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    IBOutlet UIView *joinView;
    IBOutlet UITextField *inputNameField;
    IBOutlet UIButton *joinButton;
    
    IBOutlet UIView *chatView;
    IBOutlet UIButton *sendButton;
    IBOutlet UITextField *chatTextField;
    IBOutlet UIView *chatsView;
    
    IBOutlet UITableView *tView;
    
    NSMutableArray * messages;
    
}

@end
