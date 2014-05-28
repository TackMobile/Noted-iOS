//
//  NTDThemesTableViewController.m
//  Noted
//
//  Created by Tack Workspace on 4/2/14.
//  Copyright (c) 2014 Tack Mobile. All rights reserved.
//

#import "NTDThemesTableViewController.h"
#import "NTDModalView.h"
#import "NTDTheme.h"
#import <UIView+FrameAdditions.h>
#import <IAPHelper/IAPShare.h>

#pragma mark - NTDThemePreview

@implementation NTDThemePreview

- (id) initWithThemeName:(NSInteger)themeName {
    self = [super init];
    if (self) {
        [self setThemeName:themeName];
    }
    return self;
}

- (void) setThemeName:(NSInteger)themeName {
    for (UIView *view in self.subviews)
        [view removeFromSuperview];
    
    self.backgroundColor = [UIColor clearColor];
    self.theme = themeName;
    for (int i=0; i<NTDNumberOfColorSchemes; i++) {
        UIView *theView = [UIView new];
        theView.backgroundColor = [NTDTheme backgroundColorForThemeName:themeName colorScheme:i];
        [self addSubview:theView];
    }
    [self layoutIfNeeded];

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
}

- (void)viewWillAppear:(BOOL)animated {
    self.selectedThemeIndex = [NTDTheme activeThemeIndex];
    [super viewWillAppear:animated];
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
    if ([NTDTheme didPurchaseThemes]) {
        self.selectedThemeIndex = indexPath.item;
        [NTDTheme setThemeToActive:indexPath.item];
        [self.tableView reloadData];
    } else {
        [self promptToPurchaseThemes];
    }
}

#pragma mark - User flow

- (void) promptToPurchaseThemes {
    
    NSString *msg = @"Get more themes for your notes to customize Noted.";
    self.modalView = [[NTDModalView alloc]
                      initWithMessage:msg
                      layer:nil
                      backgroundColor:[UIColor blackColor]
                      buttons:@[@"$0.99"]
                      dismissalHandler:^(NSUInteger index) {
                          switch (index) {
                              case 0:
                                  [self purchaseThemesButtonPressed];
                                  break;
                              default:
                                  break;
                          }
                      }];
    
    UIEdgeInsets modalInsets = UIEdgeInsetsMake(0, 0, 65, 35);
    [self.modalView showWithEdgeInsets:modalInsets];
    [self addBorderToActiveModal];
}

- (void) purchaseThemesButtonPressed {
    [self showWaitingModal];
    
    //initate the purchase request
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
         if(response > 0 ) {
             // purchase themes
             SKProduct* product =[[IAPShare sharedHelper].iap.products objectAtIndex:1];
             
             IAPbuyProductCompleteResponseBlock buyProductCompleteResponceBlock = ^(SKPaymentTransaction* transaction){
                 if (transaction.error) {
                     NSLog(@"Failed to complete purchase: %@", [transaction.error localizedDescription]);
                     [self purchaseThemesFailure];
                 } else {
                     switch (transaction.transactionState) {
                         case SKPaymentTransactionStatePurchased:
                         {
                             // check the receipt
                             [[IAPShare sharedHelper].iap checkReceipt:transaction.transactionReceipt
                                                       AndSharedSecret:@"TackSecret"
                                                          onCompletion:^(NSString *response, NSError *error) {
                                                              NSDictionary *reciept = [IAPShare toJSON:response];
                                                              if ([reciept[@"status"] integerValue] == 0) {
                                                                  NSString *pID = transaction.payment.productIdentifier;
                                                                  [[IAPShare sharedHelper].iap provideContent:pID];
                                                                  NSLog(@"Success: %@",response);
                                                                  NSLog(@"Pruchases: %@",[IAPShare sharedHelper].iap.purchasedProducts);
                                                                  [self purchaseThemesSuccess];
                                                              } else {
                                                                  NSLog(@"Reciept Invalid");
                                                                  [self purchaseThemesFailure];
                                                              }
                                                          }];
                             break;
                         }
                             
                         default:
                         {
                             NSLog(@"Purchase Failed");
                             [self purchaseThemesFailure];
                             break;
                         }
                     }
                 }
             };
             
             // attempt to buy the product
             [[IAPShare sharedHelper].iap buyProduct:product
                                        onCompletion:buyProductCompleteResponceBlock];
         }
     }];
}

- (void)purchaseThemesSuccess {
    [self dismissModalIfShowing];
    
    NSString *msg = @"Thanks for purchasing themes. Now check out your new fancy colors...";
    self.modalView = [[NTDModalView alloc]
                      initWithMessage:msg
                      layer:nil
                      backgroundColor:[UIColor blackColor]
                      buttons:@[@"Dismiss"]
                      dismissalHandler:^(NSUInteger index) {
                          [NTDTheme setPurchasedThemes:YES];
                      }];
    
    UIEdgeInsets modalInsets = UIEdgeInsetsMake(0, 0, 65, 35);
    [self.modalView showWithEdgeInsets:modalInsets];
    [self addBorderToActiveModal];

}

- (void)purchaseThemesFailure {
    [self dismissModalIfShowing];
    [self promptToPurchaseThemes];
}

- (void) showWaitingModal {
    // display a "waiting" modal which replaces the old one
    NSString *msg = @"Waiting for response from the App Store";
    self.modalView = [[NTDModalView alloc]
                      initWithMessage:msg
                      layer:nil
                      backgroundColor:[UIColor blackColor]
                      buttons:@[@"..."]
                      dismissalHandler:^(NSUInteger index) {
                          [self showWaitingModal];
                      }];
    
    UIEdgeInsets modalInsets = UIEdgeInsetsMake(0, 0, 65, 35);
    [self.modalView showWithEdgeInsets:modalInsets];
    [self addBorderToActiveModal];
}

- (void)addBorderToActiveModal {
    // add a gray border (special to this view, because it is all black)
    float borderWidth = 1/[[UIScreen mainScreen] scale];
    CGRect modalBorderRect = CGRectInset(self.modalView.bounds, -borderWidth, -borderWidth);
    UIView *modalBorder = [[UIView alloc] initWithFrame:modalBorderRect];
    modalBorder.backgroundColor = [UIColor darkGrayColor];
    [self.modalView insertSubview:modalBorder atIndex:0];
}

- (void)dismissModalIfShowing {
    if (self.modalView != nil)
        [self.modalView dismiss];
}

@end