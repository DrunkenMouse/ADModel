//
//  NSObject+ADModel.m
//  ADModel
//
//  Created by 王奥东 on 16/8/2.
//  Copyright © 2016年 王奥东. All rights reserved.
//

#import "NSObject+ADModel.h"
#import "ADClassInfo.h"
#import <objc/message.h>

/**
 attribute((always_inline))强制内联，所有加了attribute((always_inline))的函数在被调用时不会被编译成函数调用而是直接扩展到调用函数体内
 所以force_inline修饰的方法被执行时，不会跳到方法内部执行，而是将方法内部的代码放到调用者内容去执行
 如force_inline修饰的方法a，在方法b中调用不会跳到a中而是将a中代码放到b中直接执行
 需要注意的是对于#define force_inline __inline__ __attribute__((always_inline))而言
 force_inline 指的是 __inline__ __attribute__((always_inline))
 而并不是单独的attribute((always_inline))
 */

#define force_inline __inline__ __attribute__((always_inline))

// Foundation class Type
// 创建Class Type
typedef NS_ENUM(NSUInteger, ADEncodingNSType) {
    ADEncodingTypeNSUnknown = 0,
    ADEncodingTypeNSString,
    ADEncodingTypeNSMutableString,
    ADEncodingTypeNSValue,
    ADEncodingTypeNSNumber,
    ADEncodingTypeNSDecimalNumber,
    ADEncodingTypeNSData,
    ADEncodingTypeNSMutableData,
    ADEncodingTypeNSDate,
    ADEncodingTypeNSURL,
    ADEncodingTypeNSArray,
    ADEncodingTypeNSMutableArray,
    ADEncodingTypeNSDictionary,
    ADEncodingTypeNSMutableDictionary,
    ADEncodingTypeNSSet,
    ADEncodingTypeNSMutableSet,
};

/// Get the Foundation class type from property info.
/**
 通过property信息获取创建者的class type
 
 isSubclassOfClass: 从自身开始，它沿着类的层次结构，在每个等级与目标类逐一进行比较。如果发现一个相匹配的对象，返回YES。如果它从类的层次结构自顶向下没有发现符合的对象，返回NO
 
 方法意思为：静态的force_inline修饰的返回值为ADEncodingNSType的方法ADClassGetNSType其所需参数为(Class cls)
 */
static force_inline ADEncodingNSType ADClassGetNSType(Class cls) {
    if (!cls) return ADEncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return ADEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return ADEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return ADEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return ADEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return ADEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return ADEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return ADEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return ADEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return ADEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return ADEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return ADEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return ADEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return ADEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return ADEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return ADEncodingTypeNSSet;

    return ADEncodingTypeNSUnknown;
}

/// Whether the type is c number.
//这个类型是否是C类型
static force_inline BOOL ADEncodingTypeIsCNumber(ADEncodingType type) {
    switch (type & ADEncodingTypeMask) {
        case ADEncodingTypeBool:
        case ADEncodingTypeInt8:
        case ADEncodingTypeUInt8:
        case ADEncodingTypeInt16:
        case ADEncodingTypeUInt16:
        case ADEncodingTypeInt32:
        case ADEncodingTypeUInt32:
        case ADEncodingTypeInt64:
        case ADEncodingTypeUInt64:
        case ADEncodingTypeFloat:
        case ADEncodingTypeDouble:
        case ADEncodingTypeLongDouble: return YES;
        default: return NO;
    }
}

/// Parse a number value from 'id'.
/**
 通过id分析出一个数值
 __unsafe_unretained 和assign类似，但是它适用于对象类型，当目标被摧毁时，属性值不会自动清空（unsafe,不安全 unretained引用计数不加一）
 */
static force_inline NSNumber *ADNSNumberCreateFromID(__unsafe_unretained id value) {
    
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
//          isnan(值是无穷大或无穷小的不确定值)或isinf(值是无限循环)
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
//          long long atoll(const char *nptr); 把字符串转换成长长整型数（64位）
            return @(atoll(cstring));
        }
    }
    return nil;
}

/// Parse string to date.
//根据字符串分析出一个date
static force_inline NSDate *ADNSDateFromString(__unsafe_unretained NSString *string) {
    
    typedef NSDate* (^ADNSDateParseBlock)(NSString *string);
    //从这开始声明一个宏定义kParserNum
#define kParserNum 34
    //定义一个ADNSDateParseBlock数组,数组长度为[kParserNum + 1],并全部初始化值为0
    static ADNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            /*
             2014-01-20  // Google
             */
#pragma mark - - - - - - - - -
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    ADNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
//宏定义kParserNum到这里结束
#undef kParserNum
}


/// Get the 'NSBlock' class.
//获得'NSBlock'类，返回值为强转成类的无参无返Block，且其父类为[NSObject class]
static force_inline Class ADNSBlockClass() {
    
    static Class cls;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //定义一个无参无返回值的空block
        //将block强转成NSObject类赋值给cls
#pragma mark - - - - - - - - -
        void (^block)(void) = ^{};
        cls = ((NSObject *)block).class;
        //cls不断向上转换直至父类为[NSObject class]
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls; // current is "NSBlock"
}


/**
 Get the ISO date formatter.
 获取ISO日期格式
 ISO:国际标准化
 
 ISO8601 format example:
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 
 length: 20/24/25
 */

static force_inline NSDateFormatter *ADISODateFormatter() {
    
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc]init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    
    return formatter;
}

/// Get the value with key paths from dictionary
/// The dic should be NSDictionary, and the keyPath should not be nil.
/**
 从一个字典里中根据key paths中包含的key获取一个value
 如果value为字典类型则设置dic为当前value
 但是只获取最后一个value
 dic应该为NSDictionary,keyPath不应该是nil
 */
static force_inline id ADValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths){
    
    id value = nil;
    for (NSUInteger i = 0 ,max = keyPaths.count; i < max; i++) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            }else{
                return nil;
            }
        }
    }
    return value;
}

/// Get the value with multi key (or key path) from dictionary
/// The dic should be NSDictionary
/**
 从字典中根据多个Key(或key path)获取值
 这个dic应该是NSDictionary
 */
static force_inline id ADValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys) {
    
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        } else {
            value = ADValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}


/// A property info in object model.
//model对象中的property信息
@interface _ADModelPropertyMeta : NSObject{
    
    @package
    NSString * _name;           ///< property's name
    ADEncodingType _type;       ///< property's type
    ADEncodingNSType _nsType;   ///< property's Foundation type
    BOOL _isCNumber;            ///< is c number type
    Class _cls;                 ///< property's class, or nil
   
    //  Class _genericCls; 包含的自己创建的class,如果没有则为空
    Class _genericCls;          ///< container's generic class, or nil if threr's no generic class
   
    //    getter方法，如果对象无法响应则为Nil
    SEL _getter;                ///< getter, or nil if the instances cannot respond
   
    //    setter方法，如果对象无法响应则为Nil
    SEL _setter;                ///< setter, or nil if the instances cannot respond
    
   
    //    _isKVCCompatible  如果它可以成功使用KVC则返回YES
    BOOL _isKVCCompatible;///< YES if it can access with key-value coding
   
    //    _isStructAvailableForKeyedArchiver 如果这个struct可以通过key实现encode的archiver/unarchiver则返回YES
    BOOL _isStructAvailableForKeyedArchiver;///< YES if the struct can encoded with keyed archiver/unarchiver
    
    //    _hasCustomClassFromDictionary     class/自己创建的Class 能否实现+modelCustomClassForDictionary
    BOOL _hasCustomClassFromDictionary; ///< class/generic class implements +modelCustomClassForDictionary:
    
    /*
     mapped to 映射
     property->key:       _mappedToKey:key     _mappedToKeyPath:nil            _mappedToKeyArray:nil
     property->keyPath:   _mappedToKey:keyPath _mappedToKeyPath:keyPath(array) _mappedToKeyArray:nil
     property->keys:      _mappedToKey:keys[0] _mappedToKeyPath:nil/keyPath    _mappedToKeyArray:keys(array)
     */
    //   _mappedToKey   映射到的Key
    NSString *_mappedToKey;         ///< the key mapped to
    
    //   _mappedToKeyPath   映射到的keyPath (如果值不是key path则为Nil)
    NSArray *_mappedToKeyPath;      ///< the key path mapped to (nil if the name is not key path)
    
