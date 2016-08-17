//
//  NSObject+ADModel.h
//  ADModel
//
//  Created by 王奥东 on 16/8/2.
//  Copyright © 2016年 王奥东. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//mapped to 映射
//列子 instancetype 通常也指实例

/**
 Provide some data-model method:
 提供一些数据模型方法
 
 * Convert json to any object, or convert any object to json.
 * Set object properties with a key-value dictionary (like KVC).
 * Implementations of `NSCoding`, `NSCopying`, `-hash` and `-isEqual:`.
 转化json为任何对象，或转换任何对象为json
 通过key-value字典设置对象属性(像KVC)
 实现"NSCoding","NSCopying","-hash"和"isEqual:"
 
 See `ADModel` protocol for custom methods.
 看ADModel协议通过方法
 Sample Code:
 
 ********************** json convertor *********************
 @interface ADAuthor : NSObject
 @property (nonatomic, strong) NSString *name;
 @property (nonatomic, assign) NSDate *birthday;
 @end
 @implementation ADAuthor
 @end
 
 @interface ADBook : NSObject
 @property (nonatomic, copy) NSString *name;
 @property (nonatomic, assign) NSUInteger pages;
 @property (nonatomic, strong) ADAuthor *author;
 @end
 @implementation ADBook
 @end
 
 int main() {
 // create model from json
 ADBook *book = [ADBook ad_modelWithJSON:@"{\"name\": \"Harry Potter\", \"pages\": 256, \"author\": {\"name\": \"J.K.Rowling\", \"birthday\": \"1965-07-31\" }}"];
 
 // convert model to json
 NSString *json = [book ad_modelToJSONString];
 // {"author":{"name":"J.K.Rowling","birthday":"1965-07-31T00:00:00+0000"},"name":"Harry Potter","pages":256}
 }
 
 ********************** Coding/Copying/hash/equal *********************
 @interface ADShadow :NSObject <NSCoding, NSCopying>
 @property (nonatomic, copy) NSString *name;
 @property (nonatomic, assign) CGSize size;
 @end
 
 @implementation ADShadow
 - (void)encodeWithCoder:(NSCoder *)aCoder { [self ad_modelEncodeWithCoder:aCoder]; }
 - (id)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self ad_modelInitWithCoder:aDecoder]; }
 - (id)copyWithZone:(NSZone *)zone { return [self ad_modelCopy]; }
 - (NSUInteger)hash { return [self ad_modelHash]; }
 - (BOOL)isEqual:(id)object { return [self ad_modelIsEqual:object]; }
 @end
 
 */
@interface NSObject (ADModel)

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
+ (nullable instancetype)ad_modelWithJSON:(id)json;

/**
 Creates and returns a new instance of the receiver from a key-value dictionary.
 This method is thread-safe.
 
 @param dictionary  A key-value dictionary mapped to the instance's properties.
 Any invalid key-value pair in dictionary will be ignored.
 
 @return A new instance created from the dictionary, or nil if an error occurs.
 
 @discussion The key in `dictionary` will mapped to the reciever's property name,
 and the value will set to the property. If the value's type does not match the
 property, this method will try to convert the value based on these rules:
 
 `NSString` or `NSNumber` -> c number, such as BOOL, int, long, float, NSUInteger...
 `NSString` -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd".
 `NSString` -> NSURL.
 `NSValue` -> struct or union, such as CGRect, CGSize, ...
 `NSString` -> SEL, Class.
 */
/**
 创建并返回一个新的列子通过参数的key-value字典
 这个方法是安全的
 参数:dictionary 一个key-value字典映射到列子的属性
 字典中任何一对无效的key-value都将被忽视
 返回一个新的粒子通过字典创建的，如果解析失败返回为nil
 描述:字典中的key将映射到接收者的property name
 而值将设置给这个Property，如果这个值类型与property不匹配
 这个方法将试图转变这个值基于这些结果:
 */
+ (nullable instancetype)ad_modelWithDictionary:(NSDictionary *)dictionary;
/**
 Set the receiver's properties with a json object.
 
 @discussion Any invalid data in json will be ignored.
 
 @param json  A json object of `NSDictionary`, `NSString` or `NSData`, mapped to the
 receiver's properties.
 
 @return Whether succeed.
 */
/**
 通过一个json对象设置调用者的property
 json中任何无效的数据都将被忽视
 参数：json 一个关于NSDictionary,NSString,NSData的json对象将映射到调用者的property
 返回：是否成功
 
 */
