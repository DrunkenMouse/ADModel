/**
 我的英文能力不够，所以我把作者提供的英文注释解析通过字典百度自己的理解等方法翻译后写下来，再对照自己的翻译与各方查询的资料来分析。若觉得不错，可否给颗star?你的支持将是我的动力。
 
 最近工作感觉压抑好大，若觉得不错，可否支持一下。。真的。。
 */

/**
 Json转Model：

 //mapped to 映射//列子 instancetype 通常也指实例
 
 只有解析，注释请下载后观看(麻烦下载前顺手star一下，你的支持将是我的动力！)，建议最好对比源码观看。
 
 由于内容过多，先只说下通过JSON创建并返回一个实例的解析
 
 +(instancetype)ad_modelWithJSON:(id)json:
 在其内部其实通过类方法[self _ad_dictionaryWithJSON:json]创建了一个字典，而后通过类方法[self ad_modelWithDictionary:dic]创建并返回所需的实例
 
 +(NSDictionary *)_ad_dictionaryWithJSON：(id)json
 类方法，自定义的实现方法并没有相应的方法声明，接收到Json文件后先判断Json文件是否为空，判断有两种方式 if (!json || json == (id)kCFNull)
 
 kCFNull: NSNull的单例，也就是空的意思那为什么不用Null、Nil或nil呢？
 
 以下为nil，Nil，Null，NSNull的区别
 
 Nil：对类进行赋空值
 
 ni：对对象进行赋空值
 
 Null：对C指针进行赋空操作，如字符串数组的首地址 char *name = NULL
 
 NSNull：对组合值，如NSArray，Json而言，其内部有值，但值为空
 
 所以判断条件json不存在或json存在，但是其内部值为空，就直接返回nil。若json存在且其内部有值，则创建一个空字典(dic)与空NSData(jsonData)值而后再判断，若json是NSDictionary类，就直接赋值给字典。
 
 若是NSString类，就将其强制转化为NSString，而后用UTF-8编码处理赋值给jsonData。
 
 若是NSData，就直接赋值给jsonData而后判断，而jsonData存在就代表json值转化为二进制NSData。
 
 用官方提供的JSON解析就可获取到所需的值赋值为dic。若发现解析后取到得值不是NSDictionary，就代表值不能为dict，因为不是同一类型值，就让dict为nil最后返回dict。
 
 在这个方法里相当于若JSON文件为NSDictionary类型或可解析成dict的NSData、NSString类型就赋值给dict返回，若不能则返回的dict为nil
 
 +(instancetype)ad_modelWithDictionary:(NSDictionary *)dictionary
 类方法，方法内部会先判断若字典不存在，或字典存在但值为空的情况下直接返回nil而后在判断若传过来的字典其实不是NSDictionary类型，则也返回nil。所以，到了下一步时就代表字典存在且值不为空，而且传过来的字典就是NSDictionary类型，则创建一个类Cls为当前调用方法的类，而后通过自定义方法[_ADModelMeta metaWithClass:Cls]将自身类传过去。
 
 _ADModelMeta为延展类实现方法里声明的类，metaWithClass:Cls方法为
 
 +(instancetype)metaWithClass:(Class)cls
 类方法，方法返回这个class元素，model缓存在方法内部，会先判断若cls不存在则返回nil而若存在，则创建三个静态属性:CFMutableDictionaryRef cache(static，静态修饰符，被static修饰的属性在程序结束前不会被销毁。CFNSMutableDictionaryRef，可变字符串底层，效率比其高).
 
 dispatch_semaphore_t  lock(同步信号量，一次执行里面让其值为1则wait时就会通过继续执行)，dispatch_once_t oncetoken（一次执行，配合dispatch_once使用，整个程序只会执行一次）一次执行中创建CFMutableDictionaryRef与dispatch_semaphore_create（1）
 
 其中CFMutableDictionary的创建中四个参数意义为： cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
 
 @功能 CFDictionaryCreateMutable创建一个新的词典。
 
 @参数 CFAllocator 分配器应该用于分配CFAllocator字典的内存及其值的存储。这 参数可能为空，在这种情况下，当前的默认值CFAllocator使用。如果这个引用不是一个有效的cfallocator，其行为是未定义的。这里是内存及其值的存储为默认。
 
 @参数 capacity 暗示值得个数，通过0实现可能忽略这个提示，或者可以使用它来优化各种。这里是忽略。
 
 @参数 keyCallBacks 指向CFDictionaryKeyCallBacks结构为这本字典使用回调函数初始化在字典中的每一个键，初始化规则太多而且看的有点迷糊就不多说了，毕竟不敢乱说。意思应该是对键值对中的键进行初始化，并有相应的优化方式。
 
 @参数 valueCallBacks 指向CFDictionaryValueCallBacks结构为这本词典使用回调函数初始化字典中的每一个值。对键值对中的值进行初始化，并有相应地优化方式。
 一次执行之后通过wait判断可否继续执行，由于Create值为1所以可通行一次，此时在CF字典cache中获得值不可变的函数指针cls对应的值_ADModelMeta *meta(const 值不可被更改，void * 函数指针，通过__bridge桥接转换)而后通过signal操作让lock锁的信号加1，再去执行判断语句。
 
 判断内容为若meta不存在，或meta存在但其属性classInfo(ADClassInfo *类型)的needUpdate为YES代表meta需要更新或存储，则通过_ADModelMeta对象方法(instancetype)initWithClass:(Class)cls 获取一个实例。
 
 -(instancetype)initWithClass:(Class)cls
 方法内，会先通过[ADClassInfo classInfoWithClass:(Class)cls]获取到cls的信息而在[ADClassInfo classInfoWithClass:(Class)cls]方法内部，又会先去判断Cls是否存在，若不存在返回nil若存在，则创建两个CFMutableDictionaryRef（metaCache与classCache）与一个一次执行，一个同步信号量。
 
 而后通过一次执行初始化两个CFMutableDictionaryRef与同步信号量的初始化创建完毕后会先判断同步信号量，由于初始化有值则减一后继续执行此时创建一个ADClassInfo *info用于保存通过CFDictionaryGetValue获取到的Class信息。
 
 其中class_isMetaClass判断指定类是否是一个元类
 
 元类是类对象的类，如[NSArray array]中的NSArray也是一个对象,NSArray通过元类生成,而元类又是一个对象，元类的类是根源类NSObject,NSObject父类为Nil
 如果是元类则存储在metaCache中，所以也是从其中取值，如果不是就存储在classCache中也就是从classCache中取值，通过一个不可变的函数指针cls取值而后同步信号量加1 若取得到信息info则直接返回，若取不到就借助[[ADClassInfo alloc] initWithClass:cls];去获取Info。
 
 [[ADClassInfo alloc] initWithClass:cls] 私有方法，未在.h文件中声明在此方法中会先判断传过来的cls是否存在，若不存在返回nil若存在，就先通过父类初始化一次并保存传过来的_cls = Cls,与Cls的父类(_superCls = class_getSuperclass(cls)获取父类)以及Cls是否为元类的Bool值( _isMeta =  class_isMetaClass(cls))，若不是元类则获得其元类并保存(_metaCls = objc_getMetaClass(class_getName(cls)))，以及类的名字(_name = NSStringFromClass(cls))而后调用一次_update方法。
 
 在update方法里会先对ivarInfos(ivars）methodInfos(methods) propertyInfos(properties)三个属性初始化，ivars属性，methods方法，properties属性操作并临时保存self.cls(之前刚赋值)。
 
 声明一个 保存 方法描述的数组指针 长度值 methodCount。 Method *methods = class_copyMethodList(cls, &methodCount);返回关于对象方法描述的一个数组指针，数组长度保存在methodCount地址里。
 
 如果指针存在，就创建一个NSMutableArray字典存储方法，并保存此字典_methodInfos = methodInfos; 而后再通过自定义方法[[ADClassMethodInfo alloc] initWithMethod:methods[i]]；通过传过来的方法返回一个实例-(instancetype)initWithMethod:(Method)method通过传过来的方法返回一个实例。
 
 在此方法里会先判断方法是否存在，若不存在返回nil，若存在则保存方法method，与方法操作SEL(method_getName(method))，方法实现IMP(method_getImplementation(method))，方法操作的名字( const char *name =sel_getName(_sel)，返回值是一个值不可变的字符指针name，字符指针通常指向一个字符数组的首地址，字符数组类似于字符串) 。
 
 若取得到名字则将方法名用UTF-8编码后保存。方法参数和返回值类型(method_getTypeEncoding(method))若取得到通过UTF-8编码后保存。方法的返回值类型(method_copyReturnType(method))若取得到则通过UTF-8编码后保存。
 
 方法的参数个数(method_getNumberOfArguments(method))若个数大于0，则创建一个可变数组，而后去遍历获取参数类型(method_copyArgumentType(method, i)获取方法的指定位置参数的类型字符串)，若获取到的参数类型存在就通过UTF-8编码后获取，不存在就为nil，而后保存到可变数组里，若有值则存储，没有值用@“”代替，存储后若获取到的参数类型存在就free释放其内存，全部获取后保存此数组。
 
 最后将保存好信息的self返回此时回到_update方法里，已经通过对象获得到一个方法的描述信息，判断方法名(name，方法操作的名字)是否有值,如有值则以此为key，对象为值存储在可变字典methodInfos里，而methodInfos之前已经被保存。没有自然就不存了。
 
 全部存储完毕后释放methods内存(之前获取的关于对象方法描述的一个数组指针)。获取到数组后，去获取cls的属性。同理，先通过class_copyPropertyList获取到属性个数存储在一个unsigned int(无符号整型)值中，再获取属性描述properties,如果有属性则属性描述有值。
 
 此时创建并保存一个可变字典，而后遍历属性，并将遍历时的属性通过[[ADClassPropertyInfo alloc] initWithProperty:properties[i]];封装成一个ADClassPropertyInfo对象，以属性名为Key属性，对象为值存储在字典里存储完后释放属性描述内存。
 
 -(instancetype)initWithProperty:(objc_property_t)property
 方法中，依旧是先判断后保存，保存了传过来的属性,属性的名称，属性的特性列表指针objc_property_attribute_t *(通常代表其是一个数组，一个结构体包含一个name属性的描述，一个value属性值)，而后遍历此指针指向的数组开始一个一个取值保存在新建的objc_property_attribute_t中。
 
 若取出来的name皆是以T开头后面跟随属性类型如字典，属性是强弱指针（如&为强指针，空为Value）原子性非原子性（空为atomic，N为nonatomic），变量名称，使用UTF-8编码后保存。
 
 在使用自定义C语言函数结构体objc_property_attribute_t中的name与Value：
 结构体中的name与Value：
 
 属性类型  name值：T  value：变化
 
 编码类型  name值：C(copy) &(strong) W(weak) 空(assign) 等 value：无
 
 非/原子性 name值：空(atomic) N(Nonatomic)  value：无
 
 变量名称  name值：V  value：变化
 属性描述为 T@"NSString",&,V_str 的 str
 
 属性的描述：T 值：@"NSString"
 
 属性的描述：& 值：
 
 属性的描述：V 值：_str2
 
 
 ADEncodingGetType(返回值为ADEncodingType，接收参数为不可变的字符数组typeEncoding)转换value值。
 
 在ADEncodingGetType中，先用可变字符数组type保存传过来的Value值，若值不存在则返回自定义枚举ADEncodingTypeUnknown，若有值则获取type长度，若长度为0仍旧返回Unknown，若长度不为0则声明一个枚举值qualifier，在设置一个值为true的Bool值用于死循环，在死循环内部从字符数组type的首地址开始一个一个取出内部的字符，若满足要求则让qualifier进行位运算(1 | 0 = 1, 1 | 1 = 0)而后指针+1指向下一个值，当值不满足任何条件跳出while循环。
 
 再获取剩余字符数组长度，若长度为0则或运算Unknow，若不是则判断此时的内部为哪种类型与qualifier进行或运算后返回，若为@类型即为block或Object类型，长度为2以？结尾则是Block否则就是Object，如果类型不可知则返回qualifier与Unknow或运算值。
 
 返回值之前的switch选择中，此时我们得到了value的类型与修饰符类型（如不可变的int16类型），再去判断若Value有值，其类型又是Object类型，则使用NSScanner（条件判断）获取字符串通过scanString:intoString:判断值是否包含NULL
 
 @\”中 \”转义符，转义成“ 所以值为@“，从@“开始遍历若找到NULL则返回YES
 不包含结束此次循环。若包含则创建一个空字符串clsName，而后通过NSCharacterSet（一组Unicode字符，常用与NSScanner，NSString处理）转换字符串@“\“<”再通转换后的NSCharterSet扫描scanner中是否包含转换后的对象，若包含则将传入的字符串指向的遇到charterSet字符之前内容的指针保存到&clsName地址中。
 
 此时的&clsName代表字符串头地址的地址，存储后若地址中有值，则将值通过UTF-8编码处理后，通过objc_getClass获取到其isa保存(objc_getClass来获取对象的isa，isa是一个指针指向对象自身)而后再声明一个空的可变数组，用于获取字符串中从“<”到“ >”中的内容，保存在新建的字符串protocol中，若有内容且之前的空数组没有值（不明白为何多这一步）则添加字符串给可变数组，至此，属性名为T的操作就结束了。
 
 若name属性名为V代表是值名称（如字符串Str，V的值Str），直接使用UTF-8编码后保存R代表属性为只读属性，则让type或运算ADEncodingTypePropertyCopyC为Copy，&为Reatin（引用计数加一，形同强指针）
 
 N为nonatomic，D为Dynamic(@dynamic ,告诉编译器不自动生成属性的getter、setter方法)
 
 W为weak，G为getter方法，S为setter方法
 
 获取到属性后释放属性的特性列表，保存已获取的type值，若属性名称存在而属性的getter、setter方法没有获取就通过属性名称获取，至此属性列表获取完毕。
 
 接下来就是获取成员变量了（成员变量与属性的操作区别在于：成员变量{}中声明的, 属性@property声明的），这个比较简单。
 
 先获取成员变量列表、个数，若列表有值则声明一个可变字典并保存，而后通过自定义方法[[ADClassIvarInfo alloc] initWithIvar:ivars[i]]；获取成员变量。
 
 -(instancetype)initWithIvar:(Ivar)ivar
 方法里，依旧先判断传过来的是否为空，而后保存传过来的ivar，获取成员变量名(ivar_getName(ivar))，获取得到通过UTF-8编码后保存，在获取成员变量首地址的偏移量(ivar_getOffset(ivar))，runtime会计算ivar的地址偏移来找ivar的最终地址，获取成员变量类型编码（ivar_getTypeEncoding(ivar)），若获取得到通过UTF-8编码后保存，而后再通过自定义C函数ADEncodingGetType获取type值(之前已经描述)。
 
 至此，方法method，属性property，成员变量ivar全部获取。
 
 获取后判断若不存在就赋空值，将_needUpdate赋值为NO回到-(instancetype)initWithClass:(Class)cls方法中，更新结束后通过自定义方法[self.class classInfoWithClass:_superCls]获取父类信息并保存，而后返回self此时回到classInfoWithClass，此时已经获得Cls的info信息。
 
 若获得到info信息就执行一次同步信号灯wait操作，而后通过info.isMeta判断Cls是否为元类来存储Cls的info，元类存储在metaCache中，非元类存储在classCache中，存储后让线程同步信号灯加1返回info。
 
 为什么加1？因为下次进入方法后要通过wait，然后才能通过静态可变CF字典取值。
 此时回到initWithClass，获取到Cls的信息，如果信息不存在返回nil，存在就先通过父类初始化一次，而后判断并获取白名单，黑名单里的的属性。再定义一个可变字典genericMapper用于获取自定义Class中包含的集合属性。
 
 先让Cls执行方法modelContainerPropertyGenericClass（若方法存在执行， 描述:    如果这个property是一个对象容器，列如NSArray/NSSet/NSDictionary  实现这个方法并返回一个属性->类mapper,告知哪一个对象将被添加到这个array /set /）获取返回回来的字典（如：@"shadows" : [ADShadow class]，由用户书写）
 
 若字典有值则再声明一个可变字典tmp，而后通过Block遍历字典genericMapper，若字典Key不是字符串类型返回,若是字典则获取Key对应值的类，获取不到则返回，获取到后判断是否是元类，如果是元类则tmp字典以genericMapper的key为自身key，以genericMapper的value为自身value，如果不是元类而是字符串类，则以此字符串创建一个类（NSClassFromString(obj)）。
 
 若创建成功则以以genericMapper的key为自身key，以创建的类为自身value，遍历完后保存genericMapper为tmp。而后创建所有的porperty元素，先取得classInfo,如果classInfo存在并且父类不为空（预先解析父类,但忽视根类(NSObject/NSProxy)）。
 
 而后遍历curClassInfo.propertyInfos.allValues(curClassInfo的字典属性propertyInfos的所有值)保存在ADClassPropertyInfo * propertyInfo中，若propertyInfo.name不存在 或黑名单存在且黑名单包含propertyInfo.name  或白名单存在且白名单不包含propertyInfo.name  则结束当前循环。
 
 随后通过自定义方法[_ADModelPropertyMeta metaWithClassInfo:classInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]]获取model对象中的property信息。
 
 + (instancetype)metaWithClassInfo:(ADClassInfo *)classInfo propertyInfo:(ADClassPropertyInfo *)propertyInfo generic:(Class)generic
 方法下次在描述，感觉本文已经写得实在有点多，总之就是通过此获取到model对象中的property信息，包括getter、setter方法，可否使用KVC，可否归档解档，以及Key、keyPath、keyArray映射等。
 
 回到initWithClass方法，若获取到model对象中的property信息meta不存在，或meta->_name（成员变量不支持点语法）不存在，或meta->_getter、meta->_setter不存在或已保存在字典allPropertyMetas中就结束当前循环，若都不满足则保存在字典allPropertyMetas中。遍历结束后保存curClassInfo为其父类，而后再while循环直至根类while结束后若allPropertyMetas有值则保存，而后创建一个可变字典，两个可变数组。通过modelCustomPropertyMapper方法实现定制元素
 
 + (nullable NSDictionary*)modelCustomPropertyMapper;
 定制属性元素，描述 如果JSON/Dictionary的key并不能匹配model的property name，实现这个方法并返回额外的元素。
 
 先去判断能否响应这个方法，如果能，就创建一个字典，声明是NSDictionary，但是实现时是自定义属性映射字典，相当于响应了这个方法返回值赋值给字典customMapper，而后Block遍历次字典，通过之前存储的allPropertyMetas字典取出对应Key的值赋值给propertyMeta，若取不出则直接return，若取得出则allPropertyMetas删除Key与Key对应的值
 
 而后判断customMapper中的Value是否属于NSString类型，若属于但长度为0则return，否则保存在propertyMeta中，随后以"."分割字符串为一个数组keyPath	，而后遍历数组，若遍历时的字符串长度为0，则创建一个临时数组保存keyPath移除@“”对象而后再赋值给KeyPath。遍历结束后，若此时KeyPath的Count大于1，则保存在propertyMeta中，并将propertyMeta保存在之前新建的可变数组keyPathPropertyMetas中，随后判断mapper[mappedToKey]（mapper，之前创建的用于映射的可变字典）是否有值，没有则赋值空，有就赋值给propertyMeta的_next，而后保存propertyMeta。
 
 若值是NSArray类型，则将其强转成NSArray类型而后字符串oneKey遍历，遍历前创建一个可变数组mappedToKeyArray，如果遍历时oneKey不是字符串或长度为0则结束此次遍历，如果都不符合则通过“。”分割成一个数组，若数组的数量大于1则保存数组否则保存oneKey，而后判断若propertyMeta->_mappedToKey不存在则保存其为oneKey，如果数组数量大于1则保存_mappedToKeyPath为数组，若保存失败则return，随后保存mappedToKeyArray为_mappedToKeyArray等。
 
 处理完定制属性之后再去遍历保存的所有Property元素的可变字典allPropertyMetas，保存字典的Value值的成员变量并保存Value值 为mapper[name]，若保存成功则保存mapper,而后保存classInfo,所有property元素的个数，通过自定义强制内联方法ADClassGetNSType保存Cls的类型，而后保存几个用户自定义方法的返回值，代码中有详细文档翻译。而后返回self，就此initWithClass方法结束。
 
 此时返回到metaWithClass中，我们已经获取了需要的meta，若获取成功则线程信号量wait一次操作，并设置其值到缓存中，随后信号量加1返回Meta.
 
 此时返回到ad_modelWithDictionary方法中，我们已经获取了modelMeta，若其_hasCustomClassFromDictionary值为YES就让Cls执行一次+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;（通过字典创建的class,nil指使用当前class，用户自定义的方法），而后通过Cls创键一个对象one,让One执行方法-(BOOL)ad_modelSetWithDictionary:(NSDictionary *)dic ; 若执行成功返回one否则为nil
 
 -(BOOL)ad_modelSetWithDictionary:(NSDictionary *)dic ; 
 这个方法也是下次在解说吧
 
 至此Json转Model分析完毕。撒花~~~~~~~~
 
 */

 /*
  //meta 元素
  + (instancetype)metaWithClassInfo:(ADClassInfo *)classInfo propertyInfo:(ADClassPropertyInfo *)propertyInfo generic:(Class)generic
  support pseudo generic class with protocol name
  支持假的generic class通过协议名
  generic class自己写的类
  如果generic不存在(genericMapper[propertyInfo.name])且PropertyInfo.protocols存在
  遍历propertyInfo信息的所有protocols,将其通过UTF-8编码后转换为class类型
  若转换成功则generic值为此类，结束遍历
  创建一个_ADModelPropertyMeta 对象meta，用于保存propertyInfo里的name、type、propertyInfo自身与generic
  如果meta ->_type是object类型，就通过自定义方法ADClassGetNSType根据propertyInfo.cls设置meta->_nsType值，否则就通过ADEncodingTypeIsCNumber根据meta->_type设置meta->_isCNumber值
  如果meta->_type是一个ADEncodingTypeStruct类型值，声明一个NSSet对象，一个一次执行。
  一次执行内部创建一个NSMutableSet *set集合添加了32位与64位下的size、point、Rect、AffineTransform、EdgeInsets、Offset值类型并设置给types
  而后判断若types包含propertyInfo.typeEncoding则设置meta->_isStructAvailableForKeyedArchiver = YES
  保存propertyInfo.cls为meta->_cls
  如果generic有值或meta->_cls有值并且meta->_nsType是NSUnknown类型，就保存meta->_hasCustomClassFromDictionary值为响应是否成功。
  其余部分千篇一律，没啥好说的。其中instancesRespondToSelector： 是判断类的实例对象能否响应方法，如果能就保存相应的操作。如果meta->_getter与_setter都存在就判断meta->_type是否为可KVC操作的类型。 最后返回meta。
  —(BOOL)ad_modelSetWithDictionary:(NSDictionary *)dic
  通过一个key-value字典设置调用者的属性
  参数：dic  一个Key-Value字典映射到调用者property,字典中任何一对无效的Key-Value都将被忽视
  描述  dictionary中的Key将被映射到调用者的property name 而这个value将设置给property.
  如果value类型与property类型不匹配，这个方法将试图转换这个value基于以下这些值：
  返回  转换是否成功
  Json转Model最后一步所调用的方法中的最后一步，现在我们就来解析一下。
  内部会先判断若字典不存在，或字典内部值为空则返回NO
  如果字典存在且内部有值但不是字典类型也返回NO
  于是就确定字典存在且内部有值属于NSDictionary类型，则先去获取model类的元素缓存通过 [_ADModelMeta metaWithClass:object_getClass(self)]；临时存储在modelMeta中
  如果modelMeta中的keyMappedCount为0代表缓存的元素数为0则返回NO
  如果自身有响应方法_hasCustomWillTransformFromDictionary(在model转换前被命名,返回修改的字典)，就让自身的代理去响应此方法，将字典传过去并将返回值覆盖自身，如果覆盖后字典不是NSDictionary类型就返回NO
  创建一个结构体ModelSetContext，初始化是0，内部存储有三个函数指针，分别代表modelMeta(模型元素)，model(自身)，dictionary(字典dic)
  如果modelMeta中存储的_keyMappedCount大于等于dic中值的个数
  就执行 CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
  这里需要讲下这个CFDictionaryApplyFunction的作用及其三个参数
  CFDictionaryApplyFunction 对所有键值执行同一个方法
  @function CFDictionaryApplyFunction调用一次函数字典中的每个值。
  @param 字典。如果这个参数不是一个有效的CFDictionary,行为是未定义的。
  @param 调用字典中每一个值执行一次这个方法。如果这个参数不是一个指针指向一个函数的正确的原型,行为是未定义的。
  @param 一个用户自定义的上下文指针大小的值，通过第三个参数作用于这个函数，另有没使用此函数的。如果上下文不是预期的应用功能，则这个行为未定义。
  第三个参数的意思，感觉像是让字典所有的键值去执行完方法后，保存在这个上下文指针(如自定义结构体)的指针(指向一个地址，所以自定义的结构体要用&取地址符)所指向的地址，也就是自定义的结构体中。
  也就是dic里面的键值对全部执行完参数2的方法后保存在参数3中。
  其中参数2是自定义方法ModelSetWithDictionaryFunction，关于此方法
  static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void * _context)
  对于字典的函数应用，设置key-value配对给model
  参数 _key        不应该是nil,NSString
  参数 _value      不应该是nil
  参数 _context    _context.modelMeta 和 _context.model 不应该是nil
  表示是一个静态的无返回值的C函数，接收参数为不可变的函数指针key，不可变的函数指针value，不可变的函数指针_context
  方法内部会先声明一个ModelSetContext结构体指针context保存传过来的_context
  方法中用到了很多__unsafe__unretained修饰符。
  __unsafe_unretained 指针所指向的地址即使已经被释放没有值了，依旧会指向，如同野指针一样，weak/strong这些则会被置为nil。一般应用于iOS 4与OS X  Snow Leopard(雪豹)中，因为iOS 5以上才能使用weak。
  __unsafe_unretained与weak一样，不能持有对象，也就是对象的引用计数不会加1
  unsafe_unretained修饰符以外的 strong/ weak/ autorealease修饰符保证其指定的变量初始化为nil。同样的，附有 strong/ weak/ _autorealease修饰符变量的数组也可以保证其初始化为nil。
  autorealease(延迟释放,给对象添加延迟释放的标记,出了作用域之后，会被自动添加到"最近创建的"自动释放池中)
  为什么使用unsafe_unretained?
  作者回答：在 ARC 条件下，默认声明的对象是 strong 类型的，赋值时有可能会产生 retain/release 调用，如果一个变量在其生命周期内不会被释放，则使用 unsafe_unretained 会节省很大的开销。
  网友提问： 楼主的偏好是说用unsafe_unretained来代替weak的使用，使用后自行解决野指针的问题吗？
  作者回答：关于 unsafe_unretained 这个属性，我只提到需要在性能优化时才需要尝试使用，平时开发自然是不推荐用的。
  以下就简称un。
  将context中的modelMeta通过桥接转化为ADModelMeta对象并用un修饰的_ADModelMeta对象meta保存。
  将传过来的函数指针Key通过桥接转换为id对象并以此为Key，通过meta—>__mapper 取出key对应的值保存在un修饰的_ADModelPropertyMeta对象中。
  将context中的model通过桥接转换为id对象并保存在一个un修饰的id对象model中
  然后以propertyMeta为while判断条件，若其存在则为真，如果其存在并且存储有_setter方法，则通过自定义静态函数方法ModelSetValueForProperty取出model中其对应的value值。
  static void ModelSetValueForProperty方法，接收三个参数，__unsafe_unretained id model,
  __unsafe_unretained id value, __unsafe_unretained _ADModelPropertyMeta *meta
  如果传过来的property是C类型，就通过自定义方法ADNSNumberCreateFromID分析出一个数值。
  ADNSNumberCreateFromID一个静态的force_inline（代码中有解释，内容过多不赘述）修饰的返回值为NSNumber指针(意义通常为NSNumber对象，再加一个指针就是NSNumber对象数组)，参数为__unsafe_unretained id value
  方法内部声明了三个属性，一个NSCharacterSet(Unicode字符，常用于NSString、NSScanner处理)，一个字典，一个一次执行
  在一次执行内部，NSCharacterSet通过Range初始化，dic初始化中将正确、不正确、空的常用类型都进行了封装。
  而后判断若传过来的value不存在，或value为空返回nil，若value为NSNumber类型则直接返回value，若是NSString类型则先创建一个NSNumber *num初始化为dic[value]，先判断取出的值是否为NO，若是则再判断取出的值是否为空，如果是则返回nil，如果不是则直接返回num，num应为@(YES)即为1。
  而若num值为NO，则将value强转为NSString类型，然后通过刚才定义的dot在其内部查询字符 ‘  .  ’ 若查询得到则创建一个值不可变的字符数组接收强转后并UTF-8编码后的value值。
  如果强转后没有值则返回nil，如果有值则atof处理(将字符数组转化为数字，而字符串需要UTF-8编码后才能转为字符数组。其实字符串可以直接doubleValue转换，但大神用这种方法应该是效率快吧)
  若处理后的结果num，使用isnan(值是无穷大或无穷小的不确定值)或isinf(值是无限循环)判断，若有一个成立返回nil，否则将num包装成一个对象返回。
  如果不包含，则直接将value通过UTF-8编码成一个字符数组，若编码后没值则返回nil 有值就通过atoll转换后返回( long long atoll(const char *nptr); 把字符串转换成长长整型数（64位）)
  如果value不是NSNumber也不是NSString类型就直接返回nil
  回到函数ModelSetValueForProperty中，我们已经获取了num值，而后调用自定义静态内联无返回值的函数ModelSetNumberToProperty
  函数ModelSetNumberToProperty (__unsafe_unretained id model, __unsafe_unretained NSNumber *num, __unsafe_unretained _ADModelPropertyMeta *meta)
  设置数字给property
  描述 调用者(caller 来访者)应对这个参数保持强引用在这个函数返回之前
  参数 model 不应该是nil
  参数 num 可以是nil
  参数 meta 不应该是nil，meta.isCNumber应该是YES,meta.setter不应该是Nil
  方法内部使用了大量的objc_msgSend，这里简单说下
  objc_msgSend OC消息传递机制中选择子发送的一种方式，代表是当前对象发送且没有结构体返回值
  选择子简单说就是@selector()，OC会提供一张选择子表供其查询，查询得到就去调用，查询不到就添加而后查询对应的实现函数。通过_class_lookupMethodAndLoadCache3(仅提供给派发器用于方法查找的函数)，其内部会调用lookUpImpOrForward方法查找，查找之后还会有初始化枷锁缓存之类的操作，详情请自行搜索，就不赘述了。
  这里的意思是，通过objc_msgSend给强转成id类型的model对象发送一个选择子meta，选择子调用的方法所需参数为一个bool类型的值num.boolValue
  再通俗点就是让对象model去执行方法meta->_setter,方法所需参数是num.bollValue
  再通俗点：((void (*)(id, SEL, bool))(void *) objc_msgSend) 一位一个无返回值的函数指针，指向id的SEL方法，SEL方法所需参数是bool类型，使用objc_msgSend完成这个id调用SEL方法传递参数bool类型，(void *)objc_msgSend为什么objc_msgSend前加一个(void *)呢？我查了众多资料，众多。最后终于皇天不负有心人有了个结果，是为了避免某些错误，比如model对象的内存被意外侵占了、model对象的isa是一个野指针之类的。要是有大牛能说明白，麻烦再说下。而((id)model, meta->_setter, num.boolValue）则一一对应前面的id,SEL,bool
  再通俗点。。你找别家吧。。
  switch遍历meta->_type，如果是ADEncodingTypeBool类型，就让model对象执行方法meta—>_setter，将num.boolValue作为参数发送过去。
  如果是Int8类型就让对象执行方法meta—>_setter，将num.charValue强转为(int8_t)类型发过去
  如果是UInt8(无符号的Int8类型)同上，其余同上一直到Int64类型，为什么？因为int64代表此时的num值特别长，长到你需要判断一下传过来的num值是不是NSDecimalNumber类型(NSDecimalNumber数字精确，其值确定后不可修改，是NSNumber的子类)
  如果是float、double、long double类型，在对num得值转换后需要判断其是否是无穷大或无穷小或无限循环的，如果是就令值为0再去执行同样的操作
  如果num有值就创建一个[num class]用来保存这个num
  如果meta不是C number类型，就判断是否为meta—>_nsType是否有值，如果有值就判断value是否为空值，空值就调用objc_msgSend，传参数为nil，否则就Switch判断meta—>_nsType值。
  如果是NSString或NSMutableString类型就判断value是否为NSString类型，如果是就再判断meta—>_nsType是否为NSString类型，如果都是则调用objc_msgSend将value作为参数发过去，如果meta—>_nsType不是则将其value强转成NSString再.mutableCopy后作为参数发过去。
  如果Value不是则依次判断是否为NSNumber、NSData、NSURL或NSAttributedString，如果满足则在判断meta—>_nsType是否为ADEncodingTypeNSString，如果是就value转换相应的值后作为参数传递，如果不是就多进行一步.mutableCopy操作，NSData是个例外。
  meta—>_nsType如果是ADEncodingTypeNSValue、ADEncodingTypeNSNumber、ADEncodingTypeNSDecimalNumber，则依旧是判断meta—>_nsType类型，难点已经描述，这些就是千篇一律了。如果meta—>_nsType没有值就声明一个Bool值isNull保存value是否为kCFNull的结果，而后switch遍历meta—>_type枚举值。
  其中说一下strcmp(比较两个字符串)
  strcmp(const char string1, const char string2);
  比较字符串string1和string2大小.
  返回值< 0, 表示string1小于string2;
  返回值为0, 表示string1等于string2;
  返回值> 0, 表示string1大于string2.
  方法结束返回到ModelSetWithDictionaryFunction，while循环中会不变的通过propertyMeta = propertyMeta—>_next改变propertyMeta的值直至为空跳出while循环则此时方法结束。
  回到ad_modelSetWithDictionary中会发现余下的操作也是一样的。
  于是此方法结束，至此son转Model结束。
  怎么样，是不是还有点迷？还有点乱？好像自己还什么都不理解一样？
  没事，自己穿针引线多来几回就行了。我平常学习一个动画效果有时候都要好几个来回，更何况YYModel这种大作、只是再一次来回时你会感受到，什么叫一马平川仿似行云流水。
  
  */





















