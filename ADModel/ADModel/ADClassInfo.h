//
//  ADClassInfo.h
//  ADModel
//
//  Created by 王奥东 on 16/8/2.
//  Copyright © 2016年 王奥东. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN
///**
// Type encoding's type.
// encoding类型
// */
typedef NS_OPTIONS(NSUInteger, ADEncodingType) {
    
    ADEncodingTypeMask         = 0xFF,  ///< mask of type value,遮盖type值
    ADEncodingTypeUnknown      = 0,     ///< unknown
    ADEncodingTypeVoid         = 1,     ///< void
    ADEncodingTypeBool         = 2,     ///< bool
    ADEncodingTypeInt8         = 3,     ///< char / BOOL
    ADEncodingTypeUInt8        = 4,     ///< unsigned char
    ADEncodingTypeInt16        = 5,     ///< short
    ADEncodingTypeUInt16       = 6,     ///< unsigned short
    ADEncodingTypeInt32        = 7,     ///< int
    ADEncodingTypeUInt32       = 8,     ///< unsigned int
    ADEncodingTypeInt64        = 9,     ///< long long
    ADEncodingTypeUInt64       = 10,    ///< unsigned long long
    
    ADEncodingTypeFloat        = 11,    ///< float
    ADEncodingTypeDouble       = 12,    ///< double
    ADEncodingTypeLongDouble   = 13,    ///< long double
    ADEncodingTypeObject       = 14,    ///< id
    ADEncodingTypeClass        = 15,    ///< Class
    ADEncodingTypeSEL          = 16,    ///< SEL
    ADEncodingTypeBlock        = 17,    ///< block
    ADEncodingTypePointer      = 18,    ///< void*
    ADEncodingTypeStruct       = 19,    ///< struct
    ADEncodingTypeUnion        = 20,    ///< union
    ADEncodingTypeCString      = 21,    ///< char*
    ADEncodingTypeCArray       = 22,    ///< char[10] (for example)
   
    
//    这里的1 << 8 等操作是位运算
    ADEncodingTypeQualifierMask     = 0xFF00, ///< mask of qualifier,遮盖修饰
    ADEncodingTypeQualifierConst    = 1 << 8,   ///< const
    ADEncodingTypeQualifierIn       = 1 << 9,   ///< in
    ADEncodingTypeQualifierInout    = 1 << 10,  ///< inout
    ADEncodingTypeQualifierOut      = 1 << 11,  ///< out
    ADEncodingTypeQualifierBycopy   = 1 << 12,  ///< bycopy
    ADEncodingTypeQualifierByref    = 1 << 13,  ///< byref
    ADEncodingTypeQualifierOneway   = 1 << 14,  ///< oneway
    
    
    ADEncodingTypePropertyMask          = 0xFF0000,///mask of property,遮盖property
    ADEncodingTypePropertyReadonly      = 1 << 16, ///< readonly
    ADEncodingTypePropertyCopy          = 1 << 17, ///< copy
    ADEncodingTypePropertyRetain        = 1 << 18, ///< retain
    ADEncodingTypePropertyNonatomic     = 1 << 19, ///< nonatomic
    ADEncodingTypePropertyWeak          = 1 << 20, ///< weak
    ADEncodingTypePropertyCustomGetter  = 1 << 21, ///< getter=
    ADEncodingTypePropertyCustomSetter  = 1 << 22, ///< setter=
    ADEncodingTypePropertyDynamic       = 1 << 23, ///< @dynamic
    
};


/**
 Get the type from a Type-Encoding string.
 从一个type-Encoding string获取type值
 
 @discussion See also(描述也可以看):
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 参数 typeEncoding 一个type-Encoding string
 @return The encoding type.
 返回 这个encoding的type值
 */
ADEncodingType ADEncodingGetType(const char *typeEncoding);

/**
 Instance variable information.
 对象的变量信息
 */
@interface ADClassIvarInfo : NSObject

@property (nonatomic, assign, readonly) Ivar ivar;                   ///< ivar opaque struct ,不透明结构体opaque struct
//  ivar runtime使用时用到的属性，详情可参考我git中的runtime使用Demo
//  https://github.com/DrunkenMouse/rutime
@property (nonatomic, strong, readonly) NSString *name;              ///< Ivar's name

@property (nonatomic, assign, readonly) ptrdiff_t offset;            ///< Ivar's offset

@property (nonatomic, strong, readonly) NSString *typeEncoding;      ///< Ivar's type encoding

@property (nonatomic, assign, readonly) ADEncodingType type;         ///< Ivar's type

/**
 Creates and returns an ivar info object.
 创建并返回一个对象的ivar 信息
 @param ivar ivar opaque struct
 参数 ivar 不透明结构体ivar
 @return A new object, or nil if an error occurs.
 返回 一个新的对象，若产生错误返回Nil
 */
//不透明结构体：结构体定义被隐藏，通常通过指针访问其值
-(instancetype)initWithIvar:(Ivar)ivar;
@end