- (BOOL)ad_modelSetWithJSON:(id)json;

/**
 Set the receiver's properties with a key-value dictionary.
 
 @param dic  A key-value dictionary mapped to the receiver's properties.
 Any invalid key-value pair in dictionary will be ignored.
 
 @discussion The key in `dictionary` will mapped to the reciever's property name,
 and the value will set to the property. If the value's type doesn't match the
 property, this method will try to convert the value based on these rules:
 
 `NSString`, `NSNumber` -> c number, such as BOOL, int, long, float, NSUInteger...
 `NSString` -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-dd".
 `NSString` -> NSURL.
 `NSValue` -> struct or union, such as CGRect, CGSize, ...
 `NSString` -> SEL, Class.
 
 @return Whether succeed.
 */
/**
 通过一个key-value字典设置调用者的属性
 参数：dic  一个Key-Value字典映射到调用者property,字典中任何一对无效的Key-Value都将被忽视
 描述  dictionary中的Key将被映射到调用者的property name 而这个value将设置给property.
 如果value类型与property类型不匹配，这个方法将试图转换这个value基于以下这些值：
 返回  转换是否成功
 */
- (BOOL)ad_modelSetWithDictionary:(NSDictionary *)dic;
/**
 Generate a json object from the receiver's properties.
 
 @return A json object in `NSDictionary` or `NSArray`, or nil if an error occurs.
 See [NSJSONSerialization isValidJSONObject] for more information.
 
 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it just convert
 the inner object to json object.
 */
/**
 产生一个json对象通过调用者的property
 返回一个NSDictionary或NSArray的json对象，如果解析失败返回一个Nil
 了解更多消息观看[NSJSONSerialization isValidJSONObject]
 描述：任何无效的property都将被忽视
 如果调用者是NSArray,NSDictionary或NSSet,他将转换里面的对象为json对象
 */
- (nullable id)ad_modelToJSONObject;

/**
 Generate a json string's data from the receiver's properties.
 
 @return A json string's data, or nil if an error occurs.
 
 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it will also convert the
 inner object to json string.
 */
/**
 创建一个json string‘s data(json字符串二进制数据)通过调用者的property
 返回一个json string's data,如果解析失败返回为空
 描述：任何无效的property都将被忽视
 如果调用者是一个NSArray,NSDictionary或NSSet,它也将转换内部对象为一个Json字符串
 */
- (nullable NSData *)ad_modelToJSONData;

/**
 Generate a json string from the receiver's properties.
 
 @return A json string, or nil if an error occurs.
 
 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it will also convert the
 inner object to json string.
 */
/**
 创建一个json string通过调用者的property
 返回一个json string,如果错误产生返回一个nil
 描述 任何无效的property都将被忽视
 如果调用者是NSArray,NSDictionary或NSSet,它也将转换内部对象为一个json string
 */
- (nullable NSString *)ad_modelToJSONString;

/**
 Copy a instance with the receiver's properties.
 
 @return A copied instance, or nil if an error occurs.
 */
/**
 copy一个对象通过调用者的properties
 返回一个copy的对象，如果解析失败则返回为nil
 */
- (nullable id)ad_modelCopy;
/**
 Encode the receiver's properties to a coder.
 
 @param aCoder  An archiver object.
 将调用者property编码为一个Coder
 参数 aCoder 一个对象档案
 */
- (void)ad_modelEncodeWithCoder:(NSCoder *)aCoder;

/**
 Decode the receiver's properties from a decoder.
 
 @param aDecoder  An archiver object.
 
 @return self
 通过一个decoder解码成对象的property
 参数 aDecoder 一个对象档案
 返回 调用者自己
 */
- (id)ad_modelInitWithCoder:(NSCoder *)aDecoder;

/**
 Get a hash code with the receiver's properties.
 
 @return Hash code.
 通过调用者Property获取到一个哈希Code
 返回 hashCode
 */
- (NSUInteger)ad_modelHash;

/**
 Compares the receiver with another object for equality, based on properties.
 
 @param model  Another object.
 
 @return `YES` if the reciever is equal to the object, otherwise `NO`.
 比较这个调用者和另一个对象是否相同，基于property
 参数 model 另一个对象
 返回 如果两个对象相同则返回YES 否则为NO
 */
- (BOOL)ad_modelIsEqual:(id)model;

/**
 Description method for debugging purposes based on properties.
 
 @return A string that describes the contents of the receiver.
 描述方法为基于属性的Debug目的(Debug模式中基于属性的描述方法)
 返回一个字符串描述调用者的内容
 */
