//
//  HLJGalleryDetailViewController.m
//  HLJGallery
//
//  Created by TianHe on 2018/12/3.
//

#import "HLJGalleryDetailViewController.h"
#import "Masonry.h"
#import "UIColor+Extend.h"
#import "DeviceInfo.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIScrollView+HLJEmpty.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIScrollView+Refresh.h"
#import "HLJWaitingProgressView.h"
#import "SVProgressHUD.h"
#import "SystemMacroDefine.h"
#import "UINavigationItem+HLJNavigationBar.h"
#import "UIViewController+HLJStatusBarStyle.h"
#import "UINavigationItem+HLJNavigationBar.h"
#import "UIViewController+HLJNavigationBar.h"
//
#import "ShareHelper.h"
#import "HLJTrackEventDefine.h"
#import "TrackEngine.h"
#import "UIView+TrackAttributes.h"
#import "NSDictionary+TrackData.h"
//
#import "HLJMediator+HLJUserActions.h"
#import "HLJMediator+MessageChatActions.h"
#import "HLJMediator+User_MerchantActions.h"
#import "HLJMediator+HLJDiary.h"
#import "HLJMediator+UserAppProductActions.h"
#import "HLJMediator+MealCaseActions.h"
#import "HLJMediator+ThreadActions.h"
//view
#import "HLJGalleryDetailMealCardView.h"
#import "HLJGalleryDetailMerchantCardView.h"
#import "HLJGalleryDetailTableHeaderView.h"
//vm
#import "HLJGalleryDetailViewModel.h"
//cell
#import "CJImageScrollerTableViewCell.h"
//vc
#import "HLJGalleryPreviewViewController.h"
#import "HLJGalleryCategoryViewController.h"

#define kGradientBlackViewHeight 85

@interface HLJGalleryDetailViewController () <UITableViewDelegate,UITableViewDataSource, HLJMediaPreviewViewControllerDelegate,DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>

@property (nonatomic, strong) NSNumber *galleryId;
@property (nonatomic,strong) UIView *gradientBlackView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) HLJGalleryDetailViewModel *viewModel;

@property (nonatomic, strong) NSIndexPath *previewIndexPath;
@property (nonatomic, assign) BOOL shouldReload;///< 收藏状态变更后,进入页面时reload

@end

@implementation HLJGalleryDetailViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithGalleryId:(NSNumber *)galleryId{
    self = [super init];
    if (self) {
        self.galleryId = galleryId;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.shouldReload) {
        [self.tableView reloadData];
        self.shouldReload = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.galleryId == nil) {
        [SVProgressHUD showErrorWithStatus:@"缺少相册ID!"];
        return;
    }
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self setupUI];
    
    [self requestDataWithLoading:YES isRefresh:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(galleryCollectStateChange:) name:kNotificationGallerySetCollect object:nil];
}

- (void)setupUI{
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    @weakify(self)
    [self.tableView addPullToRefreshWithActionHandler:^{
        @strongify(self);
        [self requestDataWithLoading:NO isRefresh:YES];
    }];
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        [self requestDataWithLoading:NO isRefresh:NO];
    }];
    
    RAC(self.tableView, hlj_InfiniteNoMoreData) = RACObserve(self.viewModel, noMoreData);
}

- (void)initGradientView {
    [self.view addSubview:self.gradientBlackView];
    [self.gradientBlackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view);
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(kGradientBlackViewHeight);
    }];
}


