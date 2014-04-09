//
//  NTDThemesTableViewController.h
//  Noted
//
//  Created by Tack Workspace on 4/2/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDTheme.h"

@interface NTDThemePreview : UIView

@property (nonatomic) NSInteger theme;

- (id) initWithThemeName:(NSInteger)themeName;

@end

@interface NTDThemesTableViewController : UITableViewController

//@property (nonatomic, strong) activeTheme

@end