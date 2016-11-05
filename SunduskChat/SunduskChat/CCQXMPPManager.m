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
#import "Reachability.h"

static CCQXMPPManager *instance;
@interface CCQXMPPManager ()<XMPPStreamDelegate, XMPPAutoPingDelegate, XMPPReconnectDelegate, XMPPRosterDelegate, NSFetchedResultsControllerDelegate, XMPPIncomingFileTransferDelegate>
//密码
@property (nonatomic, copy) NSString *password;
//登录/注册的标记
@property (nonatomic, assign, getter=isRegisterAccount) BOOL registerAccount;
//心跳检测模块
@property (nonatomic, strong) XMPPAutoPing *xmppAutoping;
//自动重连模块
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
//通讯录查询控制器
@property (nonatomic, strong) NSFetchedResultsController *rosterFetchController;
//消息归档模块
@property (nonatomic, strong) XMPPMessageArchiving *xmppMsgArchiving;
//文件接收模块
@property (nonatomic, strong) XMPPIncomingFileTransfer *xmppIncomingFT;
@end

@implementation CCQXMPPManager

+ (instancetype)sharedManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [CCQXMPPManager new];
        //设置日志
        [instance setupLogging];
        //设置模块
        [instance setupModule];
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

//设置模块
- (void)setupModule{
    //模块类, xmppframework将XEP都封装成了模块  模块使用步骤: 1.创建模块 2.设置属性/代理 3.激活模块
    
    /**
     * 心跳检测
     */
    //设置发送心跳包时间间隔
    self.xmppAutoping.pingInterval = 500;
    //设置心跳响应的超时时长
    self.xmppAutoping.pingTimeout = 5;
    //设置是否响应另一端发来的心跳包
    self.xmppAutoping.respondsToQueries = YES;
    //激活模块
    [self.xmppAutoping activate:self.xmppStream];
    
    /**
     * 自动重连模块
     */
    [self.xmppReconnect activate:self.xmppStream];
    
    /**
     * 通讯录模块
     */
    //设置自动同步通讯录(从服务器同步) 通讯录模块每次初始化后,只允许完整的同步一次通讯录(同步一次完整的通讯录后,再对好友关系进行改变,使用增量的方式来获取)
    self.xmppRoster.autoFetchRoster =YES;
    //当连接断开时,自动清理通讯录的内存缓存
    self.xmppRoster.autoClearAllUsersAndResources = YES;
    
    /**
     * XMPP中的好友关系分两种:
     出席: 类似通讯录中的联系人(出席关系是不知道对方的状态)
     订阅: 类似微博的关注(订阅后可以获取对方的状态)
     */
    //设置是否自动接受已知的出席/订阅请求(简单理解为接受好友请求,如果想要区别好友的发起方,则该属性不能设置为YES)
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = NO;
    [self.xmppRoster activate:self.xmppStream];
    
    /**
     * 消息归档模块
     */
    //是否只归档客户端的消息(即使设置为NO,也要求客户端完整实现0136协议才可以实现离线消息同步)
    self.xmppMsgArchiving.clientSideMessageArchivingOnly = YES;
    [self.xmppMsgArchiving activate:self.xmppStream];
    
    /**
     * 电子名片模块
     */
    [self.xmppvCardTemp activate:self.xmppStream];
    
    /**
     * 头像模块
     */
    [self.xmppAvatar activate:self.xmppStream];
    
    /**
     * 文件接收模块
     */
    //是否自动接收文件
    self.xmppIncomingFT.autoAcceptFileTransfers = YES;
    [self.xmppIncomingFT activate:self.xmppStream];
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
//带内注册(在xmpp的长连接中)
- (void)registerWithJID:(XMPPJID *)jid andPassword:(NSString *)password{
    //设置注册标记
    self.registerAccount = YES;
    //建立长连接
    [self connectWithJID:jid andPassword:password];
}

#pragma mark - XMPPIncomingFileTransferDelegate

//接收文件失败
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didFailWithError:(NSError *)error{
    
}

//接收到文件请求后调用  如果自动接收文件,则该方法不会响应
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didReceiveSIOffer:(XMPPIQ *)offer{
    
}

//接收到文件后调用
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didSucceedWithData:(NSData *)data named:(NSString *)name{
    
    NSLog(@"接收到文件:%@", name);
    //保存文件
    [data writeToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:name] atomically:YES];
}


#pragma mark - NSFetchedResultsControllerDelegate

//结果集发生变化后调用->间接监听到user表的变化
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controllerP{
    //给通讯录控制器发通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HMXMPPRosterDidChangeNote" object:nil userInfo:nil];
}

#pragma mark - 通讯录相关

