//
//  CSFtpController.h
//  SimpleStudio
//
//  Created by centurion on 4/11/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTPManager.h"
#import "ControlView.h"
@interface CSFtpController : NSObject
{
   NSURL* fileURL;
   
   BOOL success;
   BOOL aborted;

}

@property FTPManager *man;
// Properties that don't need to be seen by the outside world.
-(void)uploadFinished;
-(void)startUploading;
-(void)upload:(NSString*)file ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass;

@end

