//
//  CCQContactsViewController.m
//  SunduskChat
//
//  Created by 夜兔神威 on 2016/11/3.
//  Copyright © 2016年 ccq. All rights reserved.
//

#import "CCQContactsViewController.h"
#import "CCQChatViewController.h"
@interface CCQContactsViewController ()
//联系人列表
@property (nonatomic, strong) NSArray <XMPPUserCoreDataStorageObject *> *contacts;
@end

@implementation CCQContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //刷新数据
    [self reloadData];
    
    //监听好友变化通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"CCQXMPPRosterDidChangeNote" object:nil];
}
//刷新数据
- (void)reloadData{
    
    //赋值数据
    self.contacts = [[CCQXMPPManager sharedManager] reloadContactList];
    //刷新界面
    [self.tableView reloadData];
}
#pragma mark - 事件响应

//点击添加好友
- (IBAction)clickAddFriendItem:(id)sender {
    
    //添加好友
    [[CCQXMPPManager sharedManager].xmppRoster addUser:[XMPPJID jidWithUser:@"lisi" domain:@"im.itcast.cn" resource:@"iOS"] withNickname:@"李四"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.contacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contact" forIndexPath:indexPath];
    
    //设置联系人名称
    UILabel *nameLabel = [cell viewWithTag:1002];
    nameLabel.text = self.contacts[indexPath.row].jid.user;
    //设置头像
    UIImageView *imgV = [cell viewWithTag:1001];
    imgV.image = [UIImage imageWithData:[[CCQXMPPManager sharedManager].xmppAvatar photoDataForJID:self.contacts[indexPath.row].jid]];
    
    return cell;
}




// 编辑cell
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //删除好友
        [[CCQXMPPManager sharedManager].xmppRoster removeUser:self.contacts[indexPath.row].jid];
    }
}


- (void)dealloc{
    //移除该对象监听的所有通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
