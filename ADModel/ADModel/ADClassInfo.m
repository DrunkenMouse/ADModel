//
//  ADClassInfo.m
//  ADModel
//
//  Created by 王奥东 on 16/8/2.
//  Copyright © 2016年 王奥东. All rights reserved.
//

#import "ADClassInfo.h"
#import <objc/runtime.h>

/**
 从一个不可变的type-Encoding 字符数组 获取type值
 @param typeEncoding  A Type-Encoding string.
 参数 typeEncoding 一个type-Encoding string
 @return The encoding type.
 返回 这个encoding的type值
 */


//C语言函数，返回值为ADEncodingType，接收参数为不可变的字符数组typeEncoding
//字符串就是字符数组
ADEncodingType ADEncodingGetType(const char *typeEncoding){
    
    //用一个可变字符数组type保存传过来的不可变字符数组typeEncoding
    //如果type不存在就返回unknown
    char *type = (char *)typeEncoding;
    if (!type) return ADEncodingTypeUnknown;
    //获取字符数组的长度
    //如果长度为0返回unknown
    size_t len = strlen(type);
    if (len == 0) return  ADEncodingTypeUnknown;
    
    //声明一个encoding类型
    ADEncodingType qualifier = 0;
    //设置一个值为true的bool用于while死循环
    bool prefix = true;
    
    //以死循环的方式遍历字符数组type
    while (prefix) {
        
        //从字符数组type的首地址开始一个一个取出内部的字符
        switch (*type) {
                
            case 'r':{
                //对qualifier进行或运算
                //0 | 1 = 1  ，  1 | 1 = 0
                //qualifier =  qualifier | ADEncodingTypeQualifierConst
                qualifier |= ADEncodingTypeQualifierConst;
                //随后地址指针+1
                type++;
            }  break;
                
            case 'n': {
                qualifier |= ADEncodingTypeQualifierIn;
                type++;
            }break;
                
            case 'N': {
                qualifier |= ADEncodingTypeQualifierInout;
                type++;
            }break;
            
            case 'o':{
                qualifier |= ADEncodingTypeQualifierOut;
                type++;
            }break;
                
            case 'O':{
                qualifier |= ADEncodingTypeQualifierBycopy;
                type++;
            }break;
                
            case 'R':{
                qualifier |= ADEncodingTypeQualifierByref;
                type++;
            }break;
                
            case 'V':{
                qualifier |= ADEncodingTypeQualifierOneway;
                type++;
            }break;
            //以上条件都不满足，跳出死循环
            default:{
                prefix = false;
            }
                break;
        }
       
    }
    //获取剩余字符数组的长度
    len = strlen(type);
    
    
    if (len == 0) return ADEncodingTypeUnknown | qualifier;
   
    switch (*type) {
            
        case 'v':   return ADEncodingTypeVoid | qualifier;
        case 'B':   return ADEncodingTypeBool | qualifier;
        case 'c':   return ADEncodingTypeInt8 | qualifier;
        case 'C':   return ADEncodingTypeUInt8 | qualifier;
        case 's':   return ADEncodingTypeInt16 | qualifier;
        case 'S':   return ADEncodingTypeUInt16 | qualifier;
        case 'i':   return ADEncodingTypeInt32 | qualifier;
        case 'I':   return ADEncodingTypeUInt32 | qualifier;
        case 'l':   return ADEncodingTypeInt32 | qualifier;
        case 'L':   return ADEncodingTypeUInt32 | qualifier;
        case 'q':   return ADEncodingTypeInt64 | qualifier;
        case 'Q':   return ADEncodingTypeUInt64 | qualifier;
        case 'f':   return ADEncodingTypeFloat | qualifier;
        case 'd':   return ADEncodingTypeDouble | qualifier;
        case 'D':   return  ADEncodingTypeLongDouble | qualifier;
        case '#':   return ADEncodingTypeClass  | qualifier;
        case ':':   return ADEncodingTypeSEL |qualifier;
        case '*':   return ADEncodingTypeCString | qualifier;
        case '^':   return ADEncodingTypePointer | qualifier;
        case '[':   return ADEncodingTypeCArray | qualifier;
        case '(':   return ADEncodingTypeUnion | qualifier;
        case '{':   return ADEncodingTypeStruct | qualifier;
        case '@':  {
            if (len == 2 && *(type + 1) == '?')
                return ADEncodingTypeBlock | qualifier;
            else
                return ADEncodingTypeObject | qualifier;
        }
        default:
            return ADEncodingTypeUnknown | qualifier;
    }
    
    
}

