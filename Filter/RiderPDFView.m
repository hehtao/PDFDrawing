//
//  RiderPDFView.m
//  Filter
//
//  Created by tao he on 2018/2/8.
//  Copyright © 2018年 tao he. All rights reserved.
//

#import "RiderPDFView.h"

@implementation RiderPDFView{
    //用它来记录传递进来的PDF资源数据
    CGPDFDocumentRef  documentRef;
    //记录需要显示页码
    int  pageNum;
}

- (instancetype)initWithFrame:(CGRect)frame documentRef:(CGPDFDocumentRef)docRef andPageNum:(int)page {
    
    self= [super initWithFrame:frame];
    self->documentRef = docRef;
    self->pageNum     = page;
    self.backgroundColor= [UIColor whiteColor];
    return self;
    
}


- (void)drawRect:(CGRect)rect {
    [self drawPDFIncontext:UIGraphicsGetCurrentContext()];
}

- (void)drawPDFIncontext:(CGContextRef)context {
    
    CGContextTranslateCTM(context,0.0,self.frame.size.height);
    
    CGContextScaleCTM(context,1.0, -1.0);
    
    //上面两句是对环境做一个仿射变换，如果不执行上面两句那么绘制出来的PDF文件会呈倒置效果，第二句的作用是使图形呈正立显示，第一句是调整图形的位置，如不执行绘制的图形会不在视图可见范围内
    
    
    //获取需要绘制的页码的数据。两个参数，第一个数传递进来的PDF资源数据，第二个是传递进来的需要显示的页码
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(self->documentRef,self->pageNum);

    //记录当前绘制环境，防止多次绘画
    CGContextSaveGState(context);
    
    //创建一个仿射变换的参数给函数。第一个参数是对应页数据；第二个参数是个枚举值，我每个都试了一下，貌似没什么区别……但是网上看的资料都用的我当前这个，所以就用这个了；第三个参数，是图形绘制的区域，我设置的是当前视图整个区域，如果有需要，自然是可以修改的；第四个是旋转的度数，这里不需要旋转了，所以设置为0；第5个，传递true，会保持长宽比
    CGAffineTransform pdfTransForm =CGPDFPageGetDrawingTransform(pageRef,kCGPDFCropBox,self.bounds,0,true);
    //把创建的仿射变换参数和上下文环境联系起来
    CGContextConcatCTM(context, pdfTransForm);
    //把得到的指定页的PDF数据绘制到视图上
    CGContextDrawPDFPage(context, pageRef);
    //恢复图形状态
    CGContextRestoreGState(context);
}

@end