    //   _mappedToKeyArray  key(NSString)或keyPath(NSArray)数组 (如果不能映射到多个key则为nil)
    NSArray *_mappedToKeyArray;     ///< the key(NSString) or keyPath(NSArray) array (nil if not mapped to multiple keys)
    
    //  _info   property的信息
    ADClassPropertyInfo *_info;     ///< property's info
    
    //  _next   下一个元素,如果是多个Property映射到同一个key
    _ADModelPropertyMeta *_next;    ///< next meta if there are multiple properties mapped to the same key.
   
}

@end


@implementation _ADModelPropertyMeta
//meta 元素
// support pseudo generic class with protocol name
// 支持假的generic class通过协议名
// generic class自己写的类
+ (instancetype)metaWithClassInfo:(ADClassInfo *)classInfo propertyInfo:(ADClassPropertyInfo *)propertyInfo generic:(Class)generic {
    
  
    //如果自定义class不存在且Property信息存在protocols
    if (!generic && propertyInfo.protocols) {
        //遍历propertyInfo信息的所有protocols,将其通过UTF-8编码后转换为class类型
        //若转换成功则generic值为此类,结束遍历
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
           
            if (cls) {
                generic = cls;
                break;
            }
            
        }
        
    }
    
    _ADModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    
    if ((meta->_type & ADEncodingTypeMask) == ADEncodingTypeObject) {
        meta->_nsType = ADClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = ADEncodingTypeIsCNumber(meta->_type);
    }
    
    if ((meta->_type & ADEncodingTypeMask) == ADEncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         看来除structs之外不能decode NSValue通过NSKeyedUnarchiver
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        
        //如果自定义的集合包含propertyInfo.typeEncoding
        //则设置meta的isStructAvailableForKeyedArchiver属性为YES
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
        
    }
    meta->_cls = propertyInfo.cls;
    
    /**
     如果你需要在json->object的改变时创建关于不同类的对象
     使用这个方法基于dictionary data去改变custom class
     
     描述 如果model实现了这个方法,他将被认为通知是确定的class结果
     参数 json/kv字典
     返回 通过字典创建的class,nil指使用当前class
     */
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == ADEncodingTypeNSUnknown) {
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation object)
         KVC 无效的类型:
         long double
         提示(例如 SEL/CoreFoundation 对象)
         */
        switch (meta->_type & ADEncodingTypeMask) {
            case ADEncodingTypeBool:
            case ADEncodingTypeInt8:
            case ADEncodingTypeUInt8:
            case ADEncodingTypeInt16:
            case ADEncodingTypeUInt16:
            case ADEncodingTypeInt32:
            case ADEncodingTypeUInt32:
            case ADEncodingTypeInt64:
            case ADEncodingTypeUInt64:
            case ADEncodingTypeFloat:
            case ADEncodingTypeDouble:
            case ADEncodingTypeObject:
            case ADEncodingTypeClass:
            case ADEncodingTypeBlock:
            case ADEncodingTypeStruct:
            case ADEncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default: break;
        }
    }
    
    return meta;
}
@end


/// A class info in object model.
//model对象中一个class 信息
@interface _ADModelMeta : NSObject{

    @package
    
//    一个class的class 信息
    ADClassInfo *_classInfo;
    
    //    Key:映射key和key path,value:_YYModelPropertyMeta
    /// Key:mapped key and key path, Value:_YYModelPropertyMeta.
    NSDictionary *_mapper;
    
    //    数组<_YYModelPropertyMeta>,关于model的所有property元素
    /// Array<_YYModelPropertyMeta>, all property meta of this model.
    NSArray *_allPropertyMetas;
    
    //    数组<_YYModelPropertyMeta>,property元素映射到的一个key path
    /// Array<_YYModelPropertyMeta>, property meta which is mapped to a key path.
    NSArray *_keyPathPropertyMetas;
    
    //    数组<_YYModelPropertyMeta>,property元素映射到的多个key
    /// Array<_YYModelPropertyMeta>, property meta which is mapped to multi keys.
    NSArray *_multiKeysPropertyMetas;
    
    //    关于映射的key(与key path)的数字，等同于_mapper.count
    /// The number of mapped key (and key path), same to _mapper.count.
    NSUInteger _keyMappedCount;
    
    //    Model class 类型
    /// Model class type.
    ADEncodingNSType _nsType;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}
@end

@implementation _ADModelMeta

