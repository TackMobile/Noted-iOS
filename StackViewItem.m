//
//  StackViewItem.m
//  Noted
//
//  Created by Ben Pilcher on 11/23/12.
//  Copyright (c) 2012 Tack Mobile. All rights reserved.
//

#import "StackViewItem.h"
#import "NoteEntryCell.h"
#import "UIColor+HexColor.h"
#import "NoteViewController.h"

#define FULL_TEXT_TAG       190

@implementation StackViewItem

- (id)initWithIndexPath:(NSIndexPath *)anIndexPath
{
    if (self = [super init]) {
        _indexPath = anIndexPath;
        _offsetFromActive = 0;
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
        [self updateForEntry];
    }
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
    } else {
        [noteEntryCell.subtitleLabel setTextColor:[UIColor colorWithHexString:@"AAAAAA"]];
    }
    
    noteEntryCell.relativeTimeText.textColor = noteEntryCell.subtitleLabel.textColor;
    
    noteEntryCell.contentView.backgroundColor = _noteEntry.noteColor ? _noteEntry.noteColor : [UIColor whiteColor];
    [noteEntryCell.subtitleLabel setText:_noteEntry.title];
    UITextView *fullText = (UITextView *)[noteEntryCell.contentView viewWithTag:FULL_TEXT_TAG];
    if (fullText) {
        fullText.text = _noteEntry.text;
    }
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
    desc = [desc stringByAppendingFormat:@"offset %i\n\n",_offsetFromActive];
    desc = [desc stringByAppendingFormat:@"dest frame %@\n\n",NSStringFromCGRect(_destinationFrame)];
    
    return desc;
}

@end
