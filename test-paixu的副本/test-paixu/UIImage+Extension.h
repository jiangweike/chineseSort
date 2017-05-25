//
//  UIImage+Extension.h
//  test-paixu
//
//  Created by 姜维克 on 2017/3/2.
//  Copyright © 2017年 O2O_iOS_jiangweike. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)
- (UIImage *)addWaterText:(NSString *)waterText textPosition:(CGPoint)position textAttributes:(NSDictionary<NSString *,id> *)attributes;
@end