//自定义方法，未在.h声明
- (instancetype)initWithClass:(Class)cls {
    ADClassInfo *classInfo = [ADClassInfo classInfoWithClass:cls];
    if (!classInfo) return nil;
    self = [super init];
    // Get black list
    //    获取黑名单
    /**
     在model变换时所有在黑名单里的property都将被忽视
     返回 一个关于property name的数组
     */
    NSSet *blacklist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlacklist)]) {
        NSArray *properties = [(id<ADModel>)cls modelPropertyBlacklist];
        if (properties) {
            blacklist = [NSSet setWithArray:properties];
        }
    }
    
    // Get white list
    //    获取白名单
    NSSet *whitelist = nil;
    /**
     如果一个property不在白名单，在model转变时它将被忽视
     返回nil忽视这方面
     
     返回 一个包含property name的数组
     */
    if ([cls respondsToSelector:@selector(modelPropertyWhitelist)]) {
        NSArray *properties = [(id<ADModel>)cls modelPropertyWhitelist];
        if (properties) {
            whitelist = [NSSet setWithArray:properties];
        }
    }
    
    // Get container property's generic class
    //    获取自定义class中包含的property
    NSDictionary *genericMapper = nil;
    /**
     描述:    如果这个property是一个对象容器，列如NSArray/NSSet/NSDictionary
     实现这个方法并返回一个属性->类mapper,告知哪一个对象将被添加到这个array /set /
     */
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<ADModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary new];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isKindOfClass:[NSString class]]) return;
                //object_getClass 返回对象的类
                Class meta = object_getClass(obj);
                if (!meta) return;
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            }];
            genericMapper = tmp;
        }
    }
    
    // Create all property metas.
    // 创建所有的property 元素
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
    //保存根据传过来的class得到的classInfo
    ADClassInfo *curClassInfo = classInfo;
    
    while (curClassInfo && curClassInfo.superCls != nil) { // recursive parse super class, but ignore root class (NSObject/NSProxy)
        //预先解析父类,但忽视根类(NSObject/NSProxy)
        for (ADClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            
            //  若propertyInfo.name不存在
            //  或黑名单存在且黑名单包含propertyInfo.name
            //  或白名单存在且白名单不包含propertyInfo.name
            //  则结束当前循环
            
            if (!propertyInfo.name) continue;
            
            if (blacklist && [blacklist containsObject:propertyInfo.name]) continue;
            if (whitelist && ![whitelist containsObject:propertyInfo.name]) continue;
            
            _ADModelPropertyMeta *meta = [_ADModelPropertyMeta metaWithClassInfo:classInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]];
            
            if (!meta || !meta->_name) continue;
            if (!meta->_getter || !meta->_setter) continue;
            if (allPropertyMetas[meta->_name]) continue;
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    if (allPropertyMetas.count) _allPropertyMetas = allPropertyMetas.allValues.copy;
    
    // create mapper
    //    创建映射
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray new];
    /**
     modelCustomPropertyMapper
     定制属性元素
     描述 如果JSON/Dictionary的key并不能匹配model的property name
     实现这个方法并返回额外的元素
     */
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
         // 返回自定义属性映射字典
        NSDictionary *customMapper = [(id <ADModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {
            _ADModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) return;
                
                propertyMeta->_mappedToKey = mappedToKey;
//                以"."分割字符串为一个数组
                NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:@""];
                        keyPath = tmp;
                        break;
                    }
                }
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
                
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *mappedToKeyArray = [NSMutableArray new];
                for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (oneKey.length == 0) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    } else {
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) return;
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _ADModelPropertyMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = ADClassGetNSType(cls);
    /**
     modelCustomWillTransformFromDictionary:
     这个方法行为是相似的与 "- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic"
     但在model转换前被命名的
     描述 如果model实现了这个方法,它将被命名在"+modelWithJson:","+modelWithDictionary:","-modelSetWithJSON:"and"-modelSetWithDictionary:"之前
     如果方法返回为nil,转换过程中将忽视这个model
     @param dic  The json/kv dictionary.
     参数 dic     json/kv 字典
     @return Returns the modified dictionary, or nil to ignore this model.
     返回     返回修改的字典，如果忽视这个model返回Nil
     */
    _hasCustomWillTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    /**
     modelCustomTransformFromDictionary:
     如果默认的json-to-model转换并不符合你的model对象,实现这个方法去增加额外的过程。
     你也可以使用这个方法使model的property生效
     描述 如果model实现了这个方法,它将被命名在"+modelWithJSON:","+modelWithDictionary","-modelSetWithJSON:" and "-modelSetWithDictionary:"结束
     @param dic  The json/kv dictionary.
     
     参数 dic json/kv 字典
     
     @return Returns YES if the model is valid, or NO to ignore this model.
     
     返回 如果这个model是有效的,返回YES 或返回NO忽视这个model
     
     */
    _hasCustomTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)]);
    /**
     modelCustomTransformToDictionary:
     如果默认的model-to-json转换并不符合你的model class,实现这个方法添加额外的过程。
     你也可以使用这个方法使这个json dictionary有效
     描述 如果这个model实现了这个方法,它将被调用在"-modelToJSONObject"和"-modelToJSONStrign"结束
     如果这个方法返回NO,这个转换过程将忽视这个json dictionary
     */
    _hasCustomTransformToDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)]);
    /**
     modelCustomClassForDictionary:
     如果你需要在json->object的改变时创建关于不同类的对象
     使用这个方法基于dictionary data去改变custom class
     描述 如果model实现了这个方法,他将被认为通知是确定的class结果
     在"+modelWithJson","+modelWithDictionary"期间，父对象包含的property是一个对象
     (两个单数的并经由`+modelContainerPropertyGenericClass`包含)
     */
    _hasCustomClassFromDictionary = ([cls respondsToSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
}

/// Returns the cached model class meta
//返回这个class元素model缓存
+(instancetype)metaWithClass:(Class)cls{
    
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    //第一次进来是没有，但第二次不就有了~
    _ADModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
   
    dispatch_semaphore_signal(lock);
    //如果model元素不存在，或model元素缓存需要更新
    if (!meta || meta -> _classInfo.needUpdate) {
        //重新创建meta
        meta = [[_ADModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void*)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end
//
//
///**
// Get number from property.
// @discussion Caller should hold strong reference to the parameters before this function returns.
// @param model Should not be nil.
// @param meta  Should not be nil, meta.isCNumber should be YES, meta.getter should not be nil.
// @return A number object, or nil if failed.
// */
///**
// 通过property获取一个数字
// 描述 调用者(caller 来访者)应对这个参数保持强引用在这个函数返回之前
// 参数 model 不应该是nil
// 参数 meta  不应该是nil,meta.isCNumber 应该是YES,meta.getter不应该是nil
// 返回 一个数字对象，如果获取失败返回nil
// */
static force_inline NSNumber *ModelCreateNumberFromProperty(__unsafe_unretained id model,__unsafe_unretained _ADModelPropertyMeta *meta) {
    switch (meta->_type & ADEncodingTypeMask) {
        case ADEncodingTypeBool: {
            return @(((bool (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeInt8: {
            return @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeUInt8: {
            return @(((uint8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeInt16: {
            return @(((int16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeUInt16: {
            return @(((uint16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeInt32: {
            return @(((int32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeUInt32: {
            return @(((uint32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeInt64: {
            return @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeUInt64: {
            return @(((uint64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case ADEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case ADEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case ADEncodingTypeLongDouble: {
            double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        default: return nil;
    }
}

/**
 Set number to property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param num   Can be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.setter should not be nil.
 */
/**
 设置数字给property
 描述 调用者(caller 来访者)应对这个参数保持强引用在这个函数返回之前
 参数 model 不应该是nil
 参数 num 可以是nil
 参数 meta 不应该是nil，meta.isCNumber应该是YES,meta.setter不应该是Nil
 */
static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model, __unsafe_unretained NSNumber *num, __unsafe_unretained _ADModelPropertyMeta *meta) {
    switch (meta->_type & ADEncodingTypeMask) {
//            objc_msgSend OC消息传递机制中选择子发送的一种方式，代表是当前对象发送且没有结构体返回值
//            选择子简单说就是@selector()，OC会提供一张选择子表供其查询，查询得到就去调用，查询不到就添加而后查询对应的实现函数。通过_class_lookupMethodAndLoadCache3(仅提供给派发器用于方法查找的函数)，其内部会调用lookUpImpOrForward方法查找，查找之后还会有初始化枷锁缓存之类的操作，详情请自行搜索，就不赘述了。
//            这里的意思是，通过objc_msgSend给强转成id类型的model对象发送一个选择子meta，选择子调用的方法所需参数为一个bool类型的值num.boolValue
//            再通俗点就是让对象model去执行方法meta->_setter,方法所需参数是num.bollValue
//            再通俗点：((void (*)(id, SEL, bool))(void *) objc_msgSend) 一位一个无返回值的函数指针，指向id的SEL方法，SEL方法所需参数是bool类型，使用objc_msgSend完成这个id调用SEL方法传递参数bool类型，(void *)objc_msgSend为什么objc_msgSend前加一个(void *)呢？我查了众多资料，众多。最后终于皇天不负有心人有了个结果，是为了避免某些错误，比如model对象的内存被意外侵占了、model对象的isa是一个野指针之类的。要是有大牛能说明白，麻烦再说下。
//            而((id)model, meta->_setter, num.boolValue）则一一对应前面的id,SEL,bool
//            再通俗点。。你找别家吧。。
        case ADEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.boolValue);
        } break;
        case ADEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)model, meta->_setter, (int8_t)num.charValue);
        } break;
        case ADEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint8_t)num.unsignedCharValue);
        } break;
        case ADEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case ADEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint16_t)num.unsignedShortValue);
        } break;
        case ADEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        }
        case ADEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint32_t)num.unsignedIntValue);
        } break;
        case ADEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.longLongValue);
            }
        } break;
        case ADEncodingTypeUInt64: {
//            NSDecimalNumber数字精确，其值确定后不可修改，是NSNumber的子类
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.unsignedLongLongValue);
            }
        } break;
        case ADEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case ADEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case ADEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        } // break; commented for code coverage in next line
        default: break;
    }
}

/**
 Set value to model with a property meta.
 设置value给model通过一个property 元素
 
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param value Should not be nil, but can be NSNull.
 @param meta  Should not be nil, and meta->_setter should not be nil.
 描述 调用者(caller 来访者)应对这个参数保持强引用在这个函数返回之前
 参数 model 不应该是nil
 参数 value 不应该是nil,但可以是NSNull
 参数 meta  不应该是nil,且meta->_setter 不应该是nil
 */
static void ModelSetValueForProperty(__unsafe_unretained id model,
__unsafe_unretained id value, __unsafe_unretained _ADModelPropertyMeta *meta) {
    if (meta->_isCNumber) {
        //自定义的ADNSNumberCreateFromID
        NSNumber *num = ADNSNumberCreateFromID(value);
        //自定义的ModelSetNumberToProperty
        ModelSetNumberToProperty(model, num, meta);
        if (num) [num class]; // hold the number
    } else if (meta->_nsType) {
        if (value == (id)kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
        } else {
            switch (meta->_nsType) {
                case ADEncodingTypeNSString:
                case ADEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == ADEncodingTypeNSString) {
//  objc_msgSend，这个函数将消息接收者和方法名作为基础参数。消息发送给一个对象时，objc_msgSend通过对象的isa指针获得类的结构体，先在Cache里找，找到就执行，没找到就在分发列表里查找方法的selector，没找到就通过objc_msgSend结构体中指向父类的指针找到父类，然后在父类分发列表找，直到root class（NSObject）。
//  在64位下，直接使用objc_msgSend一样会引起崩溃，必须进行一次强转
//  ((void(*)(id, SEL,int))objc_msgSend)(self, @selector(doSomething:), 0);
//  调用无参数无返回值方法 ((void (*)(id, SEL))objc_msgSend)((id)msg, @selector(noArgumentsAndNoReturnValue));
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (meta->_nsType == ADEncodingTypeNSString) ?  ((NSNumber *)value).stringValue : ((NSNumber *)value).stringValue.mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter,  (meta->_nsType == ADEncodingTypeNSString) ? ((NSURL *)value).absoluteString : ((NSURL *)value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,  meta->_setter, (meta->_nsType == ADEncodingTypeNSString) ? ((NSAttributedString *)value).string : ((NSAttributedString *)value).string.mutableCopy);
                    }
                } break;
                    
                case ADEncodingTypeNSValue:
                case ADEncodingTypeNSNumber:
                case ADEncodingTypeNSDecimalNumber: {
                    if (meta->_nsType == ADEncodingTypeNSNumber) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ADNSNumberCreateFromID(value));
                    } else if (meta->_nsType == ADEncodingTypeNSDecimalNumber) {
                        if ([value isKindOfClass:[NSDecimalNumber class]]) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else if ([value isKindOfClass:[NSNumber class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *)value) decimalValue]];
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, decNum);
                        } else if ([value isKindOfClass:[NSString class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                            NSDecimal dec = decNum.decimalValue;
                            if (dec._length == 0 && dec._isNegative) {
                                decNum = nil; // NaN
                            }
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, decNum);
                        }
                    } else { // YYEncodingTypeNSValue
                        if ([value isKindOfClass:[NSValue class]]) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        }
                    }
                } break;
                    
                case ADEncodingTypeNSData:
                case ADEncodingTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        if (meta->_nsType == ADEncodingTypeNSData) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            NSMutableData *data = ((NSData *)value).mutableCopy;
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_nsType == ADEncodingTypeNSMutableData) {
                            data = ((NSData *)data).mutableCopy;
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                    }
                } break;
                    
                case ADEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ADNSDateFromString(value));
                    }
                } break;
                    
                case ADEncodingTypeNSURL: {
                    if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                        NSString *str = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, nil);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, [[NSURL alloc] initWithString:str]);
                        }
                    }
                } break;
                    
                case ADEncodingTypeNSArray:
                case ADEncodingTypeNSMutableArray: {
                    if (meta->_genericCls) {
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]]) valueArr = value;
                        else if ([value isKindOfClass:[NSSet class]]) valueArr = ((NSSet *)value).allObjects;
                        if (valueArr) {
                            NSMutableArray *objectArr = [NSMutableArray new];
                            for (id one in valueArr) {
                                if ([one isKindOfClass:meta->_genericCls]) {
                                    [objectArr addObject:one];
                                } else if ([one isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:one];
                                        if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne ad_modelSetWithDictionary:one];
                                    if (newOne) [objectArr addObject:newOne];
                                }
                            }
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, objectArr);
                        }
                    } else {
                        if ([value isKindOfClass:[NSArray class]]) {
                            if (meta->_nsType == ADEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter,
                                    ((NSArray *)value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_nsType == ADEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter,
                                   ((NSSet *)value).allObjects.mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case ADEncodingTypeNSDictionary:
                case ADEncodingTypeNSMutableDictionary: {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (meta->_genericCls) {
                            NSMutableDictionary *dic = [NSMutableDictionary new];
                            [((NSDictionary *)value) enumerateKeysAndObjectsUsingBlock:^(NSString *oneKey, id oneValue, BOOL *stop) {
                                if ([oneValue isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:oneValue];
                                        if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne ad_modelSetWithDictionary:(id)oneValue];
                                    if (newOne) dic[oneKey] = newOne;
                                }
                            }];
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, dic);
                        } else {
                            if (meta->_nsType == ADEncodingTypeNSDictionary) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter,
                                    ((NSDictionary *)value).mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case ADEncodingTypeNSSet:
                case ADEncodingTypeNSMutableSet: {
                    NSSet *valueSet = nil;
                    if ([value isKindOfClass:[NSArray class]]) valueSet = [NSMutableSet setWithArray:value];
                    else if ([value isKindOfClass:[NSSet class]]) valueSet = ((NSSet *)value);
                    
                    if (meta->_genericCls) {
                        NSMutableSet *set = [NSMutableSet new];
                        for (id one in valueSet) {
                            if ([one isKindOfClass:meta->_genericCls]) {
                                [set addObject:one];
                            } else if ([one isKindOfClass:[NSDictionary class]]) {
                                Class cls = meta->_genericCls;
                                if (meta->_hasCustomClassFromDictionary) {
                                    cls = [cls modelCustomClassForDictionary:one];
                                    if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                }
                                NSObject *newOne = [cls new];
                                [newOne ad_modelSetWithDictionary:one];
                                if (newOne) [set addObject:newOne];
                            }
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, set);
                    } else {
                        if (meta->_nsType == ADEncodingTypeNSSet) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, valueSet);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)valueSet).mutableCopy);
                        }
                    }
                } // break; commented for code coverage in next line
                    
                default: break;
            }
        }
    } else {
        BOOL isNull = (value == (id)kCFNull);
        switch (meta->_type & ADEncodingTypeMask) {
            case ADEncodingTypeObject: {
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
                } else if ([value isKindOfClass:meta->_cls] || !meta->_cls) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)value);
                } else if ([value isKindOfClass:[NSDictionary class]]) {
                    NSObject *one = nil;
                    if (meta->_getter) {
                        one = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
                    }
                    if (one) {
                        [one ad_modelSetWithDictionary:value];
                    } else {
                        Class cls = meta->_cls;
                        if (meta->_hasCustomClassFromDictionary) {
                            cls = [cls modelCustomClassForDictionary:value];
                            if (!cls) cls = meta->_genericCls; // for xcode code coverage
                        }
                        one = [cls new];
                        [one ad_modelSetWithDictionary:value];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)one);
                    }
                }
            } break;
                
            case ADEncodingTypeClass: {
                if (isNull) {
                    ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)NULL);
                } else {
                    Class cls = nil;
                    if ([value isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(value);
                        if (cls) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)cls);
                        }
                    } else {
                        cls = object_getClass(value);
                        if (cls) {
                            if (class_isMetaClass(cls)) {
                                ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)value);
                            }
                        }
                    }
                }
            } break;
                
            case  ADEncodingTypeSEL: {
                if (isNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)NULL);
                } else if ([value isKindOfClass:[NSString class]]) {
                    SEL sel = NSSelectorFromString(value);
                    if (sel) ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)sel);
                }
            } break;
                
            case ADEncodingTypeBlock: {
                if (isNull) {
                    ((void (*)(id, SEL, void (^)()))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)())NULL);
                } else if ([value isKindOfClass:ADNSBlockClass()]) {
                    ((void (*)(id, SEL, void (^)()))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)())value);
                }
            } break;
                
            case ADEncodingTypeStruct:
            case ADEncodingTypeUnion:
            case ADEncodingTypeCArray: {
                if ([value isKindOfClass:[NSValue class]]) {
                    const char *valueType = ((NSValue *)value).objCType;
                    const char *metaType = meta->_info.typeEncoding.UTF8String;
                    if (valueType && metaType && strcmp(valueType, metaType) == 0) {
                        [model setValue:value forKey:meta->_name];
                    }
                }
            } break;
                
            case ADEncodingTypePointer:
            case ADEncodingTypeCString: {
                if (isNull) {
                    ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, (void *)NULL);
                } else if ([value isKindOfClass:[NSValue class]]) {
                    NSValue *nsValue = value;
                    if (nsValue.objCType && strcmp(nsValue.objCType, "^v") == 0) {
                        ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, nsValue.pointerValue);
                    }
                }
            } // break; commented for code coverage in next line
                //break; 注解对于代码覆盖在下一行
            default: break;
        }
    }
}


