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
//model
#import "CJScrollerUnitModel.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<CJScrollerUnitModel *> *dataArray;

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
    return 1;
}

//header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}

//cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CJScrollerUnitModel *unitModel = self.dataArray[indexPath.section];
    CGFloat bottomHeight = 30;
    return unitModel.currentImageHeight + bottomHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CJImageScrollerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CJImageScrollerTableViewCell"];
    if (!cell) {
        cell = [[CJImageScrollerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CJImageScrollerTableViewCell"];
    }

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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    }
    return _tableView;
}

@end
