//
//  CCQXMPPManager.h
//  SunduskChat
//
//  Created by 夜兔神威 on 2016/11/3.
//  Copyright © 2016年 ccq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCQXMPPManager : NSObject
//通讯录模块
@property (nonatomic, strong) XMPPRoster *xmppRoster;
// 单例
+ (instancetype) sharedManager;

/**
 *  登录
 *
 *  @param jid      xmpp的账号名
 *  @param password 密码
 */
- (void)loginWithJID:(XMPPJID *)jid andPassword:(NSString *)password;


/**
 *  注册
 *
 *  @param jid      xmpp的账号名
 *  @param password 密码
 */
- (void)registerWithJID:(XMPPJID *)jid andPassword:(NSString *)password;
@end