typedef struct {
    void *modelMeta;  ///< _ADModelMeta
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} ModelSetContext;

/**
 Apply function for dictionary, to set the key-value pair to model.
 
 @param _key     should not be nil, NSString.
 @param _value   should not be nil.
 @param _context _context.modelMeta and _context.model should not be nil.
 
 对于字典的函数应用，设置key-value配对给model
 参数 _key        不应该是nil,NSString
 参数 _value      不应该是nil
 参数 _context    _context.modelMeta 和 _context.model 不应该是nil
 */

static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void * _context) {
    
    ModelSetContext *context = _context;
    
//      __unsafe_unretained 指针所指向的地址即使已经被释放没有值了，依旧会指向，如同野指针一样，weak/strong这些则会被置为nil。一般应用于iOS 4与OS X  Snow Leopard(雪豹)中，因为iOS 5以上才能使用weak。
//    
//      __unsafe_unretained与weak一样，不能持有对象，也就是对象的引用计数不会加1
//    
//    unsafe_unretained修饰符以外的 strong/ weak/ autorealease修饰符保证其指定的变量初始化为nil。同样的，附有 strong/ weak/ _autorealease修饰符变量的数组也可以保证其初始化为nil。
//    
//    autorealease(延迟释放,给对象添加延迟释放的标记,出了作用域之后，会被自动添加到"最近创建的"自动释放池中)
//    为什么使用unsafe_unretained?
//    作者回答：在 ARC 条件下，默认声明的对象是 strong 类型的，赋值时有可能会产生 retain/release 调用，如果一个变量在其生命周期内不会被释放，则使用 unsafe_unretained 会节省很大的开销。
//    网友提问： 楼主的偏好是说用unsafe_unretained来代替weak的使用，使用后自行解决野指针的问题吗？
//    作者回答：关于 unsafe_unretained 这个属性，我只提到需要在性能优化时才需要尝试使用，平时开发自然是不推荐用的。
    
    //结构体context中的void函数modelMeta通过桥接转换成_ADModelMeta
    __unsafe_unretained _ADModelMeta *meta = (__bridge _ADModelMeta *)(context -> modelMeta);
    __unsafe_unretained _ADModelPropertyMeta *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
    __unsafe_unretained id model = (__bridge id)(context->model);
    
    while (propertyMeta) {
        if (propertyMeta -> _setter) {
            //自定义方法ModelSetValueForProperty
            ModelSetValueForProperty(model, (__bridge __unsafe_unretained id)_value, propertyMeta);
        }
        propertyMeta = propertyMeta -> _next;
    };
    
}

