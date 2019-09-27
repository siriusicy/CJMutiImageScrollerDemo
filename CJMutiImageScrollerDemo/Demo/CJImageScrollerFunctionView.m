//
//  CJImageScrollerFunctionView.m
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/9/9.
//

#import "CJImageScrollerFunctionView.h"
#import "Masonry.h"
#import "DeviceInfo.h"

@interface CJImageScrollerFunctionView ()

@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *collectButton;

@end

@implementation CJImageScrollerFunctionView


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.shareButton];
        [self addSubview:self.collectButton];
        [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.mas_equalTo(0);
        }];
        
        [self.collectButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.shareButton.mas_right);
            make.top.right.bottom.mas_equalTo(0);
            make.width.mas_equalTo(self.shareButton);
        }];
    }
    return self;
}

#pragma mark -  set/get

- (UIButton *)shareButton{
    if (_shareButton == nil) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shareButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_shareButton setTitle:@"分享" forState:UIControlStateNormal];
        [_shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _shareButton;
}


- (UIButton *)collectButton{
    if (_collectButton == nil) {
        _collectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _collectButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_collectButton setTitle:@"收藏" forState:UIControlStateNormal];
        [_collectButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _collectButton;
}


@end
