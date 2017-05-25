//
//  ViewController.m
//  test-paixu
//
//  Created by 姜维克 on 2017/2/20.
//  Copyright © 2017年 O2O_iOS_jiangweike. All rights reserved.
//
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define RectMacro(image) CGRectMake((kScreenWidth - image.size.width) * 0.5, (kScreenHeight - image.size.height) * 0.5, image.size.width, image.size.height)
#import "ViewController.h"
#import "UIImage+Extension.h"
#import "JWKContactModel.h"
#import "JWKContactManager.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSDictionary *dic;
@property (nonatomic,strong) UIImageView *demoImage;
@property (nonatomic ,strong) NSArray * keys;
/** correctPinYin */
@property (nonatomic, strong) NSDictionary *correctPinYin;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *stringsToSort=[NSArray arrayWithObjects:
                            @"李白",
                            @"张三",@"啊",@"哦",@"呃",@"萝卜",@"卜",@"bo",@"Bo",@"卜吧",
                            @"李白2",@"李bai",@"李白说",@"libaishuo",
                            @"网轮",@"忘仑",@"网动",@"理dong没",@"离东没",
                            @"重庆",@"重量",@"汪伦",@"王伦",@"粒冬",@"网东",
                            @"调节",@"调用",@"忘轮",@"忘伦",@"理dong",@"网冬",
                            @"小白",@"小明",@"千珏",@"力冬",@"离冬",@"李动",
                            @"lidon2",@"lidon?",@"lidon😆",@"li😆",
                            @"黄家驹", @"鼠标",@"hello",@"多美丽",@"肯德基",@"##",
                            @"李东",@"LiDONG",@"林夕",@"李鹏",@"立冬",@"李东2",@"lidong",@"lidon1",@"lidon!",@"LIdong",@"李dong",
                            @"#?",@"2",@",,",@"😆",@"!",@"丽冬",
                            nil];
    
    NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:stringsToSort.count];
    
    
    for (NSString *str in stringsToSort) {
       NSString *pinYin = [self firstCharactor:str];
        NSLog(@"str:%@----pinYin:%@",str,pinYin);
    }
    
    for (NSString *name in stringsToSort) {
        JWKContactModel *model = [[JWKContactModel alloc] init];
        model.name = name;
        model.familyName = name;
        [contacts addObject:model];
    }
    