/**
 Apply function for model property meta, to set dictionary to model.
 
 @param _propertyMeta should not be nil, _YYModelPropertyMeta.
 @param _context      _context.model and _context.dictionary should not be nil.
 
 对于model property 元素的函数应用，设置dictionary给model
 参数 _propertyMeta 不应该是nil,_YYModelPropertyMeta
 参数 _context      _context.model 和 _context.dictionary 不应该是nil
 */

static void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta,void * _context){
    ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained _ADModelPropertyMeta *propertyMeta = (__bridge _ADModelPropertyMeta *)(_propertyMeta);
    if (!propertyMeta -> _setter) return;
    id value = nil;
    
    if (propertyMeta -> _mappedToKeyArray) {
        value = ADValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    }else if(propertyMeta -> _mappedToKeyPath){
        value = ADValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    }else{
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }
    
    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        ModelSetValueForProperty(model, value, propertyMeta);
    }
    
}

/**
 Returns a valid JSON object (NSArray/NSDictionary/NSString/NSNumber/NSNull),
 or nil if an error occurs.
 
 @param model Model, can be nil.
 @return JSON object, nil if an error occurs.
 
 返回一个有效的JSON对象(NSArray / NSDictionary / NSString / NSNumber / NSNull)
 如果有错误发生则返回nil
 
 参数 model Model,可以是空
 返回 json对象，如果有错误发生返回nil
 */
static id ModelToJSONObjectRecursive(NSObject *model){
    
    
    if (!model || model == (id)kCFNull) return model;
    
    if ([model isKindOfClass:[NSString class]]) return model;
    
    if ([model isKindOfClass:[NSNumber class]]) return model;
    
    if ([model isKindOfClass:[NSDictionary class]]) {
//      isValidJSONObject  判断是否为Json数据
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [((NSDictionary *)model) enumerateKeysAndObjectsUsingBlock:^(NSString  * key, id  obj, BOOL *  stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) return;
            id jsonObj = ModelToJSONObjectRecursive(obj);
            if (!jsonObj) jsonObj = (id)kCFNull;
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    if ([model isKindOfClass:[NSSet class]]) {
        NSArray *array = ((NSSet *)model).allObjects;
        if ([NSJSONSerialization isValidJSONObject:array]) return array;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in array) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            }else{
                id jsonObj = ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }

    if ([model isKindOfClass:[NSArray class]]) {
        if ([NSJSONSerialization isValidJSONObject:model])  return model;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in (NSArray *)model) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            }else{
                id jsonObj = ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull)  [newArray addObject:jsonObj];
                
            }
            return newArray;
        }
        
    }
    
    
    if ([model isKindOfClass:[NSURL class]]) return ((NSURL *)model).absoluteString;
    
    if ([model isKindOfClass:[NSAttributedString class]]) return ((NSAttributedString *)model).string;
    
    if ([model isKindOfClass:[NSDate class]]) return [ADISODateFormatter() stringFromDate:(id)model];
    
    if ([model isKindOfClass:[NSData class]]) return nil;
    
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:[model class]];
    if (!modelMeta || modelMeta -> _keyMappedCount == 0) return nil;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:64];
    __unsafe_unretained NSMutableDictionary *dic = result; // avoid retain and release in block ,避免在Block里retain、release
    [modelMeta->_mapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyMappedKey, _ADModelPropertyMeta *propertyMeta, BOOL * stop) {
        
        if (!propertyMeta -> _getter) return;
        id value = nil;
        if (propertyMeta -> _isCNumber) {
            value = ModelCreateNumberFromProperty(model, propertyMeta);
        }else if (propertyMeta -> _nsType){
            id v = ((id (*)(id,SEL))(void *)objc_msgSend)((id)model,propertyMeta->_getter);
            value = ModelToJSONObjectRecursive(v);
        }else{
            switch (propertyMeta->_type & ADEncodingTypeMask) {
                case ADEncodingTypeObject:{
                    id v = ((id (*)(id,SEL))(void *)objc_msgSend)((id)model,propertyMeta->_getter);
                    value = ModelToJSONObjectRecursive(v);
                    if (value == (id)kCFNull) value = nil;
                } break;
                case ADEncodingTypeClass:{
                    Class v = ((Class(*)(id,SEL))(void *)objc_msgSend)((id)model,propertyMeta->_getter);
                    value = v ? NSStringFromClass(v) : nil;
                } break;
                    
                case ADEncodingTypeSEL:{
                    SEL v = ((SEL(*)(id,SEL))(void *)objc_msgSend)((id)model,propertyMeta->_getter);
                    value = v ? NSStringFromSelector(v) : nil;
                }break;
                default:  break;
            }
        }
        
        if (!value) return;
     
        
        if (propertyMeta->_mappedToKeyPath) {
            NSMutableDictionary *superDic = dic;
            NSMutableDictionary *subDic = nil;
            for (NSUInteger i = 0, max = propertyMeta -> _mappedToKeyPath.count; i < max ; i++) {
                NSString *key = propertyMeta->_mappedToKeyPath[i];
                if ( i + 1 == max) {//end
                    if (!superDic[key]) superDic[key] = value;
                    break;
                }
                subDic = superDic[key];
                if (subDic) {
                    if ([subDic isKindOfClass:[NSDictionary class]]) {
                        subDic = subDic.mutableCopy;
                        superDic[key] = subDic;
                    }else{
                        break;
                    }
                } else {
                    subDic = [NSMutableDictionary new];
                    superDic[key] = subDic;
                }
                superDic = subDic;
                subDic = nil;
            }
        }else{
            if (!dic[propertyMeta->_mappedToKey]) {
                dic[propertyMeta->_mappedToKey] = value;
            }
        }
    }];

    if (modelMeta->_hasCustomTransformToDictionary) {
        BOOL suc = [((id<ADModel>)model)modelCustomTransformToDictionary:dic];
        if (!suc) return nil;
    }
    return result;
    
}


/// Add indent to string (exclude first line)
/// 给string添加缩进(不包括第一行)
static NSMutableString *ModelDescriptionAddIndent(NSMutableString * desc,NSUInteger indent) {

    for (NSUInteger i = 0, max = desc.length; i < max ; i++) {
        unichar c = [desc characterAtIndex:i];
        if (c == '\n') {
            for (NSUInteger j = 0; j < indent; j++) {
                [desc insertString:@"   " atIndex:i + 1];
            }
            i += indent * 4;
            max += indent * 4;
        }
    }
    return desc;
}


/// Generaate a description string
/// 创建一个字符串描述

