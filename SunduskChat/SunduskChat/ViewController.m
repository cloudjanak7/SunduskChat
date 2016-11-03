//
//  ViewController.m
//  SunduskChat
//
//  Created by 夜兔神威 on 2016/11/2.
//  Copyright © 2016年 ccq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//登录
        [[CCQXMPPManager sharedManager] loginWithJID:[XMPPJID jidWithUser:@"lisi" domain:@"sundusk.iOS.cn" resource:@"iOS"] andPassword:@"123"];
    
//    //注册
//    [[CCQXMPPManager sharedManager] registerWithJID:[XMPPJID jidWithUser:@"zhaoliu" domain:@"sundusk.iOS.cn" resource:@"iOS"] andPassword:@"123"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
