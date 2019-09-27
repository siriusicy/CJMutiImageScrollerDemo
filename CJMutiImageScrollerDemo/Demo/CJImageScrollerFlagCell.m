//
//  CJImageScrollerFlagCell.m
//  CJMutiImageScrollerDemo
//
//  Created by TianHe on 2019/9/6.
//  Copyright © 2019 CJ. All rights reserved.
//

#import "CJImageScrollerFlagCell.h"

@implementation CJImageScrollerFlagCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor blackColor];
    }
    return self;
}
@end