- (NSString *)ad_modelDescription;

@end



/**
 Provide some data-model method for NSArray.
 提供一些关于NSArray的data-model方法
 */
@interface NSArray (ADModel)

/**
 Creates and returns an array from a json-array.
 This method is thread-safe.
 
 @param cls  The instance's class in array.
 @param json  A json array of `NSArray`, `NSString` or `NSData`.
 Example: [{"name","Mary"},{name:"Joe"}]
 
 @return A array, or nil if an error occurs.
 
 通过一个json-array创建并返回一个数组
 这个方法是安全的
 
 参数:cls array中的对象类
 参数:json 一个json array 关于"NSArray","NSString"或"NSData"
 列子:[{"name","Mary"},{name:"Joe"}]
 返回一个数组,如果解析错误则返回nil
 */
+ (nullable NSArray *)ad_modelArrayWithClass:(Class)cls json:(id)json;

@end



/**
 Provide some data-model method for NSDictionary.
 提供一些data-model方法通过NSDictionary
 */
@interface NSDictionary (ADModel)

/**
 Creates and returns a dictionary from a json.
 This method is thread-safe.
 
 @param cls  The value instance's class in dictionary.
 @param json  A json dictionary of `NSDictionary`, `NSString` or `NSData`.
 Example: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}
 
 @return A dictionary, or nil if an error occurs.
 通过一个json文件创建并返回一个字典
 这个方法是安全的
 参数cls  字典中value的对象class
 参数json 一个json的字典是"NSDictionary","NSStirng"或"NSData"的
 列子: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}
 */
+ (nullable NSDictionary *)ad_modelDictionaryWithClass:(Class)cls json:(id)json;
@end



/**
 If the default model transform does not fit to your model class, implement one or
 more method in this protocol to change the default key-value transform process.
 There's no need to add '<ADModel>' to your class header.
 
 如果默认的model改变并符合你的model class，在这个协议里实现一个或更多的方法去改变默认的key-value修改过程
 这些不需要添加<ADModel>到你的头文件
 */
@protocol ADModel <NSObject>
@optional

/**
 Custom property mapper.
 定制属性元素
 
 @discussion If the key in JSON/Dictionary does not match to the model's property name,
 implements this method and returns the additional mapper.
 
 描述 如果JSON/Dictionary的key并不能匹配model的property name
 实现这个方法并返回额外的元素
 
 Example:
 
 json:
 {
 "n":"Harry Pottery",
 "p": 256,
 "ext" : {
 "desc" : "A book written by J.K.Rowling."
 },
 "ID" : 100010
 }
 
 model:
 @interface ADBook : NSObject
 @property NSString *name;
 @property NSInteger page;
 @property NSString *desc;
 @property NSString *bookID;
 @end
 
 @implementation ADBook
 + (NSDictionary *)modelCustomPropertyMapper {
 return @{@"name"  : @"n",
 @"page"  : @"p",
 @"desc"  : @"ext.desc",
 @"bookID": @[@"id", @"ID", @"book_id"]};
 }
 @end
 
 @return A custom mapper for properties.
 通过Property返回一个定制元素
 */
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

/**
 The generic class mapper for container properties.
 通过property容器获得自定义的class元素
 
 @discussion If the property is a container object, such as NSArray/NSSet/NSDictionary,
 implements this method and returns a property->class mapper, tells which kind of
 object will be add to the array/set/dictionary.
 描述:    如果这个property是一个对象容器，列如NSArray/NSSet/NSDictionary
 实现这个方法并返回一个属性->类元素,告知哪一个对象将被添加到这个array /set /dictionary
 
 Example:
 @class ADShadow, ADBorder, ADAttachment;
 
 @interface ADAttributes
 @property NSString *name;
 @property NSArray *shadows;
 @property NSSet *borders;
 @property NSDictionary *attachments;
 @end
 
 @implementation ADAttributes
 + (NSDictionary *)modelContainerPropertyGenericClass {
 return @{@"shadows" : [ADShadow class],
 @"borders" : ADBorder.class,
 @"attachments" : @"ADAttachment" };
 }
 @end
 
 @return A class mapper.
 返回一个对象元素
 */
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

