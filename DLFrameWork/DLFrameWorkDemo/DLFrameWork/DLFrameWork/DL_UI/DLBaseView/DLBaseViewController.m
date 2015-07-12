//
//  DLBaseViewController.m
//  
//
//  Created by XueYulun on 15/7/12.
//
//

#import "DLBaseViewController.h"

@interface DLBaseViewController ()

@end

@implementation DLBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSString *)identifier {
    
    return NSStringFromClass([self class]);
}

@end
