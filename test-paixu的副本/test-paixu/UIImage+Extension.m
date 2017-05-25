//
//  UIImage+Extension.m
//  test-paixu
//
//  Created by 姜维克 on 2017/3/2.
//  Copyright © 2017年 O2O_iOS_jiangweike. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)
- (UIImage *)addWaterText:(NSString *)waterText textPosition:(CGPoint)position textAttributes:(NSDictionary<NSString *,id> *)attributes {
    UIGraphicsBeginImageContext(self.size);
    [self drawAtPoint:CGPointZero];
    [waterText drawAtPoint:position withAttributes:attributes];
    UIImage *waterImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return waterImg;
}
@end
