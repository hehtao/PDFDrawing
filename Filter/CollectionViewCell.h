//
//  CollectionViewCell.h
//  Filter
//
//  Created by tao he on 2018/2/8.
//  Copyright © 2018年 tao he. All rights reserved.
//

#import <UIKit/UIKit.h>


@class  CollectionViewCell;

@protocol collectionCellDelegate<NSObject>

@optional
- (void)collectioncellTaped:(CollectionViewCell *)cell;
@end


@interface CollectionViewCell : UICollectionViewCell

@property(nonatomic,strong) UIScrollView *contentScrollView; //用于实现缩放功能的UISCrollView

/**
 * 这个就是显示PDF文件某一页内容的视图
 */
@property(nonatomic,strong) UIView *showView;
@property(nonatomic,weak) id<collectionCellDelegate>        cellTapDelegate;


@end
