//
//  HMMeTableViewController.m
//  HMWechat
//
//  Created by HM on 16/11/5.
//  Copyright © 2016年 HM. All rights reserved.
//

#import "CCQMeTableViewController.h"

@interface CCQMeTableViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgV;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end

@implementation CCQMeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //从电子名片模块中取出当前账号的信息
    XMPPvCardTemp *myvCard = [CCQXMPPManager sharedManager].xmppvCardTemp.myvCardTemp;
    //设置信息
    self.nickNameLabel.text = myvCard.nickname;
    self.descLabel.text = myvCard.desc;
    self.avatarImgV.image = [UIImage imageWithData:myvCard.photo];
}



@end