/**
 Instance variable information.
 对象的变量信息
 
 Creates and returns an ivar info object.
 创建并返回一个对象的ivar 信息
 @param ivar ivar opaque struct
 参数 ivar 不透明结构体ivar
 @return A new object, or nil if an error occurs.
 返回 一个新的对象，若产生错误返回Nil
 */
@implementation ADClassIvarInfo

-(instancetype)initWithIvar:(Ivar)ivar{
    
    if (!ivar) return nil;
    self = [super init];
    _ivar = ivar;
//    ivar_getName 获取成员变量名，可通过[valueForKeyPath:name]获取属性值
    const char *name = ivar_getName(ivar);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    //获取成员变量的偏移量,runtime会计算ivar的地址偏移来找ivar的最终地址
    _offset = ivar_getOffset(ivar);
    //获取ivar的成员变量类型编码
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        //对type string 进行UTF-8编码处理
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        
//        从一个不可变的type-Encoding 字符数组 获取type值
        _type = ADEncodingGetType(typeEncoding);
    }
    return self;
    
}

@end

/**
 Method information.
 方法信息
 
 创建并返回一个对象方法信息
 
 @param method method opaque struct
 参数 method  不透明结构体方法
 @return A new object, or nil if an error occurs.
 返回 一个新的对象,发生错误返回nil
 */

@implementation ADClassMethodInfo

