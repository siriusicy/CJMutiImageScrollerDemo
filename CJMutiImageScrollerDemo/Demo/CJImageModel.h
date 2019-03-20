//
//  CJImageModel.h
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/3/19.
//  Copyright © 2019 CJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CJImageModel : NSObject

@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

+ (CJImageModel *)creatWithImageName:(NSString *)imageName;

@end
