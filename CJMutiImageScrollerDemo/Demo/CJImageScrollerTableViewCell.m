//
//  CJImageScrollerTableViewCell.m
//  Pods
//
//  Created by TianHe on 2018/11/26.
//

#import "CJImageScrollerTableViewCell.h"
#import "Masonry.h"
#import "DeviceInfo.h"
#import "UIView+Extend.h"

@interface CJImageScrollerTableViewCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *imageScrollView;
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *midImageView;
@property (nonatomic, strong) UIImageView *rightImageView;
@property (nonatomic, strong) UIView *pageBgView;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, assign) CGFloat lastPosition;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation CJImageScrollerTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.imageScrollView];
        [self.imageScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.mas_equalTo(0);
        }];

        [self.contentView addSubview:self.pageBgView];
        [self.pageBgView addSubview:self.infoLabel];
        [self.pageBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.imageScrollView.mas_bottom).offset(-16);
            make.right.mas_equalTo(-16);
            make.height.mas_equalTo(20);
        }];
        
        [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
            make.right.mas_equalTo(-10);
            make.centerY.mas_equalTo(0);
        }];
        
    }
    return self;
}

- (UIImageView *)currentImageView{
    return self.midImageView;
}
#pragma mark - ------ action ------

- (void)tapImageAction:(UITapGestureRecognizer *)tap{
    if (self.imageTapBlock) {
        self.imageTapBlock((UIImageView *)(tap.view));
    }
}

#pragma mark - ------ UIScrollViewDelegate ------

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (decelerate) {
        scrollView.userInteractionEnabled = NO;
    }
}
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    self.lastPosition = scrollView.contentOffset.x;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    //    NSLog(@"velocity x:%f - y:%f",velocity.x,velocity.y);
//    NSLog(@"targetContentOffset x:%f - y:%f",targetContentOffset->x,targetContentOffset->y);
    //在这个方法里提前能知道停止的位置
    CGFloat targetOffsetX = targetContentOffset->x;
    self.currentPage = targetOffsetX / kScreenWidth;

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    scrollView.userInteractionEnabled = YES;
    
    if (self.unitModel.currentIndex != self.currentPage) {
        self.unitModel.currentIndex = self.currentPage;
        [self refreshIndex];
        
        CGFloat height = [self getMidImageViewHeight];
        [self resetImageViewFrameWithMidImageViewHeight:height];
        
        if (fabs(self.unitModel.currentImageHeight - height) > 2){
            self.unitModel.currentImageHeight = height;
            [self updateScrollerSize];
            if (self.imageHeightChangeBlock){
                self.imageHeightChangeBlock(self.unitModel);
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.lastPosition < 0) { //拖拽的时候设置lastPosition,屏蔽在此之前的滚动
        return;
    }
    
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat currentPostion = offsetX;
    
    int page = offsetX / kScreenWidth;
    
    BOOL isleft;
    if (currentPostion > _lastPosition) {
        isleft = YES; //手从右往左滑动
        if (page > 0 && offsetX - page*kScreenWidth < 0.01) {
            page = page-1;
        }
    }else{
        isleft = NO;
    }
    
    if (page < 0 || page >= self.unitModel.imageArray.count - 1) {
        return;
    }
    
    UIImageView *firstImgView = (UIImageView *)[self.imageScrollView viewWithTag:100+page];
    UIImageView *secondImgView = (UIImageView *)[self.imageScrollView viewWithTag:100+page+1];
    if (firstImgView == nil || secondImgView == nil) {
        return;
    }
    
    CJImageModel *firstModel = self.unitModel.imageArray[page];
    CJImageModel *secondModel = self.unitModel.imageArray[page+1];

    CGFloat firstImgHeight = [self heightformodel:firstModel];
    CGFloat secondImgHeight = [self heightformodel:secondModel];
    
    CGFloat distanceY = isleft ? secondImgHeight-firstImgView.height : firstImgHeight-firstImgView.height;
    CGFloat leftDistanceX = (page+1)*kScreenWidth-_lastPosition;
    CGFloat rightDistanceX = kScreenWidth-leftDistanceX;
    CGFloat distanceX = isleft ? leftDistanceX : rightDistanceX;
    
    CGFloat movingDistance = 0.0;
    if (distanceX != 0 && fabs(_lastPosition-currentPostion) > 0) {
        movingDistance = distanceY/distanceX*(fabs(_lastPosition-currentPostion));
    }
    
    CGFloat firstScale = firstModel.width * 1.0 / firstModel.height;
    CGFloat secondScale = secondModel.width * 1.0 / secondModel.height;
    
    firstImgView.frame = CGRectMake((firstImgView.frame.origin.x-movingDistance*firstScale), 0, (firstImgView.height+movingDistance)*firstScale, firstImgView.height+movingDistance);
    secondImgView.frame = CGRectMake(kScreenWidth*(page+1), 0, firstImgView.height*secondScale, firstImgView.height);
    
    self.unitModel.currentImageHeight = firstImgView.height;
    
    [self updateScrollerSize];
    
    if (self.imageHeightChangeBlock) {
//        NSLog(@"self.unitModel.cellHeight : %f",firstImgView.height);
        self.imageHeightChangeBlock(self.unitModel);
    }
    
    _lastPosition = currentPostion;
}

#pragma mark - ------ private ------

- (CGFloat)heightformodel:(CJImageModel *)model{
    if (model.width == 0 || model.height == 0) {
        return kScreenWidth;
    }
    CGFloat width = kScreenWidth;
    CGFloat scale = model.width / width;
    CGFloat height =  model.height / scale;
    return height;
}

- (CGFloat)widthformodel:(CJImageModel *)model height:(CGFloat)height{
    if (height == 0 || model.height == 0 || model.width == 0) {
        return kScreenWidth;
    }
    CGFloat scale = model.height / height;
    CGFloat width =  model.width / scale;
    return width;
}

- (void)updateScrollerSize{
    self.imageScrollView.contentSize = CGSizeMake(self.imageScrollView.contentSize.width, 0);
    [self.imageScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.unitModel.currentImageHeight);
    }];
}

