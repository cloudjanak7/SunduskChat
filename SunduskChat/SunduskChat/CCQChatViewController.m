//
//  HMChatViewController.m
//  HMWechat
//
//  Created by HM on 16/11/5.
//  Copyright © 2016年 HM. All rights reserved.
//

#import "CCQChatViewController.h"

static NSString *recvCell = @"recvCell";
static NSString *sendCell = @"sendCell";


@interface CCQChatViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//查询控制器
@property (nonatomic, strong) NSFetchedResultsController *fetchController;
//归档的消息数组
@property (nonatomic, strong) NSArray <XMPPMessageArchiving_Message_CoreDataObject *> *archivingMsgs;

@end

@implementation CCQChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //设置预估行高
    self.tableView.estimatedRowHeight = 200;
    //自动计算行高
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    //刷新数据
    [self reloadData];
}

- (void)reloadData{
    
    //进行查询
    BOOL success = [self.fetchController performFetch:nil];
    if (success) {
        
        //赋值数据
        self.archivingMsgs = self.fetchController.fetchedObjects;
        //刷新界面
        [self.tableView reloadData];
        //ViewDidLoad中不能够执行动画,设置延迟,避免出现界面bug
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            //设置tableView的滚动
            if (self.archivingMsgs.count > 0) {
                
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.archivingMsgs.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        });
    }
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    //发送消息  chat单聊  groupchat 群聊
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.contactJID];
    //设置内容
    [message addBody:textField.text];
    [[CCQXMPPManager sharedManager].xmppStream sendElement:message];
    //清空输入框
    textField.text = nil;
    
    return YES;
}


#pragma mark - NSFetchedResultsControllerDelegate

//当前联系人的消息列表发生变化后,刷新数据
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    //刷新数据
    [self reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.archivingMsgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell;
    //获取数据
    XMPPMessageArchiving_Message_CoreDataObject *archivingMsg = self.archivingMsgs[indexPath.row];
    //根据消息收发情况来不同的cell
    if (archivingMsg.isOutgoing) { //发出的消息
        
        cell = [tableView dequeueReusableCellWithIdentifier:sendCell forIndexPath:indexPath];
        UIImageView *imgV = [cell viewWithTag:1001];
        imgV.image = [UIImage imageWithData:[CCQXMPPManager sharedManager].xmppvCardTemp.myvCardTemp.photo];
        
    } else { //接收的消息
        
        cell = [tableView dequeueReusableCellWithIdentifier:recvCell forIndexPath:indexPath];
        UIImageView *imgV = [cell viewWithTag:1001];
        imgV.image = [UIImage imageWithData:[[CCQXMPPManager sharedManager].xmppAvatar photoDataForJID:self.contactJID]];
        
    }
    UILabel *contentLabel = [cell viewWithTag:1002];
    contentLabel.text = archivingMsg.message.body;
    
    return cell;
}

#pragma mark - 懒加载

- (NSFetchedResultsController *)fetchController{
    if (_fetchController == nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        // 设置谓词  取出和当前联系人聊的记录
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", self.contactJID.bare];
        [fetchRequest setPredicate:predicate];
        // 设置排序 按照时间排序
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        _fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[XMPPMessageArchivingCoreDataStorage sharedInstance].mainThreadManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        //设置代理  监听消息变化
        _fetchController.delegate = self;
    }
    return _fetchController;
}



@end
