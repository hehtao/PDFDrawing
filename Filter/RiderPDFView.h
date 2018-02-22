//
//  RiderPDFView.h
//  Filter
//
//  Created by tao he on 2018/2/8.
//  Copyright © 2018年 tao he. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RiderPDFView : UIView

/**
 创建显示PDF指定页内容的的视图

 @param frame 视图frame
 @param docRef PDF文件内容(CGPDFDocumentRef)
 @param page 要显示第几页PDF内容
 @return View视图
 */
- (instancetype)initWithFrame:(CGRect)frame documentRef:(CGPDFDocumentRef)docRef andPageNum:(int)page;

@end