- (void)refreshIndex{
    self.pageBgView.hidden = self.unitModel.imageArray.count <= 1 ;
    self.infoLabel.text = [NSString stringWithFormat:@"%zd/%zd",self.unitModel.currentIndex+1, self.unitModel.imageArray.count];
}

- (void)resetImageViewFrameWithMidImageViewHeight:(CGFloat)height{
    
    if (self.unitModel.imageArray.count <= 0) {
        self.midImageView.hidden = YES;
        self.leftImageView.hidden = YES;
        self.rightImageView.hidden = YES;
        return;
    }
    
    CGFloat width = kScreenWidth;
    NSInteger currentIndex = self.unitModel.currentIndex;
    CJImageModel *midImageModel = self.unitModel.imageArray[currentIndex];
    //
    self.midImageView.hidden = NO;
    self.midImageView.frame = CGRectMake(width*self.unitModel.currentIndex, 0, width, height);
    self.midImageView.tag = 100+currentIndex;
    self.midImageView.image = [UIImage imageNamed:midImageModel.imageName];
    //
    if (self.unitModel.currentIndex > 0) {
        self.leftImageView.hidden = NO;
        CJImageModel *leftImageModel = self.unitModel.imageArray[self.unitModel.currentIndex-1];
        CGFloat leftImageWidth = [self widthformodel:leftImageModel height:height];
        self.leftImageView.frame = CGRectMake(width*self.unitModel.currentIndex-leftImageWidth, 0,leftImageWidth , height);
        self.leftImageView.image = [UIImage imageNamed:leftImageModel.imageName];
    }else{
        self.leftImageView.hidden = YES;
    }
    self.leftImageView.tag = 100 + currentIndex - 1;
    
    //
    if (self.unitModel.imageArray.count > self.unitModel.currentIndex+1) {
        self.rightImageView.hidden = NO;
        CJImageModel *rightImageModel = self.unitModel.imageArray[self.unitModel.currentIndex+1];
        CGFloat rightImageWidth = [self widthformodel:rightImageModel height:height];
        self.rightImageView.frame = CGRectMake(width*(self.unitModel.currentIndex+1), 0, rightImageWidth, height);
        self.rightImageView.image = [UIImage imageNamed:rightImageModel.imageName];
    }else{
        self.rightImageView.hidden = YES;
    }
    self.rightImageView.tag = 100 + currentIndex + 1;
    
}

