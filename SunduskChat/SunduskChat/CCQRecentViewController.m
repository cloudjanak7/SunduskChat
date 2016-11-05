//
//  HMRecentViewController.m
//  HMWechat
//
//  Created by HM on 16/11/5.
//  Copyright © 2016年 HM. All rights reserved.
//

#import "CCQRecentViewController.h"
#import "CCQChatViewController.h"

@interface CCQRecentViewController ()<NSFetchedResultsControllerDelegate>
//查询控制器 查询contact表,获取每个联系人最近一条消息
@property (nonatomic, strong) NSFetchedResultsController *fetchController;
//最近联系人数组
@property (nonatomic, strong) NSArray <XMPPMessageArchiving_Contact_CoreDataObject *> *recentContacts;

@end

@implementation CCQRecentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadData];
}

//刷新数据
- (void)reloadData{
    //执行查询
    BOOL success = [self.fetchController performFetch:nil];
    if (success) {
        //赋值数据
        self.recentContacts = self.fetchController.fetchedObjects;
        //刷新界面
        [self.tableView reloadData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    //设置聊天界面的联系人JID
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    CCQChatViewController *chatVc = segue.destinationViewController;
    chatVc.contactJID = self.recentContacts[path.row].bareJid;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    
    [self reloadData];
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.recentContacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recent" forIndexPath:indexPath];
    
    // Configure the cell...
    //设置名称
    UILabel *nameLabel = [cell viewWithTag:1002];
    nameLabel.text = self.recentContacts[indexPath.row].bareJid.user;
    //设置消息内容
    UILabel *contentLabel = [cell viewWithTag:1003];
    contentLabel.text = self.recentContacts[indexPath.row].mostRecentMessageBody;
    //设置头像
    UIImageView *imgV = [cell viewWithTag:1001];
    imgV.image = [UIImage imageWithData:[[CCQXMPPManager sharedManager].xmppAvatar photoDataForJID:self.recentContacts[indexPath.row].bareJid]];
    
    return cell;
}

#pragma mark - 懒加载

- (NSFetchedResultsController *)fetchController{
    if (_fetchController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject" inManagedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        // 设置排序  时间倒序
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"mostRecentMessageTimestamp" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        //监听变化
        _fetchController.delegate = self;
    }
    return _fetchController;
}



@end