- (void)requestDataWithLoading:(BOOL)loading isRefresh:(BOOL)isRefresh{

    if (loading) {
        [HLJWaitingProgressView showLoadingOnView:self.view];
    }
    @weakify(self)
    [[[self.viewModel getGalleryDetailsWithGalleryId:self.galleryId firstlevelTagId:self.firstLevelTagId isRefresh:isRefresh] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self);
        [self configNav];
        [self initGradientView];
        self.tableView.isError = NO;
        [HLJWaitingProgressView removeAllOnView:self.view];
        [self.tableView stopAnimating];
        [self.tableView reloadData];
    } error:^(NSError *error) {
        @strongify(self);
        [HLJWaitingProgressView removeAllOnView:self.view];
        self.tableView.isError = YES;
        [self.tableView stopAnimating];
        [self.tableView reloadData];
        [SVProgressHUD showErrorWithStatus:error.domain];
    }];
}
- (void)configNav{
    [self updateHlj_statusBarStyle:UIStatusBarStyleLightContent];
    self.navigationItem.hlj_navBarShadowColor = [UIColor clearColor];
    self.navigationItem.hlj_navBarBgAlpha = 0;
    self.navigationItem.hlj_barButtonItemTintColor = [UIColor whiteColor];
    [self hlj_setNeedsNavigationItemLayout];
}
#pragma mark - ------ action ------
//收藏状态变更
- (void)galleryCollectStateChange:(NSNotification *)noti{
    NSDictionary *userInfo = noti.userInfo;
    NSNumber *galleryId = userInfo[@"id"];
    BOOL isCollect = [userInfo[@"isCollect"] boolValue];
    NSInteger collectNumber = [userInfo[@"collectNumber"] integerValue];
    for (HLJGalleryDetailModel *item in self.viewModel.galleryList) {
        if (item.galleryId.integerValue == galleryId.integerValue) {
            item.isCollected = isCollect;
            item.collectedNumber = collectNumber;
            self.shouldReload = YES;
            break;
        }
    }
}
//收藏按钮点击
- (void)collecBtnClickWithGallery:(HLJGalleryDetailModel *)galleryModel shouldCollected:(BOOL)shouldCollected{
    
    if (galleryModel == nil) {
        return;
    }
    if (shouldCollected) {
        [[[self.viewModel collectGalleryWithGalleryId:galleryModel.galleryId] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
            galleryModel.isCollected = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGallerySetCollect object:nil userInfo:@{@"isCollect":@(YES),@"id":galleryModel.galleryId,@"collectNumber":@(galleryModel.collectedNumber)}];
        } error:^(NSError *error) {
        }];
    }else{
        [[[self.viewModel cancelCollectGalleryWithGalleryId:galleryModel.galleryId] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
            galleryModel.isCollected = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGallerySetCollect object:nil userInfo:@{@"isCollect":@(NO),@"id":galleryModel.galleryId,@"collectNumber":@(galleryModel.collectedNumber)}];
        } error:^(NSError *error) {
        }];
    }
}
//点击分享
- (void)shareButtonClickInIndexPath:(NSIndexPath *)indexPath{
    HLJGalleryDetailModel *galleryModel = self.viewModel.galleryList[indexPath.section];
    if(!galleryModel.shareItem) {
        return;
    }

    [ShareHelper shareWithItem:galleryModel.shareItem complete:^(ThirdPartyType type, BOOL succeed) {
        
        if(!succeed){
            return;
        }

        NSString *additional;
        switch (type) {
            case ThirdPartyTypeWechat:
                additional = ANALYSIS_ADDITIONAL_SHARETYPE_WX_SESSION;
                break;
            case ThirdPartyTypeWechatFriend:
                additional = ANALYSIS_ADDITIONAL_SHARETYPE_WX_TIMELINE;
                break;
            case ThirdPartyTypeSinaWeibo:
                additional = ANALYSIS_ADDITIONAL_SHARETYPE_SINA_WEIBO;
                break;
            case ThirdPartyTypeQQ:
                additional = ANALYSIS_ADDITIONAL_SHARETYPE_QQ;
                break;
            default:
                additional = nil;
                break;
        }
        
        //        [TrackEngine trackByScreen:nil category:ANALYSIS_CATEGORY_SHOP_PRODUCT ident:galleryModel.id action:ANALYSIS_ACTION_SHARE additional:additional site:MakeTrackSite(@"AA1/A1", 3, @"分享") immediately:YES];
    }];
}

