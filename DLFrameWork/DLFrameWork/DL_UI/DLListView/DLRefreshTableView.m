//
//  DLRefreshTableView.m
//
//
//  Created by XueYulun on 15/7/10.
//
//

#import "DLRefreshTableView.h"

@interface DLRefreshTableView () {
    
    BOOL _refreshInited;
}

@end

@implementation DLRefreshTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    
    self = [super initWithFrame:frame style:style];
    if (self) {
        
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    
    if (NO == _refreshInited) {
        
        @weakify(self);
        [self ins_addPullToRefreshWithHeight:60.0 handler:^( UIScrollView * scrollView ) {
            
            @strongify(self);
            
            if (self.refreshBlock) {
                
                self.refreshBlock();
            }
        }];
        
        [self ins_addInfinityScrollWithHeight:60 handler:^( UIScrollView * scrollView ) {
            
            @strongify(self);
            
            if (self.loadMoreBlock) {
                
                self.loadMoreBlock();
            }
        }];
        
        UIView<INSAnimatable> * infinityIndicator = [[INSCircleInfiniteIndicator alloc] initWithFrame:CGRectMake(0, 0, 24.0f, 24.0f)];
        UIView<INSPullToRefreshBackgroundViewDelegate> * pullToRefresh = [[INSCirclePullToRefresh alloc] initWithFrame:CGRectMake(0, 0, 24.0f, 24.0f)];
        
        self.ins_infiniteScrollBackgroundView.preserveContentInset = NO;
        [self.ins_infiniteScrollBackgroundView addSubview:infinityIndicator];
        
        self.ins_pullToRefreshBackgroundView.delegate = pullToRefresh;
        self.ins_pullToRefreshBackgroundView.preserveContentInset = NO;
        [self.ins_pullToRefreshBackgroundView addSubview:pullToRefresh];
        
        [infinityIndicator startAnimating];
        
        _refreshInited = YES;
    }
}

- (void)stopLoading {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(stopLoadingDelayed) withObject:nil afterDelay:0.1f];
}

- (void)stopLoadingDelayed {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self ins_endInfinityScroll];
    [self ins_endPullToRefresh];
}

- (void)dealloc {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [_noDataView removeFromSuperview];
    [self ins_removeInfinityScroll];
    [self ins_removePullToRefresh];
}

- (void)setNoDataView:(UIView *)noDataView {
    
    if (_noDataView) {
        
        [_noDataView removeFromSuperview];
    }
    
    _noDataView = noDataView;
    _noDataView.hidden = YES;
    [self addSubview:_noDataView];
}

- (void)ShowNoDataView {
    
    _noDataView.hidden = NO;
}

- (void)HideNoDataView {
    
    _noDataView.hidden = YES;
}

@end