static NSString *ModelDescription(NSObject *model) {
    
    static const int kDescMaxLength = 100;
    if (!model) return @"<nil>";
    if (model == (id)kCFNull) return @"<null>";
    if (![model isKindOfClass:[NSObject class]]) return  [NSString stringWithFormat:@"%@",model];

    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:model.class];
    switch (modelMeta->_nsType) {
        case ADEncodingTypeNSString:  case ADEncodingTypeNSMutableString: {
                return [NSString stringWithFormat:@"\"%@\"",model];
            }
       
        case ADEncodingTypeNSValue:
        case ADEncodingTypeNSData: case ADEncodingTypeNSMutableData:{
            NSString *tmp = model.description;
            if (tmp.length > kDescMaxLength) {
                tmp = [tmp substringToIndex:kDescMaxLength];
                tmp = [tmp stringByAppendingString:@"..."];
            }
            return tmp;
        }
           
            
        case ADEncodingTypeNSNumber:
        case ADEncodingTypeNSDecimalNumber:
        case ADEncodingTypeNSDate:
        case ADEncodingTypeNSURL:{
            return [NSString stringWithFormat:@"%@",model];
        }

            
        case ADEncodingTypeNSSet: case ADEncodingTypeNSMutableSet: {
            model = ((NSSet *)model).allObjects;
        }//no break
        
        case ADEncodingTypeNSArray: case ADEncodingTypeNSMutableArray:{
            NSArray *array = (id)model;
            NSMutableString *desc = [NSMutableString new];
            if (array.count == 0) {
                return [desc stringByAppendingString:@"[]"];
            }else {
                [desc appendFormat:@"[\n"];
                for (NSUInteger i = 0, max = array.count; i < max; i++) {
                    NSObject *obj = array[i];
                    [desc appendString:@"   "];
                    [desc appendString:ModelDescriptionAddIndent(ModelDescription(obj).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n" ];
                }
                [desc appendString:@"]"];
                return desc;
            }
        }
            
        case ADEncodingTypeNSDictionary: case ADEncodingTypeNSMutableDictionary: {
            NSDictionary *dic = (id)model;
            NSMutableString *desc = [NSMutableString new];
            if (dic.count == 0) {
                return [desc stringByAppendingString:@"{}"];
            }else{
                NSArray *keys = dic.allKeys;
                [desc appendFormat:@"{\n"];
                for (NSUInteger i = 0, max = keys.count; i < max; i++) {
                    NSString *key = keys[i];
                    NSObject *value = dic[key];
                    [desc appendString:@"   "];
                    [desc appendFormat:@"%@ = %@",key,ModelDescriptionAddIndent(ModelDescription(value).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
                }
                [desc appendString:@"}"];
            }
            return desc;
        }

        default:{
            NSMutableString *desc = [NSMutableString new];
            [desc appendFormat:@"<%@: %p>",model.class,model];
            if (modelMeta->_allPropertyMetas.count == 0)return desc;
            
            //sort property names ,排序property name
            NSArray *properties = [modelMeta->_allPropertyMetas sortedArrayUsingComparator:^NSComparisonResult(_ADModelPropertyMeta *p1, _ADModelPropertyMeta *p2) {
                return [p1->_name compare:p2->_name];
            }];
            [desc appendFormat:@"{\n"];
            for (NSUInteger i = 0, max = properties.count; i < max; i++) {
                _ADModelPropertyMeta *property = properties[i];
                NSString *propertyDesc;
                if (property->_isCNumber) {
                    NSNumber *num = ModelCreateNumberFromProperty(model, property);
                    propertyDesc = num.stringValue;
                }else {
                    
                    switch (property -> _type & ADEncodingTypeMask) {
                        
                        case ADEncodingTypeObject: {
                            id v = ((id(*)(id, SEL))(void *)objc_msgSend)((id)model, property->_getter);
                            
                            propertyDesc = ModelDescription(v);
                            if (!propertyDesc)
                                propertyDesc = @"<nil>";
                            }  break;
                            
                        case ADEncodingTypeClass: {
                            id v = ((id(*)(id,SEL))(void *)objc_msgSend)((id)model,property->_getter);
                            propertyDesc = ((NSObject *)v).description;
                            if (!propertyDesc)  propertyDesc = @"<nil>";
                        } break;
                      
                        case ADEncodingTypeSEL: {
                            SEL sel = ((SEL(*)(id,SEL))(void *)objc_msgSend)((id)model,property->_getter);
                            if (sel)  propertyDesc = NSStringFromSelector(sel);
                            else propertyDesc = @"<NULL>";
                        }  break;
                            
                           
                            
                            //                        case YYEncodingTypeStruct: case YYEncodingTypeUnion: {
                            //                            NSValue *value = [model valueForKey:property->_name];
                            //                            propertyDesc = value ? value.description : @"{unknown}";
                            //                        } break;
                            //                        default: propertyDesc = @"<unknown>";
                            //                    }
                            //                }
                        case ADEncodingTypeBlock:{
                            id block = ((id (*)(id,SEL))(void *) objc_msgSend)((id)model,property->_getter);
                            propertyDesc = block ? ((NSObject *)block).description : @"<nil>";
                        }break;
                        
                        case ADEncodingTypeCArray:
                        case ADEncodingTypeCString:
                        case ADEncodingTypePointer:{
                            void *pointer = ((void* (*)(id, SEL))(void *)objc_msgSend)((id)model,property->_getter);
                            propertyDesc = [NSString stringWithFormat:@"%p",pointer];
                        }break;
                            
                        case ADEncodingTypeStruct:
                        case ADEncodingTypeUnion:{
                            NSValue *value = [model valueForKey:property->_name];
                            propertyDesc = value ? value.description :@"{unknown}";
                        }break;
                        
                        default:propertyDesc = @"<unknown>";
                            
                    }
                }
                propertyDesc = ModelDescriptionAddIndent(propertyDesc.mutableCopy, 1);
                [desc appendFormat:@"   %@ = %@",property->_name,propertyDesc];
                [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
            }
            [desc appendFormat:@"}"];
            return desc;
        }
    }
}

@implementation NSObject(ADModel)

//自定义方法
/**
 _ad_dictionaryWithJSON 类方法，自定义的实现方法并没有相应的方法声明
 接收到了Json文件后先判断Json文件是否为空，判断有两种方式
 if (!json || json == (id)kCFNull)  kCFNull: NSNull的单例，也就是空的意思
 那为什么不用Null、Nil或nil呢？以下为nil，Nil，Null，NSNull的区别
 Nil：对类进行赋空值
 nil：对对象进行赋空值
 Null：对C指针进行赋空操作，如字符串数组的首地址 char *name = NULL
 NSNull：对组合值，如NSArray，Json而言，其内部有值，但值为空
 所以判断条件json不存在或json存在，但是其内部值为空，就直接返回nil
 若son存在且其内部有值，则创建一个空字典(dic)与空NSData(jsonData)值
 而后再判断，若son是NSDictionary类，就直接赋值给字典
 若是NSString类，就将其强制转化为NSString，而后用UTF-8编码处理赋值给jsonData
 若是NSData，就直接赋值给jsonData
 而后判断，而jsonData存在就代表son值转化为二进制NSData，用官方提供的JSON解析就可获取到所需的值赋值为dic，若发现解析后取到得值不是NSDictionary，就代表值不能为dict，因为不是同一类型值，就让dict为nil
 最后返回dict，在这个方法里相当于若JSON文件为NSDictionary类型或可解析成dict的NSData、NSString类型就赋值给dict返回，若不能则返回的dict为nil
*/
+(NSDictionary *)_ad_dictionaryWithJSON:(id)json {
// kCFNull: NSNull的单例
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    }else if([json isKindOfClass:[NSString class]]){
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }else if ([json isKindOfClass:[NSData class]]){
        jsonData = json;
    }
    
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}


/**
 Creates and returns a new instance of the receiver from a json.
 This method is thread-safe.
 
 @param json  A json object in `NSDictionary`, `NSString` or `NSData`.
 
 @return A new instance created from the json, or nil if an error occurs.
 */
// 创建并返回一个新的列子，通过收取的一个Json文件
//这个方法是安全的
//参数：json   Json包含的类型可以是NSDictionary、NSString、NSData
//返回:通过json创建的新的对象，如果解析错误就返回为空
+(instancetype)ad_modelWithJSON:(id)json{
    //将json转换成字典
    NSDictionary *dic = [self _ad_dictionaryWithJSON:json];
    //通过字典转换成所需的实例
    return [self ad_modelWithDictionary:dic];
}

/**
 创建并返回一个新的列子通过参数的key-value字典
 这个方法是安全的
 参数:dictionary 一个key-value字典映射到列子的属性
 字典中任何一对无效的key-value都将被忽视
 返回一个新的列子通过字典创建的，如果解析失败返回为nil
 描述:字典中的key将映射到接收者的property name
 而值将设置给这个Property，如果这个值类型与property不匹配
 这个方法将试图转变这个值基于这些结果：
 结果详情看.h文件
 */
+(instancetype)ad_modelWithDictionary:(NSDictionary *)dictionary{
    if (!dictionary || dictionary == (id)kCFNull) return nil;
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    
    Class cls = [self class];
    //_ADModelMeta保存class信息
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:cls];
    
    
    if (modelMeta->_hasCustomClassFromDictionary) {
        cls = [cls modelCustomClassForDictionary:dictionary] ?: cls;
    }
    
    NSObject *one = [cls new];
    if ([one ad_modelSetWithDictionary:dictionary]) return one;
    return nil;
}

/**
 通过一个json对象设置调用者的property
 json中任何无效的数据都将被忽视
 参数：json 一个关于NSDictionary,NSString,NSData的json对象将映射到调用者的property
 返回：是否成功
 
 */
-(BOOL)ad_modelSetWithJSON:(id)json{
    NSDictionary *dic = [NSObject _ad_dictionaryWithJSON:json];
    return [self ad_modelSetWithDictionary:dic];
}


/**
 通过一个key-value字典设置调用者的属性
 参数：dic  一个Key-Value字典映射到调用者property,字典中任何一对无效的Key-Value都将被忽视
 描述  dictionary中的Key将被映射到调用者的property name 而这个value将设置给property.
 如果value类型与property类型不匹配，这个方法将试图转换这个value基于以下这些值：
 返回  转换是否成功
 */
-(BOOL)ad_modelSetWithDictionary:(NSDictionary *)dic {
    
    if (!dic || dic == (id)kCFNull) return NO;
    if (![dic isKindOfClass:[NSDictionary class]]) return NO;
    
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:object_getClass(self)];
    
    
    if (modelMeta -> _keyMappedCount == 0) return NO;
    
    if (modelMeta->_hasCustomWillTransformFromDictionary) {
        dic = [((id<ADModel>)self) modelCustomWillTransformFromDictionary:dic];
        if (![dic isKindOfClass:[NSDictionary class]]) return NO;
    }
    
    ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(modelMeta);
    context.model = (__bridge void *)(self);
    context.dictionary = (__bridge void *)(dic);
    
    if (modelMeta->_keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {

//        CFDictionaryApplyFunction 对所有键值执行同一个方法
//        @function CFDictionaryApplyFunction调用一次函数字典中的每个值。
//        @param 字典。如果这个参数不是一个有效的CFDictionary,行为是未定义的。
//        @param 调用字典中每一个值执行一次这个方法。如果这个参数不是一个指针指向一个函数的正确的原型,行为是未定义的。
//        @param 一个用户自定义的上下文指针大小的值，通过第三个参数作用于这个函数，另有没使用此函数的。如果上下文不是预期的应用功能，则这个行为未定义。
//        第三个参数的意思，感觉像是让字典所有的键值去执行完方法后，保存在这个上下文指针(如自定义结构体)的指针(指向一个地址，所以自定义的结构体要用&取地址符)所指向的地址，也就是自定义的结构体中。如何保存那？就是这个上下文也会传到参数2中。
//        也就是dic里面的键值对全部执行完参数2的方法后保存在参数3中,其中参数3也会传到参数2的函数中。

        CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
        if (modelMeta->_keyPathPropertyMetas) {
            
            CFArrayApplyFunction((CFArrayRef)modelMeta->_keyPathPropertyMetas, CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_keyPathPropertyMetas)), ModelSetWithPropertyMetaArrayFunction, &context);

        }
        if (modelMeta->_multiKeysPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_multiKeysPropertyMetas, CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_multiKeysPropertyMetas)), ModelSetWithPropertyMetaArrayFunction, &context);
        }
      
    } else {
        
        CFArrayApplyFunction((CFArrayRef)modelMeta->_allPropertyMetas, CFRangeMake(0, modelMeta->_keyMappedCount), ModelSetWithPropertyMetaArrayFunction, &context);
        
    } if (modelMeta->_hasCustomTransformFromDictionary) {
       
        return [((id<ADModel>)self) modelCustomTransformFromDictionary:dic];
    }
  
    return YES;
}