//点击标签
- (void)clickTagAction:(HLJGalleryTagModel *)tagModel{
    
    HLJGalleryCategoryViewController *vc = [[HLJGalleryCategoryViewController alloc] init];
    if (tagModel.parentTag == nil) {
        vc.firstLevelTag = tagModel;
    }else{
        vc.firstLevelTag = tagModel.parentTag;
        vc.secondLevelTag = tagModel;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)galleryDetailCardClickWithGallery:(HLJGalleryDetailModel *)galleryModel{
    switch (galleryModel.fromType) {
        case HLJGalleryFromTypeCase:
        case HLJGalleryFromTypeComment:{
            //跳转商家主页
            UIViewController *vc = [[HLJMediator sharedInstance]  HLJMediator_User_ViewControllerForMerChantDetailWithMerchantId:galleryModel.merchantInfo.merchantId trackSite:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case HLJGalleryFromTypeDiary:{
            //跳转日记详情
            UIViewController *vc = [[HLJMediator sharedInstance] HLJMediator_HLJDiaryDetailViewControllerWithDiaryID:galleryModel.diaryInfo.id];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case HLJGalleryFromTypeProduct:{
            //婚品详情
            UIViewController *vc = [[HLJMediator sharedInstance] HLJMediator_User_ProductDetailPageWithProductId:galleryModel.productInfo.productId];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case HLJGalleryFromTypeMeal:{
            //套餐详情
            UIViewController * vc = [[HLJMediator sharedInstance] HLJMediator_MealDetailPageWithMealId:galleryModel.mealInfo.mealId];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case HLJGalleryFromTypeCommunity:{
            //帖子详情
            UIViewController *vc = [[HLJMediator sharedInstance] HLJMediator_ThreadDetailViewControllerWithThreadId:galleryModel.communityInfo.id type:0 floorNo:nil fromChannel:NO trackSite:nil block:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
    
}

- (void)galleryDetailCardButtonClickWithGallery:(HLJGalleryDetailModel *)galleryModel{
    
    NSNumber *merchanrUserId = nil;
    switch (galleryModel.fromType) {
        case HLJGalleryFromTypeCase:
        case HLJGalleryFromTypeComment:{
            merchanrUserId = galleryModel.merchantInfo.userId;
        }
            break;
        case HLJGalleryFromTypeMeal:{
            merchanrUserId = galleryModel.mealInfo.merchantUserId;
        }
            break;
        default:
            break;
    }
    
    if (merchanrUserId == nil) {
        return;
    }
    if (![[HLJMediator sharedInstance] HLJMediator_checkLogin]) {
        return;
    }
    NSNumber *creatorUserId = [[HLJMediator sharedInstance] HLJMediator_userId];
    UIViewController *vc = [[HLJMediator sharedInstance] HLJMediator_msgConversationViewControllerWithCreatorUserId:creatorUserId toUserId:merchanrUserId otherExtraInfo:nil additionalMessage:nil autoSendMessageText:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark - ------ TableViewDelegate ------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.viewModel.galleryList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

//header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.01;
    }else if (section == 1) {
        return 36;
    }else {
        return 6;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (section == 1) {
        
        HLJGalleryDetailTableHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GalleryDetailSegmenteHeader"];
        if (view == nil) {
            view = [[HLJGalleryDetailTableHeaderView alloc] initWithReuseIdentifier:@"GalleryDetailSegmenteHeader"];
        }
        return view;
    }else{
        
        UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"GalleryDetailWhiteHeader"];
        if (view == nil) {
            view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"GalleryDetailWhiteHeader"];
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [UIColor whiteColor];
            view.backgroundView = backgroundView;
        }
        return view;
    }
}

//cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    HLJGalleryDetailModel *galleryModel = self.viewModel.galleryList[indexPath.section];
    CGFloat bottomHeight = [HLJGalleryDetailTableViewCell bottomViewHeightWithModel:galleryModel];
    return galleryModel.currentImageHeight + bottomHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    @weakify(self)
    
    HLJGalleryDetailModel *galleryModel = self.viewModel.galleryList[indexPath.section];
    NSString *cellID = [HLJGalleryDetailTableViewCell cellIdWithGalleryModel:galleryModel];
    
    HLJGalleryDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[HLJGalleryDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.galleryModel = galleryModel;
    
    cell.tagView.clickTagBlock = ^(HLJGalleryTagModel *tag) {
        @strongify(self)
        [self clickTagAction:tag];
    };
    
    cell.GalleryShareBlock = ^{
        @strongify(self)
        [self shareButtonClickInIndexPath:indexPath];
    };
    cell.GalleryCollectBlock = ^(BOOL shouldCollect) {
        @strongify(self)
        [self collecBtnClickWithGallery:galleryModel shouldCollected:shouldCollect];
    };
    
    cell.GalleryImageTapBlock = ^(UIImageView * _Nonnull imageView) {
        @strongify(self)
        // 预览
        self.previewIndexPath = indexPath;
        
        HLJGalleryPreviewViewController *vc = [HLJGalleryPreviewViewController mediaControllerWithFromImageView:imageView mediaArray:galleryModel.imageArray index:galleryModel.currentIndex delegate:self];
        vc.galleryModel = galleryModel;
        [self presentViewController:vc animated:YES completion:nil];
    };
    
    cell.imageHeightChange = ^(HLJGalleryDetailModel * _Nonnull gallery) {
        @strongify(self)
        [UIView performWithoutAnimation:^{
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }];
    };
    
    if ([cell.cardView isKindOfClass:[HLJGalleryDetailCardBaseView class]]) {
        HLJGalleryDetailCardBaseView *cardbaseView = (HLJGalleryDetailCardBaseView *)cell.cardView;
        cardbaseView.galleryDetailCardClickBlock = ^{
            @strongify(self)
            [self galleryDetailCardClickWithGallery:galleryModel];
        };
        cardbaseView.galleryDetailCardBtnClickBlock = ^{
            @strongify(self)
            [self galleryDetailCardButtonClickWithGallery:galleryModel];
        };
    }
    
    //埋点
    cell.hlj_enableElementViewTrack = YES;
    [cell setTrackTag:@"photos_list" position:indexPath.section];
    cell.hlj_trackData = [galleryModel elementData];
    
    //卡片按钮埋点
    if ([cell.cardView isKindOfClass:[HLJGalleryDetailMealCardView class]]) {
        UIButton *mainButton = ((HLJGalleryDetailMealCardView *)cell.cardView).mainButton;
        [mainButton setTrackTag:@"package_contact_btn" position:indexPath.section];
    }else if ([cell.cardView isKindOfClass:[HLJGalleryDetailMerchantCardView class]]) {
        UIButton *mainButton = ((HLJGalleryDetailMerchantCardView *)cell.cardView).mainButton;
        [mainButton setTrackTag:@"merchant_contact_btn" position:indexPath.section];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ------ HLJMediaPreviewViewControllerDelegate ------

- (CGRect)dismissViewRectForMediaPreviewViewController:(HLJMediaPreviewViewController *)controller index:(NSInteger)index {
    
    HLJGalleryDetailModel *gallery = ((HLJGalleryPreviewViewController *)controller).galleryModel;
    //刷新图片高
    HLJPhotoModel *imageModel = gallery.imageArray[gallery.currentIndex];
    CGFloat scale = imageModel.width / kScreenWidth;
    CGFloat height = 0.0f;
    if (imageModel.width != 0) {
        height = imageModel.height / scale;
    }else{
        height = kScreenWidth;
    }
    gallery.currentImageHeight = height;
    [self.tableView reloadData];
    
    HLJGalleryDetailTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.previewIndexPath];
    UIView *view = cell.imageScrollView;
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    CGRect rect = [view convertRect:view.bounds toView:window];
    return rect;
}
#pragma mark - ------ DZNEmptyDataSetDelegate ------
- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view {
    [self requestDataWithLoading:YES isRefresh:YES];
}
- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView {
    return YES;
}
#pragma mark - ------ set/get ------

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.sectionFooterHeight = 0.01;
        _tableView.estimatedRowHeight = 0;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
    }
    return _tableView;
}

- (UIView *)gradientBlackView {
    if (!_gradientBlackView) {
        _gradientBlackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kGradientBlackViewHeight)];
        _gradientBlackView.backgroundColor = [UIColor clearColor];
        CAGradientLayer *layer = [CAGradientLayer layer];
        layer.colors = @[(id)[[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor,
                         (id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
        layer.locations = @[@(0.0),@(1.0)];
        layer.startPoint = CGPointMake(0.5, 0.0);
        layer.endPoint = CGPointMake(0.5, 1.0);
        layer.type = kCAGradientLayerAxial;
        layer.frame = CGRectMake(0, 0, kScreenWidth, kGradientBlackViewHeight);
        [_gradientBlackView.layer addSublayer:layer];
    }
    return _gradientBlackView;
}

- (HLJGalleryDetailViewModel *)viewModel{
    if (_viewModel == nil) {
        _viewModel = [[HLJGalleryDetailViewModel alloc] init];
    }
    return _viewModel;
}
@end
