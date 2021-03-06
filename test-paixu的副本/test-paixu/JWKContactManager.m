//
//  JWKContactManager.m
//  test-paixu
//
//  Created by 姜维克 on 2017/5/23.
//  Copyright © 2017年 O2O_iOS_jiangweike. All rights reserved.
//

#import "JWKContactManager.h"
#import <AddressBook/AddressBook.h>


#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

@interface JWKContactManager ()

@property (nonatomic ,strong) NSMutableArray<JWKContactModel *> * allContacts;

@property (nonatomic ,strong) NSMutableDictionary * sortedContacts;

@property (nonatomic ,strong) NSArray * sortedKeys;

@property (nonatomic ,strong) NSMutableDictionary * correctPinYin;

@property (nonatomic ,assign) ABAddressBookRef addressBook;

@property (nonatomic ,assign) BOOL isChangingAB;

@end


static JWKContactManager * manager = nil;
@implementation JWKContactManager

#pragma mark --- interface method ---
+(void)checkAuthorize:(void (^)(BOOL))authorized {
    if (!authorized) {
        return;
    }
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    // 2.判断授权状态,如果是未决定状态,才需要请求
    if (status == kABAuthorizationStatusNotDetermined) {
        // 3.创建通讯录进行授权
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (error) {
                NSLog(@"Something wrong, you may check this error :%@",(__bridge_transfer NSError *)error);
            }
            authorized(granted);
        });
    } else if (status == kABAuthorizationStatusAuthorized) {
        authorized(YES);
    } else {
        authorized(NO);
    }
}

-(void)fetchAllContactsWithCompletion:(void (^)(NSMutableArray *))completion {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        if (self.allContacts) {
            if (completion) {
                completion(self.allContacts);
            }
            return;
        }
        NSArray * array = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(self.addressBook);
        NSMutableArray <JWKContactModel *>* contacts = [NSMutableArray array];
        for (int i = 0;i < array.count;i++) {
            [contacts addObject:[[JWKContactModel alloc] initWithABRecord:(ABRecordRef)array[i]]];
        }
        self.allContacts = contacts;
        if (completion) {
            completion(self.allContacts);
        }
    }
}

-(void)fetchSortedContactsInGroupWitnCompletion:(void(^)(NSMutableDictionary * sortedContacts,NSArray * sortedKeys))completion {
    if (self.sortedContacts && self.sortedKeys) {
        if (completion) {
            completion(self.sortedContacts,self.sortedKeys);
        }
        return;
    }
    [self fetchAllContactsWithCompletion:^(NSMutableArray *allContacts) {
        ///分组并配置排序信息
        [self seperateContactsToGroup:allContacts completion:^(NSMutableDictionary *contactsInGroup) {
            ///将分组内联系人按拼音、姓名排序
            [self sortGroupContacts:contactsInGroup];
            self.sortedContacts = contactsInGroup;
            self.sortedKeys = [self sortedKeyInGroup:self.sortedContacts];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(self.sortedContacts,self.sortedKeys);
                });
            }
        }];
    }];
}

-(void)setNeedsRefetch {
    [self createAddressBook];
    self.allContacts = nil;
    self.sortedContacts = nil;
    self.sortedKeys = nil;
}

-(void)filterAllContactsWithCondition:(BOOL (^)(JWKContactModel *))condition completion:(void (^)(NSArray *))completion {
    if (self.allContacts) {
        [self filterContacts:self.allContacts condition:condition completion:completion];
    } else {
        [self fetchAllContactsWithCompletion:^(NSMutableArray *allContacts) {
            [self filterContacts:allContacts condition:condition completion:completion];
        }];
    }
}

-(void)sortContacts:(NSArray *)contacts completion:(void (^)(NSArray *))completion {
    NSMutableArray * contactsM = [NSMutableArray arrayWithArray:contacts];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self sortContacts:contactsM];
        completion ? completion([contactsM copy]) : nil;
    });
}

