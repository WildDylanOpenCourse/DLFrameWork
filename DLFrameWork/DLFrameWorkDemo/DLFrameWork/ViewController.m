//
//  ViewController.m
//  DLFrameWork
//
//  Created by XueYulun on 15/6/25.
//  Copyright (c) 2015年 __Dylan. All rights reserved.
//

#import "ViewController.h"
#import "OHHTTPStubs.h"

// @ M

@implementation MainModel

+ (DLKeyMapper *)keyMapper {
    
    return [[DLKeyMapper alloc] initWithDictionary:@{
                                                     @"name" : @"stu_name"
                                                     }];
}

@end


// @ V

@implementation MainView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.backgroundColor = [UIColor yellowColor];
        _nameLabel.textColor = [UIColor darkGrayColor];
        _nameLabel.frame = CGRectMake(20, 20, 100, 30);
        [self addSubview:_nameLabel];
    }
    
    return self;
}

@end


// @ VM

@implementation MainViewModel

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _model = [[MainModel alloc] init];
    }
    
    return self;
}

- (void)LoadData {
    
    // Add stub
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        
        return [[OHHTTPStubsResponse responseWithFileAtPath:OHPathForFile(@"Student.json", self.class)
                                                 statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}]
                requestTime:2
                responseTime:OHHTTPStubsDownloadSpeedWifi];
    }].name = @"StudentStub";
    
    [DLAPI getWithPath:@"http://www.baidu.com" andParams:@{} completion:^(id json, DLModelError *err) {
        
        _model = [[MainModel alloc] init];
        _model.name = @"Hello";
        
        if (self.response) {
            
            self.response(_model);
        }
    }];
}

@end

// @ VC

@interface ViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    MainView * _View;
}

@property (nonatomic, strong) MainViewModel * VM;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    DLRefreshTableView * tableView = [[DLRefreshTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableFooterView = [UIView new];
    [self.view addSubview:tableView];
    
    UILabel * aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, DL_SCREENWIDTH, 30)];
    aLabel.text = @"没有数据";
    
    [tableView setNoDataView:aLabel];
    
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(self.view);
    }];
    
    [[DLFrameManager sharedInstance] SetLogEnabled:YES];
    
    [tableView setRefreshBlock:^{
    
        DLogOut(@"refresh");
    }];
    
    [tableView setLoadMoreBlock:^{
    
        DLogOut(@"load more");
    }];
}

#pragma mark - 
#pragma mark table view 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 21;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.text = @"Cell Row";
    }
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
