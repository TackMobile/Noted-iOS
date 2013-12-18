//
//  NTDDropboxNote.h
//  Noted
//
//  Created by Vladimir Fleurima on 12/18/13.
//  Copyright (c) 2013 Tack Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTDNote, DBFile;
@interface NTDDropboxNote : NSObject

-(void)copyFromNote:(NTDNote *)note file:(DBFile *)file;

@end
