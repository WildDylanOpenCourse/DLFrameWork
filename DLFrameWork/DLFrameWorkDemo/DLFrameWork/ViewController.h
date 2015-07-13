//
//  ViewController.h
//  DLFrameWork
//
//  Created by XueYulun on 15/6/25.
//  Copyright (c) 2015年 __Dylan. All rights reserved.
//

#import <UIKit/UIKit.h>

// @ Model

@interface MainModel : DLModel

@property (nonatomic, strong) NSString * name;

@end

// @ View

@interface MainView : UIView

@property (nonatomic, strong) UILabel * nameLabel;

@end

// @ VM

typedef void(^responseBlock)(id obj);

@interface MainViewModel : NSObject

@property (nonatomic, strong) MainModel * model;
@property (nonatomic, copy) responseBlock response;

- (void)LoadData;

@end

// @ VC

@interface ViewController : UIViewController


@end