-(instancetype)initWithMethod:(Method)method{
    
    if (!method) return nil;
    
    self = [super init];
    _method = method;
    //获取方法的sel
    _sel = method_getName(method);
    //获取方法的imp
    _imp = method_getImplementation(method);
    
//    Returns the name of the method specified by a given selector.
//    通过获得的一个selector返回这个方法的说明名字
//    @return A C string indicating the name of the selector.
//    返回一个c string 标示这个selector的name
//    返回值：值不可变的字符指针name，字符指针通常指向一个字符数组的首地址，字符数组类似于字符串
    const char *name = sel_getName(_sel);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
//    Returns a string describing a method's parameter and return types.
//    通过接收的一个方法返回一个string类型描述(OC实现的编码类型)
//    @return A C string. The string may be \c NULL.
//    返回一个C string . 这个string 可能是 \c NULL
//    获取描述方法参数和返回值类型
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
//    Returns a string describing a method's return type.
//    通过一个方法返回一个string(字符数组)描述（方法的返回值类型的字符串）
//    @return A C string describing the return type. You must free the string with \c free().
//    返回一个C string 描述. 你必须释放这个string 使用 \c free()
//   获取方法的返回值类型的字符串
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
//     Returns the number of arguments accepted by a method
//    通过一个方法返回主题采用数字(返回方法的参数的个数)
//    @return An integer containing the number of arguments accepted by the given method.
//    返回 一个integer 包含这个主题使用数字通过给予的方法
//    返回方法的参数的个数
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
        NSMutableArray *argumentTypes = [NSMutableArray new];
        for (unsigned int i = 0; i < argumentCount; i++) {
//       Returns a string describing a single parameter type of a method.
//       通过关于一个方法的一个单独的type参数返回一个string描述(获取方法的指定位置参数的类型字符串)
//       获取方法的指定位置参数的类型字符串
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            //argumentTypes能否添加type 如果能则添加type,否则添加@""
            //保证绝对有个对象被添加到可变数组
            [argumentTypes addObject:type ? type: @""];
            if (argumentType) free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    return self;
}

@end

/**
 Property information.
 property 信息
 
 Creates and returns a property info object.
 创建并返回一个对象的property信息
 
 @param property property opaque struct
 参数 property 不透明结构体property
 @return A new object, or nil if an error occurs.
 返回 一个新的对象,发生错误返回nil
 */


@implementation ADClassPropertyInfo

-(instancetype)initWithProperty:(objc_property_t)property{

    
    if (!property)  return nil;
    self = [super init];
    _property = property;
    //查找属性名称
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    ADEncodingType type = 0;
    unsigned int attrCount;
    // 获取属性的特性列表，数量值保存在&attrCount
    objc_property_attribute_t * attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        //name属性的描述 value属性值
        /**
         结构体中的name与Value：
         属性类型  name值：T  value：变化
         编码类型  name值：C(copy) &(strong) W(weak) 空(assign) 等 value：无
         非/原子性 name值：空(atomic) N(Nonatomic)  value：无
         变量名称  name值：V  value：变化
         
         属性描述为 T@"NSString",&,V_str 的 str
         属性的描述：T 值：@"NSString"
         属性的描述：& 值：
         属性的描述：V 值：_str2
         
         G为getter方法，S为setter方法
         D为Dynamic(@dynamic ,告诉编译器不自动生成属性的getter、setter方法)
         */
        switch (attrs[i].name[0]) {
            case 'T':{//Type encoding
                if (attrs[i].value) {
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    type = ADEncodingGetType(attrs[i].value);
                    
                    if ((type & ADEncodingTypeMask) == ADEncodingTypeObject && _typeEncoding.length) {
                        //条件判断
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
//  scanString:intoString:从当前的扫描位置开始扫描，判断扫描字符串是否从当前位置能扫描到和传入字符串相同的一串字符，如果能扫描到就返回YES,指针指向的地址存储的就是这段字符串的内容。
                        if (![scanner scanString:@"@\"" intoString:NULL]) {
                            continue;
                        }
                        
                        NSString *clsName = nil;
//  scanUpToCharactersFromSet:扫描字符串直到遇到NSCharacterSet字符集的字符时停止，指针指向的地址存储的内容为遇到跳过字符集字符之前的内容。
//  NSCharacterSet为一组Unicode字符，常用与NSScanner，NSString处理
                        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                            if (clsName.length)
//                      objc_getClass获取对象的isa，isa是一个指针指向对象自身
                                _cls = objc_getClass(clsName.UTF8String);
                        }
                        
                        NSMutableArray *protocols = nil;
                    
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString *protocol = nil;
//  获取当前位置的某个字符串的内容，可以使用scanUpToString:intoString:方法（如果你不想保留这些字符，可以传递一个NULL给第2个参数）
                            if ([scanner scanUpToString:@">" intoString:&protocol]) {
                                if (protocol.length) {
                                    if (!protocols)
                                        protocols = [NSMutableArray new];
                                    [protocols addObject:protocol];
                                }
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        _protocols = protocols;
                        
                    }
                }
            } break;
        
            case 'V':{// Instance variable
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            }break;
                
            case 'R':{
                type |= ADEncodingTypePropertyReadonly;
            }break;
                
            case 'C':{
                type |=  ADEncodingTypePropertyCopy;
            }break;
                
            case '&':{
                type |=  ADEncodingTypePropertyRetain;
            }break;
                
            case 'N':{
                type |=  ADEncodingTypePropertyNonatomic;
            }break;
                
            case 'D':{
                //Dynamic  ，@dynamic告诉编译器不自动生成属性的getter、setter方法
                type |=  ADEncodingTypePropertyDynamic;
            }break;
                
            case 'W':{
                type |=  ADEncodingTypePropertyWeak;
            }break;
                
            case 'G':{
                type |= ADEncodingTypePropertyCustomGetter;
                if (attrs[i].value) {
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            }break;
                
            case 'S':{
                type |= ADEncodingTypePropertyCustomSetter;
                if (attrs[i].value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            }break;//commented for code coverage in next line
                
            default:
                break;
        }
        
    }

    if (attrs) {
        free(attrs);
        attrs = NULL;
    }
    
    _type = type;
    
    if (_name.length) {
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[_name substringToIndex:1].uppercaseString,[_name substringFromIndex:1]]);
        }
    }
    return self;
}

@end

/**
 Class information for a class.
 一个class的class 信息
 */
//@implementation YYClassInfo {
//    BOOL _needUpdate;
//}
@implementation ADClassInfo {
    BOOL _needUpdate;
}


//私有方法
-(instancetype)initWithClass:(Class)cls{
    
    if (!cls)   return  nil;
    
    self  = [super init];
    _cls = cls;
    _superCls = class_getSuperclass(cls);
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    [self _update];
    
    _superClassInfo = [self.class classInfoWithClass:_superCls];
    return self;
}

