//
//  JWKContactManager.h
//  test-paixu
//
//  Created by 姜维克 on 2017/5/23.
//  Copyright © 2017年 O2O_iOS_jiangweike. All rights reserved.
//

//
//  JWKContactManager.h
//  sd
//
//  Created by Wicky on 2017/4/18.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 JWKContactManager
 通讯录操作工具类
 为通讯录授权及增删改查提供便捷方法
 提供更贴近中国人姓名的排序方式
 
 version 1.0.0
 提供权限获取接口
 提供获取全部联系人接口
 提供联系人分组排序接口
 提供姓名多音字配置接口
 提供友好错误信息
 
 version 1.0.1
 添加通讯录系统通讯录发生改变通知回调，支持实时更新系统通讯录
 
 version 1.0.2
 中英文分开算法修改，剔除连续空格，解决姓名本身存在空格导致的分隔错误
 
 version 1.0.3
 按姓名拼音排序算法重构，杜绝崩溃可能，返回绝对顺序。
 */


#import <Foundation/Foundation.h>
#import "JWKContactModel.h"

@interface JWKContactManager : NSObject

///获取唯一实例
+(instancetype)shareManager;

///检验授权
+(void)checkAuthorize:(void(^)(BOOL authorized))authorized;

///获取全部联系人
-(void)fetchAllContactsWithCompletion:(void(^)(NSMutableArray * allContacts))completion;

///获取全部联系人后分组并排序
-(void)fetchSortedContactsInGroupWitnCompletion:(void(^)(NSMutableDictionary * sortedContacts,NSArray * sortedKeys))completion;

///

/**
 自动过滤联系人（若未获取过自动获取）
 
 @param condition 过滤条件
 @param completion 过滤后结果回调
 */
-(void)filterAllContactsWithCondition:(BOOL (^)(JWKContactModel *))condition completion:(void (^)(NSArray *))completion;

/**
 若要重新获取通讯录，先行调用此方法
 */
-(void)setNeedsRefetch;

///按姓名、拼音排序指定联系人数组
-(void)sortContacts:(NSArray *)contacts completion:(void(^)(NSArray * sortedResults))completion;

-(void)sortContacts:(NSMutableArray *)contacts;

///将指定联系人数组按首字母分组
-(void)seperateContactsToGroup:(NSArray *)contacts completion:(void(^)(NSMutableDictionary * contactsInGroup))completion;

///首字母排序
-(NSArray *)sortedKeyInGroup:(NSMutableDictionary *)group;

///以条件过滤指定数组内的联系人
-(void)filterContacts:(NSArray *)contacts condition:(BOOL (^)(JWKContactModel *))condition completion:(void (^)(NSArray *))completion;

/**
 下列方法将操作系统联系人，添加、修改、删除联系人修改后会影响重新搜索联系人的结果，但不实际更改系统同学录，只有调用保存联系人变化方法后才会同步至系统通讯录。保存通讯录之前调用丢弃联系人变化方法可放弃改变。但调用保存联系人变化方法后，所有联系人变化将同步至系统通讯录，此时调用丢弃变化也不能恢复
 */
///添加联系人
-(BOOL)addNewContact:(JWKContactModel *)personModel;

///删除联系人
-(BOOL)removeContact:(JWKContactModel *)personModel;

///修改联系人
-(BOOL)editContactWithModel:(JWKContactModel *)personModel handler:(void(^)(JWKContactModel * aPersonModel))handler;

///保存联系人变化
-(BOOL)saveAddressBookChange;

///丢弃联系人变化
-(void)dropAddressBookChange;


@end
