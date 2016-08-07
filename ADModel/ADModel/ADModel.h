//
//  ADModel.h
//  ADModel
//
//  Created by 王奥东 on 16/8/2.
//  Copyright © 2016年 王奥东. All rights reserved.
//
#import <Foundation/Foundation.h>
//如果包含方式是<YYModel/YYModel.h>,则通过<YYModel/>形式导入剩下两个.h文件
#if __has_include(<ADModel/ADModel.h>)
//定义常量
FOUNDATION_EXPORT double ADModelVersionNumber;
FOUNDATION_EXPORT const unsigned char ADModelVersionString[];
#import <ADModel/NSObject+ADModel.h>
#import <ADModel/ADClassInfo.h>
#else
#import "NSObject+ADModel.h"
#import "ADClassInfo.h"
#endif

