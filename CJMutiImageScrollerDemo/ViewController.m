//
//  ViewController.m
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/3/19.
//  Copyright © 2019 CJ. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "DeviceInfo.h"
//cell
#import "CJImageScrollerTableViewCell.h"
#import "CJImageScrollerFlagCell.h"
#import "CJImageScrollerFunctionCell.h"
#import "CJImageScrollerFunctionView.h"
//model
#import "CJScrollerUnitModel.h"

#define kBottomViewHeight 50

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<CJScrollerUnitModel *> *dataArray;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) CJImageScrollerFunctionView *functionBtnView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self creatData];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(kBottomViewHeight);
    }];
    
    
    if (self.dataArray.count > 0) {
        //self.bottomView.XXXXX = self.dataArray.firstObject; ///< 赋值
        self.bottomView.hidden = NO;
    }
    
    [self.tableView reloadData];
 
}

- (void)creatData{
    
    NSMutableArray *muArr = [NSMutableArray arrayWithCapacity:10];
//
    for (int i=0;i<10;++i){
        CJScrollerUnitModel *unitModel = [[CJScrollerUnitModel alloc] init];
        unitModel.imageArray = [self getRandomImageArray];
        if (unitModel.imageArray.count > 0) {
            CJImageModel *image = unitModel.imageArray.firstObject;
            CGFloat scale = image.width / kScreenWidth;
            unitModel.currentImageHeight = scale ? image.height / scale : kScreenWidth;
        }
        
        [muArr addObject:unitModel];
    }
    self.dataArray = [muArr copy];
}

- (NSArray *)getRandomImageArray{
    
    NSMutableArray *muArr = [NSMutableArray array];
    NSInteger renCount = rand()%10 + 3;
    for (int i=0; i<renCount; ++i) {
        NSInteger imageName = rand()%10;
        CJImageModel *image = [CJImageModel creatWithImageName:@(imageName).stringValue];
        [muArr addObject:image];
    }
    return [muArr copy];
}

#pragma mark - ------ TableViewDelegate ------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

//header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}

//cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        CJScrollerUnitModel *unitModel = self.dataArray[indexPath.section];
        CGFloat bottomHeight = 300; ///< 可调参数
        return unitModel.currentImageHeight + bottomHeight;
    }else if (indexPath.row == 1) {
        return kBottomViewHeight;
    }else if (indexPath.row == 2) {
        return 10;
    }
        
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        CJImageScrollerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CJImageScrollerTableViewCell class])];

        cell.unitModel = self.dataArray[indexPath.section];

        cell.imageTapBlock = ^(UIImageView *imageView) {
            
        };
        
        __weak typeof(self) weakSelf = self;
        cell.imageHeightChangeBlock = ^(CJScrollerUnitModel *unitModel) {
            __strong typeof(weakSelf) self = weakSelf;
            [UIView performWithoutAnimation:^{
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }];
        };

        return cell;
    }else if (indexPath.row == 1) {
        CJImageScrollerFunctionCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CJImageScrollerFunctionCell class])];
        return cell;
    }
    
    CJImageScrollerFlagCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CJImageScrollerFlagCell class])];

    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    if ([cell isKindOfClass:[CJImageScrollerFlagCell class]]) {
        self.bottomView.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath{
    
    if ([cell isKindOfClass:[CJImageScrollerFlagCell class]]) {
        __block BOOL showBottomView = YES;
        ///如果屏幕上已经显示了分享/收藏,就隐藏底部的 (屏幕上永远只显示一个分享/收藏view)
        [tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[CJImageScrollerFlagCell class]] &&
                obj != cell) {
                showBottomView = NO;
                *stop = YES ;
            }
        }];
        
        self.bottomView.hidden = !showBottomView;
        
        if (showBottomView) {
            ///< bottomView 设置数据
            //NSInteger showSection = [tableView indexPathsForVisibleRows].lastObject.section;
            //self.functionBtnView.galleryDetail = self.dataArray[showSection];
        }
    }
}
#pragma mark - ------ set/get ------

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.delegate = self;
        _tableView.dataSource = self;

        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.01)];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.01)];
        _tableView.sectionFooterHeight = 0.01;
        _tableView.sectionHeaderHeight = 0.01;
        
        [_tableView registerClass:[CJImageScrollerTableViewCell class] forCellReuseIdentifier:NSStringFromClass([CJImageScrollerTableViewCell class])];
        [_tableView registerClass:[CJImageScrollerFunctionCell class] forCellReuseIdentifier:NSStringFromClass([CJImageScrollerFunctionCell class])];
        [_tableView registerClass:[CJImageScrollerFlagCell class] forCellReuseIdentifier:NSStringFromClass([CJImageScrollerFlagCell class])];
        
    }
    return _tableView;
}

- (UIView *)bottomView{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor greenColor];
        _bottomView.clipsToBounds = NO;
        _bottomView.hidden = YES;
        
        _bottomView.layer.shadowColor = [UIColor blackColor].CGColor;
        _bottomView.layer.shadowOffset = CGSizeMake(0,0);
        _bottomView.layer.shadowOpacity = 0.1;
        _bottomView.layer.shadowRadius = 4;
        
        [_bottomView addSubview:self.functionBtnView];
        [self.functionBtnView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.top.mas_equalTo(0);
            make.width.mas_equalTo(kScreenWidth);
            make.height.mas_equalTo(kBottomViewHeight);
        }];
        
    }
    return _bottomView;
}

- (CJImageScrollerFunctionView *)functionBtnView{
    if (_functionBtnView == nil) {
        _functionBtnView = [[CJImageScrollerFunctionView alloc] init];
    }
    return _functionBtnView;
}


@end
