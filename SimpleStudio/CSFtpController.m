//
//  CSFtpController.m
//  SimpleStudio
//
//  Created by centurion on 4/11/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSFtpController.h"

#import <CFNetwork/CFNetwork.h>
#import "CSSNetworkOperationsController.h"
#import "CStatusManager.h"

@implementation CSFtpController
@synthesize man;


FMServer* server;
NSString* filePath;
BOOL succeeded;


-(id)init
{
   if (![super init])
      {
      return nil;
      }
   man = [[FTPManager alloc] init];
   return self;
}

-(void)uploadFinished {
   NSLog(@"CSFTPController::UploadFinished");
   [[NSNotificationCenter defaultCenter] postNotificationName:@"ftpUploadFinished" object:self];
   filePath = nil;
   server = nil;
   
   //test whether succeeded == YES
}


-(void) test : (NSTimer*)timer
{
   NSLog(@"test");
}

-(void)startUploading {

   succeeded = [man uploadFile:[NSURL URLWithString:filePath] toServer:server];
   NSLog(@"CSFTPController::StartUploading succeeded = %d",succeeded);
}

-(void)upload:(NSString*)file ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass {
   NSLog(@"CSFTPController upload %@, %@, %@, %@",file,url,user,pass);
   server = [FMServer serverWithDestination:url username:user password:pass];
   [server setPort:21];
   filePath = file;
   succeeded = [man uploadFile:[NSURL URLWithString:filePath] toServer:server];
   [self performSelectorOnMainThread:@selector(uploadFinished) withObject:nil waitUntilDone:YES];

}

@end
