//
//  CJImageScrollerFunctionCell.m
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/9/9.
//

#import "CJImageScrollerFunctionCell.h"
#import "Masonry.h"
#import "DeviceInfo.h"
#import "CJImageScrollerFunctionView.h"

@interface CJImageScrollerFunctionCell ()

@property (nonatomic, strong) CJImageScrollerFunctionView *functionBtnView;

@end
@implementation CJImageScrollerFunctionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.functionBtnView];
        [self.functionBtnView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.mas_equalTo(0);
        }];
        
    }
    return self;
}

#pragma mark -  set/get

- (CJImageScrollerFunctionView *)functionBtnView{
    if (_functionBtnView == nil) {
        _functionBtnView = [[CJImageScrollerFunctionView alloc] init];
    }
    return _functionBtnView;
}


@end
