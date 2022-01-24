//
//  CSCopyPath.m
//  SimpleStudio
//
//  Created by centurion on 4/6/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import "CSCopyPath.h"

@implementation CSCopyPath

@synthesize srcPath;
@synthesize dstPath;
@synthesize srcSize;
@synthesize type;

- (id) initWithParams:(NSString*)aSrcPath :(NSString*)aDstPath :(int)aType
{
   if(![super init])
      {
      NSLog(@"CSCopyPath::init init failed");
      return nil;
      }
   srcPath = aSrcPath;
   dstPath = aDstPath;
   type = aType;
   return self;
}

@end
