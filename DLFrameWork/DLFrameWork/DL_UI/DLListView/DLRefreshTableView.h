//
//  DLRefreshTableView.h
//  
//
//  Created by XueYulun on 15/7/10.
//
//

///----------------------------------
///  @name 下拉刷新集成组建
///----------------------------------

#import <UIKit/UIKit.h>

typedef void(^RefreshDataBlock)();
typedef void(^LoadMoreBlock)();

@interface DLRefreshTableView : UITableView

// @ 实现下拉刷新的Block
@prop_copy(RefreshDataBlock, refreshBlock);

// @ 实现上拉加载的Block
@prop_copy(LoadMoreBlock, loadMoreBlock);

// $ 停止刷新
- (void)stopLoading;

@prop_strong(UIView *, noDataView);

// $ 显示没数据的视图
- (void)ShowNoDataView;

// $ 隐藏没数据的视图
- (void)HideNoDataView;

@end
