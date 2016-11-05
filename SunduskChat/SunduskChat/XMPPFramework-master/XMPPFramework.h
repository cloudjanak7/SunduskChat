//
//  This file is designed to be customized by YOU.
//  
//  Copy this file and rename it to "XMPPFramework.h". Then add it to your project.
//  As you pick and choose which parts of the framework you need for your application, add them to this header file.
//  
//  Various modules available within the framework optionally interact with each other.
//  E.g. The XMPPPing module utilizes the XMPPCapabilities module to advertise support XEP-0199.
// 
//  However, the modules can only interact if they're both added to your xcode project.
//  E.g. If XMPPCapabilities isn't a part of your xcode project, then XMPPPing shouldn't attempt to reference it.
// 
//  So how do the individual modules know if other modules are available?
//  Via this header file.
// 
//  If you #import "XMPPCapabilities.h" in this file, then _XMPP_CAPABILITIES_H will be defined for other modules.
//  And they can automatically take advantage of it.
//

//  CUSTOMIZE ME !
//  THIS HEADER FILE SHOULD BE TAILORED TO MATCH YOUR APPLICATION.

//  The following is standard:

#import "XMPP.h"

 
// List the modules you're using here:
// (the following may not be a complete list)


/**
 * 心跳检测模块
 */
#import "XMPPPing.h"      //客户端手动发送心跳包
#import "XMPPAutoPing.h"  //客户端自动发送心跳包

/**
 * 自动重连模块
 */
#import "XMPPReconnect.h"

/**
 * 通讯录模块
 */
#import "XMPPRoster.h"  //花名册模块类
#import "XMPPRosterMemoryStorage.h"    //通讯录内存存储器
#import "XMPPRosterCoreDataStorage.h"  //通讯录磁盘缓存存储器(类似自己封装的CoreData的工具类)

/**
 * 消息归档模块
 */
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h" //消息归档磁盘存储器

/**
 * 电子名片缓存模块  (头像模块基于电子名片模块的,xmppframework有个bug,导致使用电子名片模块也需要使用头像模块,所以我们使用时二者一起激活)
 */
#import "XMPPvCardTempModule.h"
#import "XMPPvCardCoreDataStorage.h"  //电子名片磁盘存储器
#import "XMPPvCardTemp.h"

/**
 * 头像模块
 */
#import "XMPPvCardAvatarModule.h"

#import "XMPPFileTransfer.h"
#import "XMPPOutgoingFileTransfer.h" //文件发送模块
#import "XMPPIncomingFileTransfer.h" //文件接收模块



//#import "XMPPBandwidthMonitor.h"
// 
//#import "XMPPCoreDataStorage.h"
//
//#import "XMPPReconnect.h"
//
//#import "XMPPRoster.h"
//#import "XMPPRosterMemoryStorage.h"
//#import "XMPPRosterCoreDataStorage.h"
//
//#import "XMPPJabberRPCModule.h"
//#import "XMPPIQ+JabberRPC.h"
//#import "XMPPIQ+JabberRPCResponse.h"
//
//#import "XMPPPrivacy.h"
//
//#import "XMPPMUC.h"
//#import "XMPPRoom.h"
//#import "XMPPRoomMemoryStorage.h"
//#import "XMPPRoomCoreDataStorage.h"
//#import "XMPPRoomHybridStorage.h"
//
//#import "XMPPvCardTempModule.h"
//#import "XMPPvCardCoreDataStorage.h"
//
//#import "XMPPPubSub.h"
//
//#import "TURNSocket.h"
//
//#import "XMPPDateTimeProfiles.h"
//#import "NSDate+XMPPDateTimeProfiles.h"
//
//#import "XMPPMessage+XEP_0085.h"
//
//#import "XMPPTransports.h"
//
//#import "XMPPCapabilities.h"
//#import "XMPPCapabilitiesCoreDataStorage.h"
//
//#import "XMPPvCardAvatarModule.h"
//
//#import "XMPPMessage+XEP_0184.h"
//
//#import "XMPPPing.h"
//#import "XMPPAutoPing.h"
//
//#import "XMPPTime.h"
//#import "XMPPAutoTime.h"
//
//#import "XMPPElement+Delay.h"
