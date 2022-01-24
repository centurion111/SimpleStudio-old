//
//  LicensingController.h
//  SimpleStudio
//
//  Created by centurion on 2/20/17.
//  Copyright © 2017 centurion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LicensingController : NSWindowController
-(IBAction)actionBuyLicense:(id)sender;
-(IBAction)ActionEnterSerial:(id)sender;
-(IBAction)ActionCancel:(id)sender;

@property (strong) IBOutlet NSImageView * picView;
@property (strong) IBOutlet NSButton * activateButton;
@property (strong) IBOutlet NSTextField * numberField;
@property (strong) IBOutlet NSTextField * numberLabel;

@end
