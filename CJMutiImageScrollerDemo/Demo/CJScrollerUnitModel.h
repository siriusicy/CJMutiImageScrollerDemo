//
//  CJScrollerUnitModel.h
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/3/19.
//  Copyright © 2019 CJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CJImageModel.h"

@interface CJScrollerUnitModel : NSObject

@property (nonatomic, copy) NSArray<CJImageModel *> *imageArray;
@property (nonatomic, assign) CGFloat currentImageHeight;
@property (nonatomic, assign) NSInteger currentIndex; ///< 当前显示的是图片数组中的第几张

@end