/**
 If you need to create instances of different classes during json->object transform,
 use the method to choose custom class based on dictionary data.
 如果你需要在json->object的改变时创建关于不同类的对象
 使用这个方法基于dictionary data去改变custom class
 
 @discussion If the model implements this method, it will be called to determine resulting class
 描述 如果model实现了这个方法,他将被认为通知是确定的class结果
 
 during `+modelWithJSON:`, `+modelWithDictionary:`, conveting object of properties of parent objects
 (both singular and containers via `+modelContainerPropertyGenericClass`).
 在"+modelWithJson","+modelWithDictionary"期间，父对象包含的property是一个对象
 (两个单数的并经由`+modelContainerPropertyGenericClass`包含)
 
 Example:
 @class ADCircle, ADRectangle, ADLine;
 @implementation ADShape
 
 + (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
 if (dictionary[@"radius"] != nil) {
 return [ADCircle class];
 } else if (dictionary[@"width"] != nil) {
 return [ADRectangle class];
 } else if (dictionary[@"y2"] != nil) {
 return [ADLine class];
 } else {
 return [self class];
 }
 }
 
 @end
 
 @param dictionary The json/kv dictionary.
 参数 json/kv字典
 
 @return Class to create from this dictionary, `nil` to use current class.
 返回 通过字典创建的class,nil指使用当前class
 
 重写时通过判断哪个key对应的有Value值,就返回一个自己需求的类
 */
+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

/**
 All the properties in blacklist will be ignored in model transform process.
 Returns nil to ignore this feature.
 
 @return An array of property's name.
 
 在model变换时所有在黑名单里的property都将被忽视
 返回 一个关于property name的数组
 */
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;

/**
 If a property is not in the whitelist, it will be ignored in model transform process.
 Returns nil to ignore this feature.
 
 @return An array of property's name.
 
 如果一个property不在白名单，在model转变时它将被忽视
 返回nil忽视这方面
 
 返回 一个包含property name的数组
 */
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;

/**
 This method's behavior is similar to `- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;`,
 but be called before the model transform.
 这个方法行为是相似的与 "- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic"
 但在model转换前被调用的
 
 @discussion If the model implements this method, it will be called before
 `+modelWithJSON:`, `+modelWithDictionary:`, `-modelSetWithJSON:` and `-modelSetWithDictionary:`.
 If this method returns nil, the transform process will ignore this model.
 描述 如果model实现了这个方法,它将被调用在"+modelWithJson:","+modelWithDictionary:","-modelSetWithJSON:"and"-modelSetWithDictionary:"之前
 如果方法返回为nil,转换过程中将忽视这个model
 
 @param dic  The json/kv dictionary.
 参数 dic     json/kv 字典
 @return Returns the modified dictionary, or nil to ignore this model.
 返回     返回修改的字典，如果忽视这个model返回Nil
 
 */
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;

/**
 If the default json-to-model transform does not fit to your model object, implement
 this method to do additional process. You can also use this method to validate the
 model's properties.
 
 如果默认的json-to-model转换并不符合你的model对象,实现这个方法去增加额外的过程。
 你也可以使用这个方法使model的property生效
 
 
 @discussion If the model implements this method, it will be called at the end of
 `+modelWithJSON:`, `+modelWithDictionary:`, `-modelSetWithJSON:` and `-modelSetWithDictionary:`.
 If this method returns NO, the transform process will ignore this model.
 
 描述 如果model实现了这个方法,它将被调用在"+modelWithJSON:","+modelWithDictionary","-modelSetWithJSON:" and "-modelSetWithDictionary:"结束
 
 
 @param dic  The json/kv dictionary.
 
 参数 dic json/kv 字典
 
 @return Returns YES if the model is valid, or NO to ignore this model.
 
 返回 如果这个model是有效的,返回YES 或返回NO忽视这个model
 
 
 */
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

/**
 If the default model-to-json transform does not fit to your model class, implement
 this method to do additional process. You can also use this method to validate the
 json dictionary.
 
 如果默认的model-to-json转换并不符合你的model class,实现这个方法添加额外的过程。
 你也可以使用这个方法使这个json dictionary有效
 
 @discussion If the model implements this method, it will be called at the end of
 `-modelToJSONObject` and `-modelToJSONString`.
 If this method returns NO, the transform process will ignore this json dictionary.
 
 描述 如果这个model实现了这个方法,它将被调用在"-modelToJSONObject"和"-modelToJSONStrign"结束
 如果这个方法返回NO,这个转换过程将忽视这个json dictionary
 
 @param dic  The json dictionary.
 
 @return Returns YES if the model is valid, or NO to ignore this model.
 */
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