- (NSArray<XMPPUserCoreDataStorageObject *> *)reloadContactList{
    
    //执行查询
    BOOL success = [self.rosterFetchController performFetch:nil];
    if (success) {
        
        return self.rosterFetchController.fetchedObjects;
        
    }else {
        NSLog(@"数据查询失败");
        return nil;
    }
}


#pragma mark - XMPPRosterDelegate

//如果没有自动接受出席订阅请求,则接受到出席/订阅请求后会响应该方法
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    
    //需要在该方法中判断"我加别人"还是"别人加我"
    
    //如果"我加别人",我们的客户端会保存添加记录(在CoreData),如果别人加我(在我没有做任何操作前,不会在数据库中记录)
    //需要根据user表中ask字段来判断(如果我加别人,该用户的ask字段为subscrib;如果别人加我,user表就根本没有该用户)
    
    //判断办法:  查询user表,找到该联系人的记录,查询其ask字段是否为subscrib,如果是就是我加别人
    //进行CoreData查询
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
    [fetchRequest setEntity:entity];
    // 设置谓词 匹配请求的发起人的JID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", presence.from];
    [fetchRequest setPredicate:predicate];
    //获取查询结果  该发起者对应的记录
    NSArray *fetchedObjects = [[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:nil];
    XMPPUserCoreDataStorageObject *contact = fetchedObjects.lastObject;
    if ([contact.ask isEqualToString:@"subscribe"]) { //我加别人
        
        //接受订阅请求
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
        
        //进行界面展示
        UIAlertController *alerController = [UIAlertController alertControllerWithTitle:@"好友通知" message:[NSString stringWithFormat:@"%@已经成为您的好友~", presence.from.user] preferredStyle:UIAlertControllerStyleAlert];
        
        UIViewController *rootVc = [[UIApplication sharedApplication].delegate window].rootViewController;
        [rootVc presentViewController:alerController animated:YES completion:nil];
        
        //设置延迟消息
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [alerController dismissViewControllerAnimated:YES completion:nil];
        });
        
    }else { //别人加我
        
        //进行界面展示,让用户选择是否添加该联系人
        UIAlertController *alerController = [UIAlertController alertControllerWithTitle:@"好友请求" message:[NSString stringWithFormat:@"%@想要添加您为好友", presence.from.user] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            //接受出席&订阅请求
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
        }];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            //拒绝请求
            [self.xmppRoster rejectPresenceSubscriptionRequestFrom:presence.from];
        }];
        
        [alerController addAction:action1];
        [alerController addAction:action2];
        
        UIViewController *rootVc = [[UIApplication sharedApplication].delegate window].rootViewController;
        [rootVc presentViewController:alerController animated:YES completion:nil];
        
        
    }
}

#pragma mark - XMPPReconnectDelegate

/**
 *  已经检测到非正常断开后调用
 *
 *  @param sender          获取到当前的网络情况(systemconfigration,使用不方便,建议使用Reachability来检测网络)
 *  @param connectionFlags
 */
//- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags{
//
//}

/**
 *  当设置是否进行自动重连时调用
 *
 *  @param sender   重连模块
 *  @param reachabilityFlags 网络情况
 *
 *  @return 设置是否进行自动重连
 */
- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags{
    //根据网络情况,选择是否进行自动重连
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = reachability.currentReachabilityStatus;
    switch (status) {
        case ReachableViaWiFi:
            return YES;
            break;
        case ReachableViaWWAN:
            //3G情况下,显示弹窗,提示用户是否自动重连
            return NO;
            break;
        default:
            return NO;
            break;
    }
    
}


#pragma mark - XMPPAutoPingDelegate

//已经发送心跳包后调用
- (void)xmppAutoPingDidSendPing:(XMPPAutoPing *)sender{
    
    
}

//已经接收到对端的响应后调用
- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender{
    
    NSLog(@"接收到响应");
}