//    [self seperateContactsToGroup:contacts completion:^(NSMutableDictionary *contactsInGroup) {
//        
//        NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:contactsInGroup.allKeys.count];
//        NSArray *keys = [self sortedKeyInGroup:contactsInGroup];
//        
//        for (NSString *key in keys) {
//            NSLog(@"key是:%@\n",key);
//            [mArr addObject:contactsInGroup[key]];
//            for (JWKContactModel *model in contactsInGroup[key]) {
//                NSLog(@"model.name :%@",model.name);
//            }
//            NSLog(@"key是:%@\n",key);
//        }
////
//        self.sSort = [NSMutableArray arrayWithArray:mArr];
//        
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self.tableView reloadData];
//        });
//        
//    }];
    
    
    [[JWKContactManager shareManager] seperateContactsToGroup:contacts completion:^(NSMutableDictionary *contactsInGroup) {
        [contactsInGroup enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSMutableArray * obj, BOOL * _Nonnull stop) {
            [[JWKContactManager shareManager] sortContacts:obj];
        }];
        self.dic = contactsInGroup;
        self.keys = [self.dic.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}


- (NSArray *)sortGroupWithArray:(NSArray *)ary
{
    NSStringCompareOptions options = NSCaseInsensitiveSearch|NSNumericSearch|NSWidthInsensitiveSearch|NSForcedOrderingSearch;
    NSComparator sort = ^(NSString *obj1, NSString *obj2){
        NSRange range = NSMakeRange(0, obj1.length);
        return [obj1 localizedCompare:obj2];
    };
    NSArray *tempArr = [ary sortedArrayUsingComparator:sort];
    return tempArr;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.keys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString * key = self.keys[section];
    return [self.dic[key] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *Cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    Cell.contentView.backgroundColor = [UIColor clearColor];
    Cell.backgroundColor = [UIColor clearColor];
    NSString * key = self.keys[indexPath.section];
    JWKContactModel *model = [self.dic[key] objectAtIndex:indexPath.row];
    Cell.textLabel.text = model.name;
    return Cell;
}


///姓名分组
-(void)seperateContactsToGroup:(NSArray *)contacts completion:(void(^)(NSMutableDictionary * contactsInGroup))completion {
    if (!completion) {
        return ;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary * dicG = [NSMutableDictionary dictionary];
        for (JWKContactModel * model in contacts) {
            NSString * nameString = model.name;
            NSString * firstChar = nil;
            if (nameString.length) {
                model.nameSortString = [self correctTheFirstNameWithChineseStr:nameString];
                model.pinYinString = [self createPinyinString:model.nameSortString];
                firstChar = [self firstCapitalCharOfString:model.pinYinString];
            }
            if (!firstChar) {
                firstChar = @"#";
            }
            NSMutableArray * arr = dicG[firstChar];
            if (!arr) {
                arr = [NSMutableArray array];
                dicG[firstChar] = arr;
            }
            [arr addObject:model];
        }
        completion(dicG);
    });
}

///姓氏多音字替换为同音字，主要用于获取正确的pinyinArray
-(NSString *)correctTheFirstNameWithChineseStr:(NSString *)chinese {
    NSString * new = [NSString stringWithString:chinese];
    if (chinese.length >= 2) {///长度大于2考虑复姓
        NSString * firstChar = [chinese substringToIndex:1];
        NSString * firstTwoChar = [chinese substringToIndex:2];
        if (self.correctPinYin[firstTwoChar]) {///优先考虑复姓
            new = [new stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:self.correctPinYin[firstTwoChar]];
        } else if (self.correctPinYin[firstChar]) {///单姓
            new = [new stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:self.correctPinYin[firstChar]];
        }
    } else if (chinese.length == 1) {///仅考虑单姓
        NSString * firstChar = [chinese substringToIndex:1];
        if (self.correctPinYin[firstChar]) {///单姓替换
            new = [new stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:self.correctPinYin[firstChar]];
        }
    }
    return new;
}

///创建拼音字符串
-(NSString *)createPinyinString:(NSString *)aString {
    if (!aString.length) {
        return nil;
    }
    __block NSString * string = @"";
    NSString * tempString = [NSString stringWithFormat:@"啊%@",aString];//别问我为什么，我也不知道为什么第一个字是汉字第二个是单词遍历的时候不会分开，前面有两个字就没关系
    [tempString enumerateSubstringsInRange:NSMakeRange(0, tempString.length) options:(NSStringEnumerationByWords|NSStringEnumerationLocalized) usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        NSString * pinyin = [self transferChineseToPinYin:substring];
        if (!string.length) {
            string = [string stringByAppendingString:[NSString stringWithString:pinyin]];
        } else {
            string = [string stringByAppendingString:[NSString stringWithFormat:@" %@",pinyin]];
        }
    }];
    if ([string hasPrefix:@"a "]) {
        string = [string substringFromIndex:2];
    }
    return string;
}

