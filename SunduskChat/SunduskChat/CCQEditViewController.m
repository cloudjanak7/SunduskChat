//
//  HMEditViewController.m
//  HMWechat
//
//  Created by HM on 16/11/5.
//  Copyright © 2016年 HM. All rights reserved.
//

#import "CCQEditViewController.h"

@interface CCQEditViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation CCQEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - 事件响应

- (IBAction)clickBackItem:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

//点击保存按钮(修改昵称/个性签名)
- (IBAction)clickSaveItem:(id)sender {
    //获取当前的电子名片
    XMPPvCardTemp *myvCard = [CCQXMPPManager sharedManager].xmppvCardTemp.myvCardTemp;
    //修改电子名片信息
    if ([self.title isEqualToString:@"修改昵称"]) { //修改昵称
        
        myvCard.nickname = self.textField.text;
        
    } else { //修改个性签名
        
        myvCard.desc = self.textField.text;
    }
    [[CCQXMPPManager sharedManager].xmppvCardTemp updateMyvCardTemp:myvCard];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