//响应已经超时后调用
- (void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender{
    
    //显示弹窗,提示用户连接已经断开,是否重新连接
    NSLog(@"响应超时");
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    
    NSLog(@"服务器连接断开");
}

//已经连接成功后调用
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
    //设置在线状态
    //    XMPPPresence *presence = [[XMPPPresence alloc] initWithXMLString:@"<presence type = 'available'/>" error:nil];
    
    //将当前账号的在线状态发送给lisi(如果不设置to,则当前账号的所有好友都会收到当前账号的新状态)
    //    [XMPPPresence presenceWithType:@"available" to:[XMPPJID jidWithUser:@"lisi" domain:@"im.itcast.cn" resource:@"iOS"]];
    
    //该方法默认设置type = available,并且变更的在线状态会发生给所有好友(pub-sub 发布订阅网络交互方式)
    XMPPPresence *presence = [XMPPPresence presence];
    
    //设置presence的子节点
    //设置固定的在线状态
    [presence addChild:[DDXMLElement elementWithName:@"show" stringValue:@"dnd"]];
    //设置自定义的在线状态(类似QQ的说说)  想要设置status必须先设置show,并且show中只有部分状态支持自定义状态
    [presence addChild:[DDXMLElement elementWithName:@"status" stringValue:@"最近手头紧~"]];
    
    //发送presence节给服务器 用来改变用户的在线状态
    [self.xmppStream sendElement:presence];
    
    //登录成功,跳转控制器
    UIStoryboard *rootSB = [UIStoryboard storyboardWithName:@"Root" bundle:nil];
    [[UIApplication sharedApplication].delegate window].rootViewController = [rootSB instantiateInitialViewController];
}


#pragma mark - 懒加载

- (XMPPStream *)xmppStream{
    
    if (_xmppStream == nil) {
        
        _xmppStream = [[XMPPStream alloc] init];
        
        //设置代理  多播代理(可以添加多个代理)  1对n 多播代理是通知和代理的一种结合方式 好处:既实现了1对多,而且还比通知好用(通知的key和传递的数据需要查询,不方便查看;可以满足双向数据传递)
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}

- (XMPPAutoPing *)xmppAutoping{
    if (_xmppAutoping == nil) {
        _xmppAutoping = [[XMPPAutoPing alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        //设置代理 监听心跳情况
        [_xmppAutoping addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppAutoping;
}

- (XMPPReconnect *)xmppReconnect{
    
    if (_xmppReconnect == nil) {
        _xmppReconnect = [[XMPPReconnect alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        [_xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppReconnect;
}

- (XMPPRoster *)xmppRoster{
    if (_xmppRoster == nil) {
        //设置Storage就是在选择缓存策略(如果选择磁盘策略,则从服务器同步到好友列表后xmppframework会使用coredata对通讯录数据进行磁盘缓存)
        _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:[XMPPRosterCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
        
        //设置代理
        [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppRoster;
}

- (NSFetchedResultsController *)rosterFetchController{
    
    if (_rosterFetchController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        // 设置谓词  我们自己约定出席+订阅才是好友
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription = 'both'"];
        [fetchRequest setPredicate:predicate];
        // 设置排序  按照英文字母顺序
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"jidStr" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _rosterFetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        //设置代理 监听好友列表的变化
        _rosterFetchController.delegate = self;
    }
    return _rosterFetchController;
}


- (XMPPMessageArchiving *)xmppMsgArchiving{
    if (_xmppMsgArchiving == nil) {
        _xmppMsgArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:[XMPPMessageArchivingCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppMsgArchiving;
}

- (XMPPvCardTempModule *)xmppvCardTemp{
    if (_xmppvCardTemp == nil) {
        _xmppvCardTemp = [[XMPPvCardTempModule alloc] initWithvCardStorage:[XMPPvCardCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppvCardTemp;
}

- (XMPPvCardAvatarModule *)xmppAvatar{
    
    if (_xmppAvatar == nil) {
        _xmppAvatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTemp dispatchQueue:dispatch_get_main_queue()];
    }
    return _xmppAvatar;
}

- (XMPPIncomingFileTransfer *)xmppIncomingFT{
    if (_xmppIncomingFT == nil) {
        _xmppIncomingFT = [[XMPPIncomingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        //设置代理 监听文件接收情况
        [_xmppIncomingFT addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppIncomingFT;
}


///**
// *  当结果集中的一个数据发生变化后调用
// *
// *  @param controller
// *  @param anObject     发生变化的对象
// *  @param indexPath    该对象在结果集中原来的位置
// *  @param type         改变的类型(增删改)
// *  @param newIndexPath 该对象在结果集中新的位置
// */
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath{
//
//}
//
///**
// *  某个组发生变化时调用
// *
// *  @param controller   <#controller description#>
// *  @param sectionInfo  <#sectionInfo description#>
// *  @param sectionIndex <#sectionIndex description#>
// *  @param type         <#type description#>
// */
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
//
//}
//
///**
// *  结果集将要发生变化后调用
// *
// *  @param controller <#controller description#>
// */
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
//
//}
//
//
///**
// *  结果集将要发生变化后调用->上下文一定变了->数据库可能变了
// *
// *  @param controller
// */
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
//
//}
//
///**
// *  设置组名时调用(可以通过分组功能实现通讯录,使用该方法来修改组名)
// *
// *  @param controller
// *  @param sectionName
// *
// *  @return
// */
//- (nullable NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName{
//    
//}

@end
