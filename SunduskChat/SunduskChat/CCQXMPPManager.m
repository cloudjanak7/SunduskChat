//
//  CCQXMPPManager.m
//  SunduskChat
//
//  Created by 夜兔神威 on 2016/11/3.
//  Copyright © 2016年 ccq. All rights reserved.
//

#import "CCQXMPPManager.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPLogging.h"
static CCQXMPPManager *instance;
@interface CCQXMPPManager ()<XMPPStreamDelegate>
// socket抽象类
@property (strong , nonatomic) XMPPStream *xmppStream;
// 密码
@property (copy , nonatomic)NSString *password;
//登录/注册的标记
@property (nonatomic, assign, getter=isRegisterAccount) BOOL registerAccount;
@end

@implementation CCQXMPPManager

+(instancetype)sharedManager{
    
   
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [CCQXMPPManager new];
        
        // 设置日志
        [instance setupLogging];
    });
    
    return instance;
}
//设置日志
- (void)setupLogging{
    
    // 开启插件  提前先要运行XcodeColors插件
    setenv("XcodeColors", "YES", 0);
    
    //设置日志级别&打印位置
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:XMPP_LOG_FLAG_SEND_RECV];
    // 设置xcode控制台使用颜色
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    //自定义颜色
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:XMPP_LOG_FLAG_SEND];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:XMPP_LOG_FLAG_RECV_POST];
    
}



//连接
- (void)connectWithJID:(XMPPJID *)jid andPassword:(NSString *)password{
    
    //建立连接  ip地址+端口号
    //ip地址
    self.xmppStream.hostName = @"127.0.0.1";
    //端口号
    self.xmppStream.hostPort = 5222;
    //jid
    self.xmppStream.myJID = jid;
    //密码
    self.password = password;
    BOOL success = [self.xmppStream connectWithTimeout:-1 error:nil];
    if (!success) {
        NSLog(@"连接失败");
    }
    
}

//登录
- (void)loginWithJID:(XMPPJID *)jid andPassword:(NSString *)password{
    
    //建立连接
    [self connectWithJID:jid andPassword:password];
}
#pragma mark - XMPPStreamDelegate
- (void)xmppStreamDidConnect:(XMPPStream *)sender{
    
    
    NSLog(@"服务器连接成功");
    //判断是登录/注册
    if (self.isRegisterAccount) {
        //进行注册
        [self.xmppStream registerWithPassword:self.password error:nil];
        
    }else {
        
        //进行登录 认证密码
        [self.xmppStream authenticateWithPassword:self.password error:nil];
    }
}
//注册成功后调用
- (void)xmppStreamDidRegister:(XMPPStream *)sender{
    
    NSLog(@"注册成功");
}
//登录成功后调用
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    
    NSLog(@"登录成功");
    //该方法默认设置type = available,并且变更的在线状态会发生给所有好友
    XMPPPresence *presence = [XMPPPresence presence];
    
    
    //设置presence的子节点
    //设置固定的在线状态
    [presence addChild:[DDXMLElement elementWithName:@"show" stringValue:@"dnd"]];
    //设置自定义的在线状态(类似QQ的说说)  想要设置status必须写法Ian设置show,并且show中只有部分状态支持自定义状态
    [presence addChild:[DDXMLElement elementWithName:@"status" stringValue:@"最近手头紧~"]];
    
    //发送presence节给服务器 用来改变用户的在线状态
    [self.xmppStream sendElement:presence];
}


#pragma mark - 懒加载

- (XMPPStream *)xmppStream{
    
    if (_xmppStream == nil) {
        
        _xmppStream = [[XMPPStream alloc] init];
        
        //设置代理  
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}


@end
