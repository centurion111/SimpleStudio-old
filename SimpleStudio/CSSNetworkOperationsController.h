//
//  CSSNetworkOperationsController.h
//  SimpleStudio
//
//  Created by centurion on 4/11/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSNetworkOperationsController : NSObject
+ (CSSNetworkOperationsController *)sharedInstance;

@property (nonatomic, assign, readonly ) NSUInteger     networkOperationCount;  // observable
- (NSURL *)smartURLForString:(NSString *)str;

- (void)didStartNetworkOperation;
- (void)didStopNetworkOperation;

@end
