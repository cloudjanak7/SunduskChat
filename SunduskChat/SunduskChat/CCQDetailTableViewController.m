//
//  HMDetailTableViewController.m
//  HMWechat
//
//  Created by HM on 16/11/5.
//  Copyright © 2016年 HM. All rights reserved.
//

#import "CCQDetailTableViewController.h"
#import "CCQEditViewController.h"

@interface CCQDetailTableViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImgV;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end

@implementation CCQDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //从电子名片模块中取出当前账号的信息
    XMPPvCardTemp *myvCard = [CCQXMPPManager sharedManager].xmppvCardTemp.myvCardTemp;
    //设置信息
    self.nameLabel.text = myvCard.nickname;
    self.descLabel.text = myvCard.desc;
    self.avatarImgV.image = [UIImage imageWithData:myvCard.photo];
}

#pragma mark - 响应事件

//点击头像
- (IBAction)clickAvatarImgV:(id)sender {
    //创建控制器
    UIImagePickerController *pickerVc = [[UIImagePickerController alloc] init];
    //设置属性/代理
    pickerVc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerVc.delegate = self;
    //允许裁切
    pickerVc.allowsEditing = YES;
    //modal展示
    [self presentViewController:pickerVc animated:YES completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    CCQEditViewController *editVc = segue.destinationViewController;
    //根据segueIdentifier设置不同的标题,用于区别设置的内容
    if ([segue.identifier isEqualToString:@"nickName"]) {
        editVc.title = @"修改昵称";
    }else{
        editVc.title = @"修改个性签名";
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *img = info[UIImagePickerControllerEditedImage];
    //获取电子名片
    XMPPvCardTemp *myvCard = [CCQXMPPManager sharedManager].xmppvCardTemp.myvCardTemp;
    myvCard.photo = UIImageJPEGRepresentation(img, 0.1);
    
    //更新电子名片
    [[CCQXMPPManager sharedManager].xmppvCardTemp updateMyvCardTemp:myvCard];
    //销毁控制器
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
