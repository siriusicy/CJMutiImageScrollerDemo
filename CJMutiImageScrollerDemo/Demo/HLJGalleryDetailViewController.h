//
//  HLJGalleryDetailViewController.h
//  HLJGallery
//
//  Created by TianHe on 2018/12/3.
//

#import <UIKit/UIKit.h>

@interface HLJGalleryDetailViewController : UIViewController

@property (nonatomic, strong) NSNumber *firstLevelTagId;

- (instancetype)initWithGalleryId:(NSNumber *)galleryId;

@end
