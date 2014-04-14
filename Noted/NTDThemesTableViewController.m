//
//  NTDThemesTableViewController.m
//  Noted
//
//  Created by Tack Workspace on 4/2/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDThemesTableViewController.h"
#import "NTDModalView.h"
#import <UIView+FrameAdditions.h>

#pragma mark - NTDThemePreview

@implementation NTDThemePreview

- (id) initWithThemeName:(NSInteger)themeName {
    self = [super init];
    if (self) {
        self.theme = themeName;
        for (int i=0; i<NTDNumberOfColorSchemes; i++) {
            UIView *theView = [UIView new];
            theView.backgroundColor = [NTDTheme backgroundColorForThemeName:themeName colorScheme:i];
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
@property (nonatomic, strong) __block NTDModalView *modalView;
@end

@implementation NTDThemesTableViewController

static NSString * const NTDThemeCellReuseIdentifier = @"ThemeCell";
static NSString * const NTDDidPurchaseThemesKey = @"DidPurchaseThemes";
static NSArray *themeNames;
static const int HeaderHeight = 38;
static const int RowHeight = 60;

#pragma mark - View Lifecycle
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NTDThemeCellReuseIdentifier];
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        themeNames = [NTDTheme themeNames];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.selectedThemeIndex = [NTDTheme activeThemeIndex];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.userInteractionEnabled = NO;
    if ([self didPurchaseThemes]) {
        self.tableView.userInteractionEnabled = YES;
    } else {
        NSString *msg = @"Get more themes for your notes to customize Noted.";
        self.modalView = [[NTDModalView alloc] initWithMessage:msg layer:nil backgroundColor:[UIColor blackColor] buttons:@[@"Purchase", @"Restore"] dismissalHandler:^(NSUInteger index) {
            if (index == 1) {
                if ([self.delegate respondsToSelector:@selector(dismissThemesTableView)])
                    [self.delegate dismissThemesTableView];
            }
            [self.modalView dismiss];
            self.tableView.userInteractionEnabled = YES;
            
        }];
        UIEdgeInsets modalInsets = UIEdgeInsetsMake(0, 0, 65, 35);
        [self.modalView showWithEdgeInsets:modalInsets];
        
        CGRect modalBorderRect = CGRectInset(self.modalView.bounds, -1, -1);
        UIView *modalBorder = [[UIView alloc] initWithFrame:modalBorderRect];
        modalBorder.backgroundColor = [UIColor darkGrayColor];
        [self.modalView insertSubview:modalBorder atIndex:0];
    }
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
    return NTDNumberOfThemes;
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
    NTDThemePreview *themePreview = [[NTDThemePreview alloc] initWithThemeName:indexPath.item];
    themePreview.frame = CGRectMake(15, 10, 40, 40);
    
    // configure the theme's title
    UILabel *themeTitle = [[UILabel alloc] initWithFrame:CGRectMake(65, 10, cell.frame.size.width-60, 40)];
    themeTitle.textColor = [UIColor whiteColor];
    themeTitle.font = [UIFont fontWithName:@"Avenir-Light" size:16];
    themeTitle.text = [themeNames objectAtIndex:indexPath.item];
    
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
    [NTDTheme setThemeToActive:indexPath.item];
    [self.tableView reloadData];
}

- (BOOL)didPurchaseThemes {
    if ([[NSUserDefaults standardUserDefaults] valueForKey:NTDDidPurchaseThemesKey]) {
        return [[[NSUserDefaults standardUserDefaults] valueForKey:NTDDidPurchaseThemesKey] boolValue];
    }
    return NO;
}

- (void)dismissModalIfShowing {
    if (self.modalView != nil)
        [self.modalView dismiss];
}

@end