///汉字转拼音
-(NSString *)transferChineseToPinYin:(NSString *)string {
    NSMutableString *mutableString = [NSMutableString stringWithString:string];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    return [mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
}

///返回字符串的大写首字母
-(NSString *)firstCapitalCharOfString:(NSString *)str {
    NSString *first = [[str substringToIndex:1] uppercaseString];
    if (![[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[A-Z]"] evaluateWithObject:first]) {
        first = @"#";
    }
    return first;
}

///首字母排序
-(NSArray *)sortedKeyInGroup:(NSMutableDictionary *)group {
    NSArray * keys = [group.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if ([keys.firstObject isEqualToString:@"#"]) {
        NSMutableArray * new = [NSMutableArray arrayWithArray:keys];
        [new addObject:@"#"];
        [new removeObjectAtIndex:0];
        keys = new.copy;
    }
    return keys;
}

//获取拼音首字母(传入汉字字符串, 返回大写拼音首字母)
- (NSString *)firstCharactor:(NSString *)aString
{
    //转成了可变字符串
    NSMutableString *str = [NSMutableString stringWithString:aString];
    //先转换为带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
    //再转换为不带声调的拼音
//    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
    //转化为大写拼音
    NSString *pinYin = [str capitalizedString];
    //获取并返回首字母
//    return [pinYin substringToIndex:1];
    return pinYin;
}

#pragma mark -
#pragma mark =懒加载
- (NSDictionary *)correctPinYin{
    if(!_correctPinYin){
        
        NSString *str = @"赵 钱 孙 李 周 吴 郑 王 冯 陈 褚 卫 蒋 沈 韩 杨 朱 秦 尤 许 何 吕 施 张 孔 曹 严 华 金 魏 陶 姜 戚 谢 邹 喻 柏 水 窦 章 云 苏 潘 葛 奚 范 彭 郎 鲁 韦 昌 马 苗 凤 花 方 俞 任 袁 柳 酆 鲍 史 唐 费 廉 岑 薛 雷 贺 倪 汤 滕 殷 罗 毕 郝 邬 安 常 乐 于 时 傅 皮 卞 齐 康 伍 余 元 卜 顾 孟 平 黄 和 穆 萧 尹 姚 邵 湛 汪 祁 毛 禹 狄 米 贝 明 臧 计 伏 成 戴 谈 宋 茅 庞 熊 纪 舒 屈 项 祝 董 梁 杜 阮 蓝 闵 席 季 麻 强 贾 路 娄 危 江 童 颜 郭 梅 盛 林 刁 锺 徐 邱 骆 高 夏 蔡 田 樊 胡 凌 霍 虞 万 支 柯 昝 管 卢 莫 经 房 裘 缪 干 解 应 宗 丁 宣 贲 邓 郁 单 杭 洪 包 诸 左 石 崔 吉 钮 龚 程 嵇 邢 滑 裴 陆 荣 翁 荀 羊 於 惠 甄 麴 家 封 芮 羿 储 靳 汲 邴 糜 松 井 段 富 巫 乌 焦 巴 弓 牧 隗 山 谷 车 侯 宓 蓬 全 郗 班 仰 秋 仲 伊 宫 宁 仇 栾 暴 甘 钭 历 戎 祖 武 符 刘 景 詹 束 龙 叶 幸 司 韶 郜 黎 蓟 溥 印 宿 白 怀 蒲 邰 从 鄂 索 咸 籍 赖 卓 蔺 屠 蒙 池 乔 阳 郁 胥 能 苍 双 闻 莘 党 翟 谭 贡 劳 逄 姬 申 扶 堵 冉 宰 郦 雍 却 璩 桑 桂 濮 牛 寿 通 边 扈 燕 冀 僪 浦 尚 农 温 别 庄 晏 柴 瞿 阎 充 慕 连 茹 习 宦 艾 鱼 容 向 古 易 慎 戈 廖 庾 终 暨 居 衡 步 都 耿 满 弘 匡 国 文 寇 广 禄 阙 东 欧 殳 沃 利 蔚 越 夔 隆 师 巩 厍 聂 晁 勾 敖 融 冷 訾 辛 阚 那 简 饶 空 曾 毋 沙 乜 养 鞠 须 丰 巢 关 蒯 相 查 后 荆 红 游 竺 权 逮 盍 益 桓 公 万俟 司马 上官 欧阳 夏侯 诸葛 闻人 东方 赫连 皇甫 尉迟 公羊 澹台 公冶 宗政 濮阳 淳于 单于 太叔 申屠 公孙 仲孙 轩辕 令狐 钟离 宇文 长孙 慕容 司徒 司空 召 有 舜 叶赫那拉 丛 岳 寸 贰 皇 侨 彤 竭 端 赫 实 甫 集 象 翠 狂 辟 典 良 函 芒 苦 其 京 中 夕 之 章佳 那拉 冠 宾 香 果 依尔根觉罗 依尔觉罗 萨嘛喇 赫舍里 额尔德特 萨克达 钮祜禄 他塔喇 喜塔腊 讷殷富察 叶赫那兰 库雅喇 瓜尔佳 舒穆禄 爱新觉罗 索绰络 纳喇 乌雅 范姜 碧鲁 张廖 张简 图门 太史 公叔 乌孙 完颜 马佳 佟佳 富察 费莫 蹇 称 诺 来 多 繁 戊 朴 回 毓 税 荤 靖 绪 愈 硕 牢 买 但 巧 枚 撒 泰 秘 亥 绍 以 壬 森 斋 释 奕 姒 朋 求 羽 用 占 真 穰 翦 闾 漆 贵 代 贯 旁 崇 栋 告 休 褒 谏 锐 皋 闳 在 歧 禾 示 是 委 钊 频 嬴 呼 大 威 昂 律 冒 保 系 抄 定 化 莱 校 么 抗 祢 綦 悟 宏 功 庚 务 敏 捷 拱 兆 丑 丙 畅 苟 随 类 卯 俟 友 答 乙 允 甲 留 尾 佼 玄 乘 裔 延 植 环 矫 赛 昔 侍 度 旷 遇 偶 前 由 咎 塞 敛 受 泷 袭 衅 叔 圣 御 夫 仆 镇 藩 邸 府 掌 首 员 焉 戏 可 智 尔 凭 悉 进 笃 厚 仁 业 肇 资 合 仍 九 衷 哀 刑 俎 仵 圭 夷 徭 蛮 汗 孛 乾 帖 罕 洛 淦 洋 邶 郸 郯 邗 邛 剑 虢 隋 蒿 茆 菅 苌 树 桐 锁 钟 机 盘 铎 斛 玉 线 针 箕 庹 绳 磨 蒉 瓮 弭 刀 疏 牵 浑 恽 势 世 仝 同 蚁 止 戢 睢 冼 种 涂 肖 己 泣 潜 卷 脱 谬 蹉 赧 浮 顿 说 次 错 念 夙 斯 完 丹 表 聊 源 姓 吾 寻 展 出 不 户 闭 才 无 书 学 愚 本 性 雪 霜 烟 寒 少 字 桥 板 斐 独 千 诗 嘉 扬 善 揭 祈 析 赤 紫 青 柔 刚 奇 拜 佛 陀 弥 阿 素 长 僧 隐 仙 隽 宇 祭 酒 淡 塔 琦 闪 始 星 南 天 接 波 碧 速 禚 腾 潮 镜 似 澄 潭 謇 纵 渠 奈 风 春 濯 沐 茂 英 兰 檀 藤 枝 检 生 折 登 驹 骑 貊 虎 肥 鹿 雀 野 禽 飞 节 宜 鲜 粟 栗 豆 帛 官 布 衣 藏 宝 钞 银 门 盈 庆 喜 及 普 建 营 巨 望 希 道 载 声 漫 犁 力 贸 勤 革 改 兴 亓 睦 修 信 闽 北 守 坚 勇 汉 练 尉 士 旅 五 令 将 旗 军 行 奉 敬 恭 仪 母 堂 丘 义 礼 慈 孝 理 伦 卿 问 永 辉 位 让 尧 依 犹 介 承 市 所 苑 杞 剧 第 零 谌 招 续 达 忻 六 鄞 战 迟 候 宛 励 粘 萨 邝 覃 辜 初 楼 城 区 局 台 原 考 妫 纳 泉 老 清 德 卑 过 麦 曲 竹 百 福 言 第五 佟 爱 年 笪 谯 哈 墨 南宫 赏 伯 佴 佘 牟 商 西门 东门 左丘 梁丘 琴 后 况 亢 缑 帅 微生 羊舌 海 归 呼延 南门 东郭 百里 钦 鄢 汝 法 闫 楚 晋 谷梁 宰父 夹谷 拓跋 壤驷 乐正 漆雕 公西 巫马 端木 颛孙 子车 督 仉 司寇 亓官 鲜于 锺离 盖 逯 库 郏 逢 阴 薄 厉 稽 闾丘 公良 段干 开 光 操 瑞 眭 泥 运 摩 伟 铁 迮";
//        _correctPinYin = [str componentsSeparatedByString:@""];
        _correctPinYin = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"paixu" ofType:@"plist"]];
    }
    return _correctPinYin;
}




#pragma mark - Add Water Text
- (void)addWaterText {
    UIImage *waterImg = [UIImage imageNamed:@"yellowman"];
    self.demoImage = [[UIImageView alloc] initWithFrame:RectMacro(waterImg)];
    NSString *text = @"WaterDemo-QH";
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18.0f],NSForegroundColorAttributeName:[UIColor blueColor]};
    CGSize tSize = [text boundingRectWithSize:waterImg.size options:NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
    self.demoImage.image = [waterImg addWaterText:text textPosition:CGPointMake((waterImg.size.width - tSize.width) * 0.5, waterImg.size.height - tSize.height) textAttributes:attributes];
    [self.view addSubview:_demoImage];
}

/**
	加文字随意
	@param img 需要加文字的图片
	@param text1 文字描述
	@returns 加好文字的图片
 */
-(UIImage *)addText:(UIImage *)img text:(NSString *)text1
{
    //get image width and height
    //    int w = img.size.width;
    //    int h = img.size.height;
    
    CGFloat w = self.view.bounds.size.width/2;
    CGFloat h = self.view.bounds.size.height/4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //create a graphic context with CGBitmapContextCreate
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    //    CGContextRotateCTM(context, (-M_PI/18*3));//我的
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 1);
    char* text = (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding];
    CGContextSelectFont(context, "Georgia", 15, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    //    CGContextSetTextMatrix(context, CGAffineTransformMakeRotation(-M_PI/18*3));
    CGContextSetRGBFillColor(context, 0, 255, 255, 0.8);
    
    //位置调整
    CGContextShowTextAtPoint(context, 0 , h-15 , text, strlen(text));
    //    CGContextShowTextAtPoint(context, w/2-strlen(text)*4.5 , h - 135, text, strlen(text));
    
    //Create image ref from the context
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIImage imageWithCGImage:imageMasked];
}

