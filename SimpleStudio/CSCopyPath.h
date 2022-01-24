//
//  CSCopyPath.h
//  SimpleStudio
//
//  Created by centurion on 4/6/15.
//  Copyright (c) 2015 centurion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSCopyPath : NSObject

enum copyOperations
{
   cp_USB = 1,
   cp_FTP = 2,
};

@property NSString *srcPath;
@property NSString *dstPath;
@property int type;
@property long long srcSize;

- (id) initWithParams:(NSString*)aSrcPath :(NSString*)aDstPath :(int)aType;
@end