/**
 产生一个json对象通过调用者的property
 返回一个NSDictionary或NSArray的json对象，如果解析失败返回一个Nil
 了解更多消息观看[NSJSONSerialization isValidJSONObject]
 描述：任何无效的property都将被忽视
 如果调用者是NSArray,NSDictionary或NSSet,他将转换里面的对象为json对象
 */
- (id)ad_modelToJSONObject {
        /*
         Apple said:
         The top level object is an NSArray or NSDictionary.
         All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
         All dictionary keys are instances of NSString.
         Numbers are not NaN or infinity.
         */
        /**
         苹果说:
         顶端等级的对象是NSArray 或 NSDictionary
         所有对象是关于NSString,NSNumber,NSArray,NSDictionary或NSNull的列子
         NSString的所有的字典key是列子
         Nunmber并不是NaN或无穷大的
         */
    id jsonObject = ModelToJSONObjectRecursive(self);
    if([jsonObject isKindOfClass:[NSArray class]]) return jsonObject;
    if ([jsonObject isKindOfClass:[NSDictionary class]]) return  jsonObject;
    return nil;
    
}

/**
 创建一个json string‘s data(json字符串二进制数据)通过调用者的property
 返回一个json string's data,如果解析失败返回为空
 描述：任何无效的property都将被忽视
 如果调用者是一个NSArray,NSDictionary或NSSet,它也将转换内部对象为一个Json字符串
 */
- (NSData *)ad_modelToJSONData{
    id jsonObject = [self ad_modelToJSONObject];
    if (!jsonObject) return nil;
    
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:NULL];
}

/**
 创建一个json string通过调用者的property
 返回一个json string,如果错误产生返回一个nil
 描述 任何无效的property都将被忽视
 如果调用者是NSArray,NSDictionary或NSSet,它也将转换内部对象为一个json string
 */