//私有方法
-(void)_update{
    
    _ivarInfos = nil;
    _methodInfos = nil;
    _propertyInfos = nil;

    Class cls = self.cls;
    unsigned int methodCount = 0;
//    Describes the instance methods implemented by a class.
//    描述这个对象方法的实现通过一个class
//    @return An array of pointers of type Method describing the instance methods
//    返回关于对象方法描述的一个数组指针
//    数组长度保存在methodCount地址里
    Method *methods = class_copyMethodList(cls, &methodCount);
    
    if (methods) {
        NSMutableDictionary * methodInfos = [NSMutableDictionary new];
        _methodInfos = methodInfos;
        for (unsigned int i = 0; i < methodCount; i++) {
//          使用自定义方法,获取一个对象,对象是根据传过来的一个方法创建
            ADClassMethodInfo *info = [[ADClassMethodInfo alloc] initWithMethod:methods[i]];
            if (info.name)  methodInfos[info.name] = info;
            
        }
        free(methods);
    }
  
    
    //属性的操作
    unsigned int propertyCount = 0;
    //同上，只是关于属性了
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties) {
        NSMutableDictionary *propertyInfos = [NSMutableDictionary new];
        _propertyInfos = propertyInfos;
        for (unsigned int i = 0; i < propertyCount; i++) {
            ADClassPropertyInfo *info = [[ADClassPropertyInfo alloc] initWithProperty:properties[i]];
            if (info.name) propertyInfos[info.name] = info;
                
        }
        free(properties);
    }
    
    //成员变量的操作，与属性的操作区别在于：成员变量{}中声明的, 属性@property声明的
    //属性会有相应的getter方法和setter方法，而成员变量没有，另外，外部访问属性可以用"."来访问，访问成员变量需要用"->"来访问


    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars) {
        NSMutableDictionary *ivarInfos = [NSMutableDictionary new];
        _ivarInfos = ivarInfos;
        for (unsigned int i = 0; i < ivarCount; i++) {
            ADClassIvarInfo *info = [[ADClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (info.name) ivarInfos[info.name] = info;
        }
        free(ivars);
    }
    if (!_ivarInfos) _ivarInfos = @{};
    if (!_methodInfos) _methodInfos = @{};
    if (!_propertyInfos) _propertyInfos = @{};
    
    _needUpdate = NO;
}

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 如果这个Class是改变的(列如: 你通过class_addMethod()添加了一个方法给这个类),你应该告诉这个方法去刷新class信息缓存
 After called this method, `needUpdate` will returns `YES`, and you should call
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 被方法告知之后，"needUpdate"应返回"YES",而且你应该告知'classInfoWithClass' or 'classInfoWithClassName'获取这个class更新信息
 */
-(void)setNeedUpdate{
    _needUpdate = YES;
}
/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.
 如果这个方法返回"YES",你应该停止使用这个对象并告知`classInfoWithClass` or `classInfoWithClassName` 去获取class更新信息
 @return Whether this class info need update.
 返回 这个class 信息是否需要更新
 */
-(BOOL)needUpdate{
    return _needUpdate;
}
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
+(instancetype)classInfoWithClass:(Class)cls{
    if (!cls) return nil;
    //   NSMutableDictionary的底层，直接使用CFMutableDictionaryRef可提高效率
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
     // 为了线程安全 同步信号量
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        /**
         
         @功能 CFDictionaryCreateMutable创建一个新的词典。
         
         @参数 CFAllocator 分配器应该用于分配CFAllocator字典的内存及其值的存储。这
         参数可能为空，在这种情况下，当前的默认值CFAllocator使用。如果这个引用不是一个有效的cfallocator，其行为是未定义的。
         
         @参数 capacity 暗示值得个数，通过0实现可能忽略这个提示，或者可以使用它来优化各种
         
         @参数 keyCallBacks 指向CFDictionaryKeyCallBacks结构为这本字典使用回调函数初始化在字典中的每一个键，初始化规则太多而且看的有点迷糊就不多说了，毕竟不敢乱说。。
         @参数 valueCallBacks 指向CFDictionaryValueCallBacks结构为这本词典使用回调函数初始化字典中的每一个值
         
         
         操作
         
         */
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        //这里我们指定一个资源 wait 返回值就不会为0 执行发出信号操作
        lock = dispatch_semaphore_create(1);
    });
//    没有资源，会一直触发信号控制
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
//    class_isMetaClass(Class cls)，判断指定类是否是一个元类(元类是类对象的类,如[NSArray array]中的NSArray也是一个对象,NSArray通过元类生成,而元类又是一个对象，元类的类是根源类NSObject,NSObject父类为Nil)
    ADClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info _update];
    }
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[ADClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls),(__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

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
+(instancetype)classInfoWithClassName:(NSString *)className{
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}

@end