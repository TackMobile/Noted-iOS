//
//  StackViewItem.m
//  Noted
//
//  Created by Ben Pilcher on 11/23/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "StackViewItem.h"
#import "NoteEntryCell.h"
#import "UIColor+Utils.h"
#import "NoteViewController.h"
#import "AnimationStackViewController.h"

#define FULL_TEXT_TAG       190

@implementation StackViewItem

- (id)initWithIndexPath:(NSIndexPath *)anIndexPath
{
    if (self = [super init]) {
        _indexPath = anIndexPath;
        _offsetFromActive = 0;
        _startingFrame = CGRectZero;
        _destinationFrame = CGRectZero;
    }
    
    return self;
}

- (void)setNoteEntry:(NoteEntry *)noteEntry
{
    if (!noteEntry || noteEntry == (id)[NSNull null]) {
        _isNoteEntry = NO;
        _isSectionZeroRowOne = YES;
        return;
    }
    
    if (_noteEntry != noteEntry && noteEntry) {
        _noteEntry = noteEntry;
        _isNoteEntry = YES;
        
    }
    
    [self updateForEntry];
}

- (void)updateForEntry
{
    if (!_cell || ![_cell isKindOfClass:[NoteEntryCell class]]) {
        return;
    }
    
    NoteEntryCell *noteEntryCell = (NoteEntryCell *)_cell;
    
    UIColor *bgColor = _noteEntry.noteColor ? _noteEntry.noteColor : [UIColor whiteColor];
    int index = [[UIColor getNoteColorSchemes] indexOfObject:bgColor];
    if (index==NSNotFound) {
        index = 0;
    }
    if (index >= 4) {
        [noteEntryCell.subtitleLabel setTextColor:[UIColor whiteColor]];
        [noteEntryCell.relativeTimeText setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    } else {
        [noteEntryCell.subtitleLabel setTextColor:[UIColor colorWithHexString:@"333333"]];
        [noteEntryCell.relativeTimeText setTextColor:[UIColor colorWithWhite:0.2 alpha:0.5]];
    }
    
    noteEntryCell.contentView.backgroundColor = _noteEntry.noteColor ? _noteEntry.noteColor : [UIColor whiteColor];
    [noteEntryCell.subtitleLabel setText:_noteEntry.title];
    //UITextView *fullText = (UITextView *)[noteEntryCell.contentView viewWithTag:FULL_TEXT_TAG];
    //if (fullText) {
      //  fullText.text = _noteEntry.text;
        //[fullText setFrame:CGRectMake(6, 27, 308, fullText.frame.size.height)];
    //}
    noteEntryCell.relativeTimeText.text = [_noteEntry relativeDateString];
    
    UILabel *circle = (UILabel *)[noteEntryCell viewWithTag:78];
    
    circle.textColor = noteEntryCell.subtitleLabel.textColor;
    circle.text = [NoteViewController optionsDotTextForColor:_noteEntry.noteColor];
    circle.font = [NoteViewController optionsDotFontForColor:_noteEntry.noteColor];
}

- (NSString *)description
{
    NSString *desc = @"";
    desc = [desc stringByAppendingFormat:@"\n\nis first: %s\n",_isFirst ? "YES" : "NO"];
    desc = [desc stringByAppendingFormat:@"is last: %s\n",_isLast ? "YES" : "NO"];
    desc = [desc stringByAppendingFormat:@"is active: %s\n",_isActive ? "YES" : "NO"];
    desc = [desc stringByAppendingFormat:@"indexPath %@\n",_indexPath];
    desc = [desc stringByAppendingFormat:@"index %i\n",_index];
    desc = [desc stringByAppendingFormat:@"offset %i\n",_offsetFromActive];
    desc = [desc stringByAppendingFormat:@"start frame %@",NSStringFromCGRect(_startingFrame)];
    desc = [desc stringByAppendingFormat:@"dest frame %@",NSStringFromCGRect(_destinationFrame)];
    
    return desc;
}

@end
