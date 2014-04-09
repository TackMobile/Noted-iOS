//
//  NTDThemesTableViewController.m
//  Noted
//
//  Created by Tack Workspace on 4/2/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDThemesTableViewController.h"
#import <UIView+FrameAdditions.h>

#pragma mark - NTDThemePreview

@implementation NTDThemePreview

- (id) initWithTheme:(NTDTheme *)theme {
    self = [super init];
    if (self) {
        self.theme = theme;
        for (int i=0; i<NTDNumberOfColorSchemes; i++) {
            UIView *theView = [UIView new];
            theme.colorScheme = i;
            theView.backgroundColor = self.theme.backgroundColor;
            [self addSubview:theView];
        }
    }
    return self;
}

- (void)layoutSubviews {
    float colorHeight = (self.frame.size.height - (NTDNumberOfColorSchemes-1))/NTDNumberOfColorSchemes;
    for (int i=0; i<[[self subviews] count]; i++) {
        CGRect colorFrame = {
            .origin.x = 0,
            .origin.y = colorHeight*i + i,
            .size.height = colorHeight,
            .size.width = self.frame.size.width
        };
        UIView *theColor = [[self subviews] objectAtIndex:i];
        [theColor setFrame:colorFrame];
    }
}

@end

#pragma mark - NTDThemeTableViewController

@interface NTDThemesTableViewController ()
@property (nonatomic) NSInteger selectedThemeIndex;
@end

@implementation NTDThemesTableViewController

static NSString * const ThemeCellReuseIdentifier = @"ThemeCell";
static const int HeaderHeight = 40;
static const int RowHeight = 60;

#pragma mark - View Lifecycle
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ThemeCellReuseIdentifier];
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    
    // TESTING
    self.selectedThemeIndex = 3;
    
}

#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    [self configureCell:cell indexPath:indexPath];
    return cell;
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // configure the theme's color box
    NTDThemePreview *themePreview = [[NTDThemePreview alloc] initWithTheme:[NTDTheme themeForColorScheme:0]];
    themePreview.frame = CGRectMake(15, 10, 40, 40);
    
    // configure the theme's title
    UILabel *themeTitle = [[UILabel alloc] initWithFrame:CGRectMake(65, 10, cell.frame.size.width-60, 40)];
    themeTitle.textColor = [UIColor whiteColor];
    themeTitle.font = [UIFont fontWithName:@"Avenir-Light" size:16];
    themeTitle.text = [NSString stringWithFormat:@"Theme title %ld", indexPath.item];
    
    // decide if the theme is currently active
    if (indexPath.item == self.selectedThemeIndex) {
        cell.backgroundColor = [UIColor darkGrayColor];
        themeTitle.font = [UIFont fontWithName:@"Avenir" size:16];
    }
    
    // add in the subviews
    [cell.contentView addSubview:themePreview];
    [cell.contentView addSubview:themeTitle];
    
    return cell;
}

#pragma mark - TableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1/[[UIScreen mainScreen] scale]; // used for small border at bottom of tableview
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor blackColor];
    
    // configure the 1px seperator that belongs under the header view
    CGRect seperatorFrame = {
        .origin.y = HeaderHeight,
        .size.width = self.view.frame.size.width,
        .size.height = 1/[[UIScreen mainScreen] scale]
    };
    UIView *seperatorView = [[UIView alloc] initWithFrame:seperatorFrame];
    seperatorView.backgroundColor = [UIColor darkGrayColor];
    
    // configure the header's text
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"Avenir-Light" size:16];
    headerLabel.text = @"Themes";
    headerLabel.alpha = .7;
    headerLabel.$size =  [headerLabel.text sizeWithFont:headerLabel.font];
    headerLabel.$x = 15;
    headerLabel.$y = 9;
    
    // add the seperator and label to the header
    [headerView addSubview:seperatorView];
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor darkGrayColor];
    return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedThemeIndex = indexPath.item;
    [self.tableView reloadData];
}

@end