- (CGFloat)getMidImageViewHeight{
    if (self.unitModel.imageArray.count <= 0) {
        return kScreenWidth;
    }
    
    CJImageModel *midImageModel = self.unitModel.imageArray[self.unitModel.currentIndex];
    CGFloat width = kScreenWidth;
    CGFloat scale = midImageModel.width / width;
    CGFloat height = 0.0f;
    if (midImageModel.width != 0) {
        height = midImageModel.height / scale;
    }else{
        height = width;
    }
    return height;
}
#pragma mark - ------ set/get ------

- (void)setUnitModel:(CJScrollerUnitModel *)unitModel{

    _unitModel = unitModel;
    
    self.lastPosition = -1; ///< 置为负数,屏蔽设置contentSize而调用scrollerView的代理
    self.currentPage = unitModel.currentIndex;
    
    [self refreshIndex];
    [self configImageScroller];

}

- (void)configImageScroller{

    CGFloat height = [self getMidImageViewHeight];
    
    [self.imageScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height);
    }];
    ///ScrollView的contentSize的高度始终设为0,以防止影响tableview的上下滚动
    self.imageScrollView.contentSize = CGSizeMake(self.unitModel.imageArray.count*kScreenWidth, 0);
    self.imageScrollView.contentOffset = CGPointMake(kScreenWidth * self.unitModel.currentIndex, 0);

    [self resetImageViewFrameWithMidImageViewHeight:height];
}

- (UIView *)pageBgView{
    if (_pageBgView == nil) {
        _pageBgView = [[UIView alloc] init];
        _pageBgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _pageBgView.layer.cornerRadius = 10;
        _pageBgView.clipsToBounds = YES;
    }
    return _pageBgView;
}

- (UILabel *)infoLabel{
    if (_infoLabel == nil) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:12];
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.backgroundColor = [UIColor clearColor];

    }
    return _infoLabel;
}

- (UIScrollView *)imageScrollView {
    if (_imageScrollView == nil) {
        _imageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0)];
        _imageScrollView.delegate = self;
        _imageScrollView.pagingEnabled = YES;
        _imageScrollView.bounces = NO;
        _imageScrollView.showsHorizontalScrollIndicator = NO;
        _imageScrollView.showsVerticalScrollIndicator = NO;
        
        if (@available(iOS 11.0, *)) { /// !!!这个必须要加,不然tableview上下滚动会混乱!!!
            _imageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [_imageScrollView addSubview:self.leftImageView];
        [_imageScrollView addSubview:self.midImageView];
        [_imageScrollView addSubview:self.rightImageView];
    }
    return _imageScrollView;
}

- (UIImageView *)leftImageView{
    if (_leftImageView == nil) {
        _leftImageView = [self getImageView];
    }
    return _leftImageView;
}

- (UIImageView *)midImageView{
    if (_midImageView == nil) {
        _midImageView = [self getImageView];
    }
    return _midImageView;
}

- (UIImageView *)rightImageView{
    if (_rightImageView == nil) {
        _rightImageView = [self getImageView];
    }
    return _rightImageView;
}

- (UIImageView *)getImageView{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0)];
    imgView.clipsToBounds = YES;
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.backgroundColor = [UIColor grayColor];
    imgView.userInteractionEnabled = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageAction:)];
    [imgView addGestureRecognizer:tap];
    return imgView;
}

@end
