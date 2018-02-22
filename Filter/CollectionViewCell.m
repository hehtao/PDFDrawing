//
//  CollectionViewCell.m
//  Filter
//
//  Created by tao he on 2018/2/8.
//  Copyright © 2018年 tao he. All rights reserved.
//

#import "CollectionViewCell.h"
#import "RiderPDFView.h"

@interface CollectionViewCell()<UIScrollViewDelegate>//遵守UISCrollViewDelegate协议，这样才能实现缩放

@end


@implementation CollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    
    if(self= [super initWithFrame:frame]) {
        _contentScrollView= [[UIScrollView alloc]initWithFrame:self.bounds];
        _contentScrollView.contentSize = frame.size;
        //设置缩放比例
        _contentScrollView.minimumZoomScale=1.0;
        _contentScrollView.maximumZoomScale=2.5;
        _contentScrollView.delegate = self;
    
        [self.contentView addSubview:_contentScrollView];
        // 单击手势
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cellClicked)];//创建手势
        [self addGestureRecognizer: tapGes];//添加手势到CollectionViewCell上
    }
    return self;
}

// 定义缩放响应视图
- (UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView {
    for(UIView*view in scrollView.subviews) {
        
        if([view isKindOfClass:[RiderPDFView class]]) {
            return view;//返回需要被缩放的视图
        }
    }
    return nil;
}


- (void)setShowView:(UIView*)showView {
    
    for(UIView *tempView in _contentScrollView.subviews) {
        //移除_contentScrollView中的所有视图
        [tempView removeFromSuperview];
    }
    _showView= showView;
    //将需要显示的视图添加到_contentScrollView上
    [_contentScrollView addSubview:showView];
}

// 代理
- (void)cellClicked {
    if ([self.cellTapDelegate respondsToSelector:@selector(collectioncellTaped:)]) {
        [self.cellTapDelegate collectioncellTaped:self];
    }
}

@end