- (NSString *)ad_modelToJSONString{
    NSData *jsonData = [self ad_modelToJSONData];
    if (jsonData.length == 0) return nil;
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

/**
 copy一个对象通过调用者的properties
 返回一个copy的对象，如果解析失败则返回为nil
 */
- (id)ad_modelCopy{
    
    if (self == (id)kCFNull) return self;
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self copy];
    
    NSObject *one = [self.class new];
    
    for (_ADModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        
        if (!propertyMeta->_getter || !propertyMeta->_setter) continue;
        
        if (propertyMeta->_isCNumber) {
            switch (propertyMeta->_type & ADEncodingTypeMask) {
                case ADEncodingTypeBool:{
                    bool num = ((bool(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    
                    ((void(*)(id,SEL,BOOL))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                    
                }  break;
                case ADEncodingTypeInt8:
                case ADEncodingTypeUInt8:{
                    uint8_t num = ((BOOL (*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                }break;
                case ADEncodingTypeInt16:
                case ADEncodingTypeUInt16: {
                    uint16_t num = ((uint16_t(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id,SEL,uint16_t))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }break;
                case ADEncodingTypeInt32:
                case ADEncodingTypeUInt32:{
                    uint32_t num = ((uint32_t(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id,SEL,uint32_t))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }break;
                case ADEncodingTypeInt64:
                case ADEncodingTypeUInt64:{
                    uint64_t num = ((uint64_t (*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id,SEL,uint64_t))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }break;
                case ADEncodingTypeFloat:{
                    float num = ((float(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void(*)(id,SEL,float))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }break;
                case ADEncodingTypeDouble:{
                    double num = ((double(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id,SEL,double))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }break;
                case  ADEncodingTypeLongDouble:{
                    long double num = ((long double (*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void(*)(id,SEL,long double))(void *)objc_msgSend)((id)one,propertyMeta->_setter,num);
                }//break;commented for code coverage in next line
                default:
                    break;
            }
        }else {
            switch (propertyMeta->_type & ADEncodingTypeMask) {
                case ADEncodingTypeObject:
                case ADEncodingTypeClass:
                case ADEncodingTypeBlock:{
                    id value = ((id(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)one,propertyMeta->_setter,value);
                } break;
                case ADEncodingTypeSEL:
                case ADEncodingTypePointer:
                case ADEncodingTypeCString:{
                    size_t value = ((size_t(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    ((void (*)(id,SEL,size_t))(void *)objc_msgSend)((id)one,propertyMeta->_setter,value);
                }break;
                case ADEncodingTypeStruct:
                case ADEncodingTypeUnion:{
                    @try {
                        NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                        if (value) {
                            [one setValue:value forKey:propertyMeta->_name];
                        }
                    } @catch (NSException *exception) { }
                }// break; commented for code coverage in next line
                    
                default:
                    break;
            }
        }
    }
    return one;
}

/**
 Encode the receiver's properties to a coder.
 
 @param aCoder  An archiver object.
 将调用者property编码为一个Coder
 参数 aCoder 一个对象档案
 */
-(void)ad_modelEncodeWithCoder:(NSCoder *)aCoder{
    if (!aCoder) return;
    if (self == (id)kCFNull) {
        [((id<NSCoding>)self)encodeWithCoder:aCoder];
        return;
    }
    
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) {
        [((id<NSCoding>)self)encodeWithCoder:aCoder];
        return;
    }

   
    for (_ADModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_getter) return;
        
        if (propertyMeta->_isCNumber) {
            NSNumber *value = ModelCreateNumberFromProperty(self, propertyMeta);
            if (value) [aCoder encodeObject:value forKey:propertyMeta->_name];
        }else{
            switch (propertyMeta->_type & ADEncodingTypeMask) {
                case ADEncodingTypeObject:{
                    id value = ((id(*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    if (value && (propertyMeta->_nsType || [value respondsToSelector:@selector(encodeWithCoder:)])) {
                        if ([value isKindOfClass:[NSValue class]]) {
                            if ([value isKindOfClass:[NSNumber class]]) {
                                [aCoder encodeObject:value forKey:propertyMeta->_name];
                            }
                        }else {
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        }
                    }
                } break;
                case ADEncodingTypeSEL:{
                    SEL value = ((SEL (*)(id,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_getter);
                    if (value) {
                        NSString *str = NSStringFromSelector(value);
                        [aCoder encodeObject:str forKey:propertyMeta->_name];
                    }
                }break;
                case ADEncodingTypeStruct:
                case ADEncodingTypeUnion:{
                    if (propertyMeta->_isKVCCompatible && propertyMeta->_isStructAvailableForKeyedArchiver) {
                        @try {
                            NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        } @catch (NSException *exception) { }
                    }
                }break;
                default:
                    break;
            }
        }
    }
}

/**
 Decode the receiver's properties from a decoder.
 
 @param aDecoder  An archiver object.
 
 @return self
 通过一个decoder解码成对象的property
 参数 aDecoder 一个对象档案
 返回 调用者自己
 */
-(id)ad_modelInitWithCoder:(NSCoder *)aDecoder{
    if (!aDecoder) return self;
    if (self == (id)kCFNull) return  self;
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return self;
   
    for (_ADModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_setter) continue;
        if (propertyMeta->_isCNumber) {
            NSNumber *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
            if ([value isKindOfClass:[NSNumber class]]) {
                ModelSetNumberToProperty(self, value, propertyMeta);
                [value class];
            }
        }else {
            ADEncodingType type = propertyMeta->_type & ADEncodingTypeMask;
            switch (type) {
                case ADEncodingTypeObject:{
                    id value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    ((void (*)(id,SEL,id))(void *)objc_msgSend)((id)self,propertyMeta->_setter,value);
                }break;
                    
                case ADEncodingTypeSEL:{
                    NSString *str = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    if ([str isKindOfClass:[NSString class]]) {
                        SEL sel = NSSelectorFromString(str);
                        ((void (*)(id,SEL,SEL))(void *)objc_msgSend)((id)self,propertyMeta->_setter,sel);
                    }
                }break;
                    
                case ADEncodingTypeStruct:
                case ADEncodingTypeUnion:{
                    if (propertyMeta->_isKVCCompatible) {
                        @try {
                            NSValue *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                            if ((value)) [self setValue:value forKey:propertyMeta->_name];
                        } @catch (NSException *exception) { }
                    }
                }break;
                default:
                    break;
            }
        }
    }
    return self;
  
    
}

/**
 Get a hash code with the receiver's properties.
 
 @return Hash code.
 通过调用者Property获取到一个哈希Code
 返回 hashCode
 */
-(NSUInteger)ad_modelHash{
    if (self == (id)kCFNull) return [self hash];
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self hash];
    
    NSUInteger value = 0;
    NSUInteger count = 0;
    for (_ADModelPropertyMeta *properytyMeta in modelMeta->_allPropertyMetas) {
        if (!properytyMeta->_isKVCCompatible) continue;
        value ^= [[self valueForKey:NSStringFromSelector(properytyMeta->_getter)] hash];
        count++;
    }
    if (count == 0) value = (long)((__bridge  void *)self);
    return value;
}

/**
 Compares the receiver with another object for equality, based on properties.
 
 @param model  Another object.
 
 @return `YES` if the reciever is equal to the object, otherwise `NO`.
 比较这个调用者和另一个对象是否相同，基于property
 参数 model 另一个对象
 返回 如果两个对象相同则返回YES 否则为NO
 */
-(BOOL)ad_modelIsEqual:(id)model{
    if (self == model) return YES;
    if (![model isMemberOfClass:self.class]) return NO;
    _ADModelMeta *modelMeta = [_ADModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self isEqual:model];
    if ([self hash] != [model hash]) return NO;
    
    for (_ADModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_isKVCCompatible) continue;
        id this = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        id that = [model valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        if (this == that) continue;
        if (this == nil || that == nil) return NO;
        if (![this isEqual:that]) return NO;
    }
    return YES;
}


/**
 Description method for debugging purposes based on properties.
 
 @return A string that describes the contents of the receiver.
 描述方法为基于属性的Debug目的(Debug模式中基于属性的描述方法)
 返回一个字符串描述调用者的内容
 */
-(NSString *)ad_modelDescription{
    return ModelDescription(self);
}

@end


@implementation NSArray (ADModel)

/**
 通过一个json-array创建并返回一个数组
 这个方法是安全的
 
 参数:cls array中的对象类
 参数:json 一个json array 关于"NSArray","NSString"或"NSData"
 列子:[{"name","Mary"},{name:"Joe"}]
 返回一个数组,如果解析错误则返回nil
 */
+(NSArray *)ad_modelArrayWithClass:(Class)cls json:(id)json{
    if (!json) return nil;
    NSArray *arr = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSArray class]]) {
        arr = json;
    }else if([json isKindOfClass:[NSString class]]){
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }else if([json isKindOfClass:[NSData class]]){
        jsonData = json;
    }
    if (jsonData) {
        arr = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![arr isKindOfClass:[NSArray class]]) arr = nil;
    }
    return [self ad_modelArrayWithClass:cls array:arr];
    
}
//自定义方法，未在.h声明
+ (NSArray *)ad_modelArrayWithClass:(Class)cls array:(NSArray *)arr{
  
    if (!cls || !arr) return nil;
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *dic in arr) {
        if (![dic isKindOfClass:[NSDictionary class]]) continue;
        NSObject *obj = [cls ad_modelWithDictionary:dic];
        if (obj) [result addObject:obj];
    }
    return result;
}
@end

@implementation NSDictionary(ADModel)

/**
 @return A dictionary, or nil if an error occurs.
 通过一个json文件创建并返回一个字典
 这个方法是安全的
 参数cls  字典中value的对象class
 参数json 一个json的字典是"NSDictionary","NSStirng"或"NSData"的
 列子: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}
 */
+(NSDictionary *)ad_modelDictionaryWithClass:(Class)cls json:(id)json{
    if (!json) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    }else if([json isKindOfClass:[NSString class]]){
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }else if([json isKindOfClass:[NSData class]]){
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return [self ad_modelDictionaryWithClass:cls dictionary:dic];
}
//自定义方法，未在.h声明
+(NSDictionary *)ad_modelDictionaryWithClass:(Class)cls dictionary:(NSDictionary *)dic {
    if (!cls || !dic) return nil;
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSString *key in dic.allKeys) {
        if (![key isKindOfClass:[NSString class]]) continue;
        NSObject *obj = [cls ad_modelWithDictionary:dic[key]];
        if (obj) result[key] = obj;
    }
    return result;
}
@end