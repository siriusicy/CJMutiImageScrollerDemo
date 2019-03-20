//
//  CJImageModel.m
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/3/19.
//  Copyright © 2019 CJ. All rights reserved.
//

#import "CJImageModel.h"

@implementation CJImageModel

+ (CJImageModel *)creatWithImageName:(NSString *)imageName{
    UIImage *image = [UIImage imageNamed:imageName];
    
    CJImageModel *imageModel = [[CJImageModel alloc] init];
    imageModel.imageName = imageName;
    imageModel.width = image.size.width;
    imageModel.height = image.size.height;
    
    return imageModel;
}

@end