/**
 Method information.
 方法信息
 */
@interface ADClassMethodInfo : NSObject
@property (nonatomic, assign, readonly) Method method;                 ///< method opaque struct 不透明结构体方法
@property (nonatomic, strong, readonly) NSString *name;                ///< method name 方法的选择子名
@property (nonatomic, assign, readonly) SEL sel;                       ///< method's selector 方法sel
@property (nonatomic, assign, readonly) IMP imp;                       ///< method's implementation 方法实现
@property (nonatomic, strong, readonly) NSString *typeEncoding;        ///< method's parameter and return types,方法参数和返回值类型
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;  ///< return value's type,方法的返回值类型的字符串
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings;   ///< array of arguments' type, type的主题数组，方法的参数类型数组
/**
 Creates and returns a method info object.
 
 创建并返回一个对象方法信息
 
 @param method method opaque struct
 参数 method  不透明结构体方法
 @return A new object, or nil if an error occurs.
 返回 一个新的对象,发生错误返回nil
 */
- (instancetype)initWithMethod:(Method)method;
@end

/**
 Property information.
 property 信息
 */
@interface ADClassPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t property;   ///< property's opaque struct ,property的不透明结构体
@property (nonatomic, strong, readonly) NSString *name;             ///< property's name ,property的名称
@property (nonatomic, assign, readonly) ADEncodingType type;        ///< property's type，通过属性特性列表获取，包括强弱指针、原子性和getter、setter
@property (nonatomic, strong, readonly) NSString *typeEncoding;     ///< property's encoding value
@property (nonatomic, strong, readonly) NSString *ivarName;         ///< property's ivar name
@property (nullable, nonatomic, assign, readonly) Class cls;        ///< may be nil   ,可以是nil,如果属性是个对象，则保存对象的isa指针
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *>       *protocols; ///< may nil,保存对象后面"\<"到">"中的所有信息
@property (nonatomic, assign, readonly) SEL getter;                 ///< getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;                 ///< setter (nonnull)
/**
 Creates and returns a property info object.
 创建并返回一个对象的property信息
 
 @param property property opaque struct
 参数 property 不透明结构体property
 @return A new object, or nil if an error occurs.
 返回 一个新的对象,发生错误返回nil
 */
-(instancetype)initWithProperty:(objc_property_t)property;
@end


/**
 Class information for a class.
 一个class的class 信息
 */
@interface ADClassInfo : NSObject

@property (nonatomic, assign, readonly) Class cls;  ///< class object，自身
@property (nullable, nonatomic, assign, readonly) Class superCls;   ///< super class object，父类
@property (nullable, nonatomic, assign, readonly) Class metaCls;    ///< class's meta class object , 不是元类元类则保存元类
@property (nonatomic, readonly) BOOL isMeta;                        ///< whether this class is meta class  ,这个元素是否为元类
@property (nonatomic, strong, readonly) NSString *name;    ///< class name，保存类名
@property (nullable, nonatomic, strong, readonly) ADClassInfo *superClassInfo; ///< super class's class info ,父类的class信息
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,ADClassInfo *> *ivarInfos;     ///< ivars
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,ADClassMethodInfo *> *methodInfos;    ///< methods，保存例子中所有方法信息，以方法的选择子名为Key，方法信息(ADClassMethodInfo)为value
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,ADClassPropertyInfo *> *propertyInfos;     ///< properties

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 如果这个Class是改变的(列如: 你通过class_addMethod()添加了一个方法给这个类),你应该告诉这个方法去刷新class信息缓存
 After called this method, `needUpdate` will returns `YES`, and you should call
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 被方法告知之后，"needUpdate"应返回"YES",而且你应该告知'classInfoWithClass' or 'classInfoWithClassName'获取这个class更新信息
 */
-(void)setNeedUpdate;

/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.
 如果这个方法返回"YES",你应该停止使用这个对象并告知`classInfoWithClass` or `classInfoWithClassName` 去获取class更新信息
 @return Whether this class info need update.
 返回 这个class 信息是否需要更新
 */
-(BOOL)needUpdate;

/**
 Get the class info of a specified Class.
 
 获取一个Class的class信息说明
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 描述 这个方法将缓存这个class信息 和 父类class信息,在第一次进入这个class时
 这个方法是线程安全的
 @param cls A class.
 参数 cls 一个class
 @return A class info, or nil if an error occurs.
 返回 一个Class 信息， 如果发生错误返回Nil
 */
+(nullable instancetype)classInfoWithClass:(Class)cls;
/**
 Get the class info of a specified Class.
  获取一个Class的class信息说明
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 描述 这个方法将缓存这个class信息和父类class 信息在第一次进入这个class时。
 这个方法是线程安全的
 @param className A class name.
 参数 className 一个class name
 @return A class info, or nil if an error occurs.
 返回 一个class info,如果出现错误返回Nil
 */
+(nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END