- (UIImage *)addText:(UIImage *)img text:(NSString *)text1 view:(UIView *)view{
    
    //先根据view的大小和算出几个位置来
    //这是间距,x上300,y上140
    int w = 300;
    int h = 140;
    CGFloat startX = view.bounds.size.width/2;
    CGFloat startY = 0;
    
    NSMutableArray *points = [NSMutableArray array];
    //    CGPoint point1 = CGPointMake(<#CGFloat x#>, <#CGFloat y#>)
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //create a graphic context with CGBitmapContextCreate
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 1);
    
    CGContextRotateCTM(context, (-M_PI/18*3));
    
    char* text = (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding];
    CGContextSelectFont(context, "Georgia", 15, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetTextMatrix(context, CGAffineTransformMakeRotation(-M_PI/18*3));
    CGContextSetRGBFillColor(context, 0, 255, 255, 0.8);
    
    //位置调整
    CGContextShowTextAtPoint(context, w/2 , 135 , text, strlen(text));
    //    CGContextShowTextAtPoint(context, w/2-strlen(text)*4.5 , h - 135, text, strlen(text));
    
    //Create image ref from the context
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIImage imageWithCGImage:imageMasked];
    
    //    return nil;
}

+(UIImage*) createImageWithColor:(UIColor*) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+(UIImage*) createImageWithColor:(UIColor*) color angle:(CGFloat)angele rect:(CGRect)rect
{
    //    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    //    CGContextRotateCTM(context, (-M_PI/18*3));
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}
@end
