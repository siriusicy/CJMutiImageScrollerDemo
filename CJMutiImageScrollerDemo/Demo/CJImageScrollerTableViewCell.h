//
//  CJImageScrollerTableViewCell.h
//  Pods
//
//  Created by TianHe on 2018/11/26.
//

#import <UIKit/UIKit.h>
#import "CJImageModel.h"
#import "CJScrollerUnitModel.h"

@interface CJImageScrollerTableViewCell : UITableViewCell

@property (nonatomic, strong) CJScrollerUnitModel *unitModel;
//
@property (nonatomic, strong, readonly) UIScrollView *imageScrollView;
@property (nonatomic, copy) void(^imageHeightChangeBlock)(CJScrollerUnitModel *unitModel);
@property (nonatomic, copy) void(^imageTapBlock)(UIImageView *imageView);

///获取当前显示的imageview
- (UIImageView *)currentImageView;

@end
