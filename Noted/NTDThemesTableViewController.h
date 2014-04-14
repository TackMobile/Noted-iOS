//
//  NTDThemesTableViewController.h
//  Noted
//
//  Created by Tack Workspace on 4/2/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTDTheme.h"

@protocol NTDThemesTableViewControllerDelegate <NSObject>

- (void) dismissThemesTableView;

@end

@interface NTDThemePreview : UIView

@property (nonatomic) NSInteger theme;

- (id) initWithThemeName:(NSInteger)themeName;

@end

@interface NTDThemesTableViewController : UITableViewController
@property (nonatomic, strong) id<NTDThemesTableViewControllerDelegate> delegate;

-(void)dismissModalIfShowing;

//@property (nonatomic, strong) activeTheme

@end