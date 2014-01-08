//
//  NTDCollectionViewController+ShakeToUndoDelete.m
//  Noted
//
//  Created by Nick Place on 1/8/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDCollectionViewController+ShakeToUndoDelete.h"
#import "NTDNote.h"

@implementation NTDCollectionViewController (ShakeToUndoDelete)

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
    }
}


-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
        [NTDNote newNoteWithText:@"This is a new note." theme:[NTDTheme themeForColorScheme:NTDColorSchemeTack] completionHandler:^(NTDNote *note) {
            [note setLastModifiedDate:[NSDate dateWithTimeIntervalSinceNow:-2*24*60*60]];
            [self reloadNotes];
        }];
        
        NSLog(@"undo");
    }
}

@end
