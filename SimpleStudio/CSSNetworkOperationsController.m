//
//  CSSNetworkOperationsController.m
//  SimpleStudio
//
//  Created by centurion on 4/11/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSSNetworkOperationsController.h"

@interface CSSNetworkOperationsController ()

// read/write redeclaration of public read-only property

@property (nonatomic, assign, readwrite) NSUInteger     networkOperationCount;

@end

@implementation CSSNetworkOperationsController

+ (CSSNetworkOperationsController *)sharedInstance
{
   static dispatch_once_t  onceToken;
   static CSSNetworkOperationsController * sSharedInstance;
   
   dispatch_once(&onceToken, ^{
      sSharedInstance = [[CSSNetworkOperationsController alloc] init];
   });
   return sSharedInstance;
}

- (NSURL *)smartURLForString:(NSString *)str
{
   NSURL *     result;
   NSString *  trimmedStr;
   NSRange     schemeMarkerRange;
   NSString *  scheme;
   
   assert(str != nil);
   
   result = nil;
   
   trimmedStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   if ( (trimmedStr != nil) && ([trimmedStr length] != 0) ) {
      schemeMarkerRange = [trimmedStr rangeOfString:@"://"];
      
      if (schemeMarkerRange.location == NSNotFound) {
         result = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://%@", trimmedStr]];
      } else {
         scheme = [trimmedStr substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
         assert(scheme != nil);
         
         if ( ([scheme compare:@"ftp"  options:NSCaseInsensitiveSearch] == NSOrderedSame) ) {
            result = [NSURL URLWithString:trimmedStr];
         } else {
            // It looks like this is some unsupported URL scheme.
         }
      }
   }
   
   return result;
}

- (void)didStartNetworkOperation
{
   // If you start a network operation off the main thread, you'll have to update this code
   // to ensure that any observers of this property are thread safe.
 //  assert([NSThread isMainThread]);
   NSLog(@"NetworkManager::DidStaryNetworkOperation");
   self.networkOperationCount += 1;
}

- (void)didStopNetworkOperation
{
   // If you stop a network operation off the main thread, you'll have to update this code
   // to ensure that any observers of this property are thread safe.
   //assert([NSThread isMainThread]);
   NSLog(@"NetworkManager::DidStaryNetworkOperation");
   assert(self.networkOperationCount > 0);
   self.networkOperationCount -= 1;
}





@end