///姓名分组
-(void)seperateContactsToGroup:(NSArray *)contacts completion:(void(^)(NSMutableDictionary * contactsInGroup))completion {
    if (!completion) {
        return ;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary * dicG = [NSMutableDictionary dictionary];
        for (JWKContactModel * model in contacts) {
            NSString * nameString = [NSString stringWithFormat:@"%@%@%@",model.familyName?:@"",model.middleName?:@"",model.givenName?:@""];
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

-(BOOL)addNewContact:(JWKContactModel *)personModel {
    if (self.isChangingAB) {
        return NO;
    }
    __block BOOL success = NO;
    self.isChangingAB = YES;
    [personModel transferToABRecordWithCompletion:^(ABRecordRef aRecord) {
        CFErrorRef error = NULL;
        success = ABAddressBookAddRecord(self.addressBook, aRecord, &error);
        if (error) {
            NSLog(@"Something wrong, you may check this error :%@",(__bridge_transfer NSError *)error);
            CFRelease(error);
        }
        self.isChangingAB = NO;
    }];
    return success;
}

-(BOOL)removeContact:(JWKContactModel *)personModel {
    if (self.isChangingAB) {
        return NO;
    }
    BOOL success = NO;
    self.isChangingAB = YES;
    if (personModel.originRecord) {
        CFErrorRef error = NULL;
        success = ABAddressBookRemoveRecord(self.addressBook, personModel.originRecord, &error);
        if (error) {
            NSLog(@"Something wrong, you may check this error :%@",(__bridge_transfer NSError *)error);
            CFRelease(error);
        }
        self.isChangingAB = NO;
    }
    return success;
}

-(BOOL)editContactWithModel:(JWKContactModel *)personModel handler:(void (^)(JWKContactModel *))handler {
    if (!personModel.originRecord || !handler || self.isChangingAB) {
        return NO;
    }
    self.isChangingAB = YES;
    handler(personModel);
    self.isChangingAB = NO;
    return YES;
}

-(BOOL)saveAddressBookChange {
    if (self.isChangingAB) {
        return NO;
    }
    CFErrorRef error = NULL;
    BOOL success = ABAddressBookSave(self.addressBook, &error);
    if (error) {
        NSLog(@"Something wrong, you may check this error :%@",(__bridge_transfer NSError *)error);
        CFRelease(error);
    }
    return success;
}

-(void)dropAddressBookChange {
    if (self.isChangingAB) {
        return;
    }
    ABAddressBookRevert(self.addressBook);
}

#pragma mark --- tool method ---
///同分组按拼音/汉字排序
-(void)sortGroupContacts:(NSMutableDictionary *)groupContacts {
    for (NSMutableArray * arr in groupContacts.allValues) {
        [self sortContacts:arr];
    }
}

///按拼音/汉字排序指定范围联系人
-(void)sortContacts:(NSMutableArray *)contacts {
    [contacts sortUsingComparator:^NSComparisonResult(JWKContactModel * obj1, JWKContactModel * obj2) {
        return [obj1.nameSortString localizedCompare:obj2.nameSortString];
    }];
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

///汉字转拼音
-(NSString *)transferChineseToPinYin:(NSString *)string {
    NSMutableString *mutableString = [NSMutableString stringWithString:string];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    return [mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
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

///返回字符串的大写首字母
-(NSString *)firstCapitalCharOfString:(NSString *)str {
    NSString *first = [[str substringToIndex:1] uppercaseString];
    if (![[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[A-Z]"] evaluateWithObject:first]) {
        first = @"#";
    }
    return first;
}

///以条件过滤数组
-(void)filterContacts:(NSArray *)contacts condition:(BOOL (^)(JWKContactModel *))condition completion:(void (^)(NSArray *))completion {
    if (!condition) {
        return;
    }
    if (contacts.count) {
        NSMutableArray * temp = [NSMutableArray array];
        for (JWKContactModel * personModel in self.allContacts) {
            if (condition(personModel)) {
                [temp addObject:personModel];
            }
        }
        completion ? completion(temp) : nil;
    } else {
        completion ? completion(nil) : nil;
    }
}

-(void)createAddressBook {
    CFErrorRef error = NULL;
    _addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) {
        NSLog(@"Something wrong, you may check this error :%@",(__bridge_transfer NSError *)error);
        CFRelease(error);
    } else {
        ABAddressBookRegisterExternalChangeCallback(_addressBook, ContactChangeCallBack, nil);
    }
}

void ContactChangeCallBack(ABAddressBookRef addressBook,CFDictionaryRef info,void *context) {
    [manager setNeedsRefetch];
    [manager fetchSortedContactsInGroupWitnCompletion:nil];
}

#pragma mark --- singleton ---
+(instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[JWKContactManager alloc] init];
    });
    return manager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

-(id)copyWithZone:(struct _NSZone *)zone {
    return manager;
}

#pragma mark --- overwrite ---
-(instancetype)init {
    if (self = [super init]) {
        [self createAddressBook];
    }
    return self;
}

-(void)dealloc {
    ABAddressBookUnregisterExternalChangeCallback(_addressBook, ContactChangeCallBack, nil);
}

#pragma mark --- setter/getter ---
-(ABAddressBookRef)addressBook {
    if (!_addressBook) {
        [self createAddressBook];
    }
    return _addressBook;
}

-(NSMutableDictionary *)correctPinYin {
    if (!_correctPinYin) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"JWKContactManagerResource" ofType:@"bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:path];
        _correctPinYin = [NSMutableDictionary dictionaryWithContentsOfFile:[bundle pathForResource:@"JWKContactManagerPinYinCorrect" ofType:@"plist"]];
    }
    return _correctPinYin;
}
@end

#pragma clang diagnostic pop
