//
//  ViewController.m
//  Filter
//
//  Created by tao he on 2018/1/22.
//  Copyright © 2018年 tao he. All rights reserved.
//

#import "ViewController.h"
#import "PPSSignatureView.h"
#import "CollectionViewCell.h"
#import "RiderPDFView.h"
#import <OpenGLES/EAGL.h>
#import "PDFManager.h"

#define k_Screen_Width [UIScreen mainScreen].bounds.size.width
#define k_Screen_Height [UIScreen mainScreen].bounds.size.height

static NSString *pdfCollectionCellReusedId = @"pdfCollectionCell";


@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,
                            UICollectionViewDelegateFlowLayout,UIScrollViewDelegate,
                            collectionCellDelegate>

// 存储 RiderPDFView PDF视图
@property(nonatomic,strong)NSMutableArray<RiderPDFView *>  *dataArray;
// 存数据的数组,为了保存结构体 CGPDFPageRef,将 CGPDFPageRef 转换为NSValue
@property(nonatomic,strong)NSMutableArray<NSValue *>        *pages;
// 一共有多少页
@property(nonatomic,assign)int                              totalPage;
// 手绘图层
@property (nonatomic,strong) PPSSignatureView               *signatureView;
@end


@implementation ViewController{
    @private
    UICollectionView *pdfCollectionView; //  展示用的CollectionView
    CGPDFDocumentRef docRef;             //  需要获取的PDF资源文件
    NSInteger        currentPage;        //  当前操作的PDF页
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //通过pdfRefByDataByUrl函数获取PDF文件资源，
    self->docRef = pdfRefByDataByUrl(@"http://teaching.csse.uwa.edu.au/units/CITS4401/practicals/James1_files/SPMP1.pdf");
    //获取需要展示的数据
    [self getDataArrayValue];
    [self configCollectionView];
    [self configTestUI];
}


#pragma mark - 创建分页展示 pdf 的网格视图
-(void)configCollectionView{
    UICollectionViewFlowLayout*layout = [[UICollectionViewFlowLayout alloc]init];
    layout.itemSize=self.view.frame.size;
    [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
    layout.minimumLineSpacing=0;
    layout.minimumInteritemSpacing=0;
    
    self->pdfCollectionView= [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:layout];
    self->pdfCollectionView.bounces = NO;
    self->pdfCollectionView.pagingEnabled=YES;
    [self->pdfCollectionView registerClass:[CollectionViewCell class]forCellWithReuseIdentifier:pdfCollectionCellReusedId];
    self->pdfCollectionView.delegate=self;
    self->pdfCollectionView.dataSource=self;
    [self.view addSubview:self->pdfCollectionView];
}


#pragma mark - 创建基本测试UI
-(void)configTestUI{
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(k_Screen_Width - 90, 60, 80, 30)];
    [saveButton setBackgroundColor:[UIColor purpleColor]];
    [saveButton setTitle:@"保存" forState:UIControlStateNormal];
    saveButton.tag = 0;
    [saveButton addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
    UIButton *signatureButton = [[UIButton alloc] initWithFrame:CGRectMake(k_Screen_Width/2.f - 40, 60, 80, 30)];
    [signatureButton setBackgroundColor:[UIColor greenColor]];
    [signatureButton setTitle:@"签名" forState:UIControlStateNormal];
    [signatureButton addTarget:self action:@selector(signature) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:signatureButton];
    
    UIButton *cancleButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 60, 80, 30)];
    [cancleButton setBackgroundColor:[UIColor orangeColor]];
    [cancleButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancleButton];
}


#pragma mark - 取消点击
-(void)cancle{
    [self.signatureView erase];
    [self.signatureView removeFromSuperview];
}


#pragma mark - 签名点击,添加手绘图层
-(void)signature{
    UIView *signatureSuperView = [self.signatureView superview];
    
    RiderPDFView *currentRiderPDFView = self.dataArray[self->currentPage];
    
    self.signatureView.frame = currentRiderPDFView.bounds;
    
    if (signatureSuperView && (![currentRiderPDFView isEqual:self.dataArray[self->currentPage]])) {
        [self.signatureView removeFromSuperview];
    }
    [currentRiderPDFView addSubview:self.signatureView];
}


#pragma mark - 保存点击
-(void)save:(UIButton *)sender{
    // 当前页PDF视图
    RiderPDFView *currentRiderPDFView = self.dataArray[self->currentPage];
    // RiderPDFView 截图并绘制成image
    UIImage *signatureImage = [self snapViewToImage:currentRiderPDFView];
    // 将image转换成 CGPDFPageRef 并替换对应原始PDFPages(self.pages)
    CGPDFPageRef currentPageRef = [self imageToPDFPageRef:signatureImage];
    // 将 CGPDFPageRef 转换成 NSValue 以便于在集合中存储
    NSValue *currentPageValue = [NSValue value:&currentPageRef withObjCType:@encode(CGPDFPageRef)];
    // 执行替换
    [self.pages replaceObjectAtIndex:self->currentPage withObject:currentPageValue];
    // 若是多页面操作,在所有页面操作完成之后调用 reSavePDF 即可
    NSString *filePath = [self reSavePDF:self.pages];
    NSLog(@"保存地址: %@",filePath);
}


#pragma mark - 重新生成PDF文件,返回新文件地址
-(NSString *)reSavePDF:(NSArray <NSValue *> *)pdfPages{
        // 新生成PDF文件路径
        NSString *fileName = [NSString stringWithFormat:@"公文%d.pdf",arc4random_uniform(100)];
        NSString *pdfPathOutput = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];

        CFURLRef pdfURLOutput = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:pdfPathOutput]);
        // Create the output context
        CGContextRef writeContext = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);
    
        CGRect mediaBox;
        CGPDFPageRef tempref;
        // 写入文件
        for (int i = 0; i < pdfPages.count; i++) {
            
            [[pdfPages objectAtIndex:i] getValue:&tempref];
         
            mediaBox = CGPDFPageGetBoxRect(tempref, kCGPDFMediaBox);
            
            CGContextBeginPage(writeContext, &mediaBox);
            
            CGContextDrawPDFPage(writeContext, tempref);
            
            CGContextEndPage(writeContext);
        }
    
        CFRelease(pdfURLOutput);
        CGPDFContextClose(writeContext);
        CGContextRelease(writeContext);
    
        return pdfPathOutput;
}


#pragma mark - view转image
-(UIImage *)snapViewToImage:(UIView *)view{
    
        CGSize size = view.bounds.size;
    
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
        CGContextRef context = UIGraphicsGetCurrentContext();
    
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, window.center.x, window.center.y);
            CGContextConcatCTM(context, window.transform);
            CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
            
            if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                
                [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
                
            } else {
                
                [view.layer renderInContext:context];
            }
            CGContextRestoreGState(context);
        }
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
}


#pragma mark - image转CGPDFPageRef
-(CGPDFPageRef)imageToPDFPageRef:(UIImage *)image{
    
    [PDFManager createPDFFileWithSrc:UIImageJPEGRepresentation(image, 1.0) toDestFile:@"test.pdf" withPassword:nil];
    NSString *path = [PDFManager pdfDestPath:@"test.pdf"];
    CGPDFDocumentRef newPDFRef =  pdfRefByFilePath(path);
//    size_t pageSize = CGPDFDocumentGetNumberOfPages(newPDFRef);
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(newPDFRef, 1);
    NSLog(@"绘制的PDF页:%@",path);
    return pageRef;
}


#pragma mark - 加载网络PDF文件
CGPDFDocumentRef pdfRefByDataByUrl(NSString *fileName) {
    NSURL*url       = [NSURL URLWithString:fileName];
    CFURLRef refURL = (__bridge_retained CFURLRef)url;
    CGPDFDocumentRef document =CGPDFDocumentCreateWithURL(refURL);
//    CGDataProviderRelease(document);
    CFRelease(refURL);
    return document;
}


#pragma mark - 加载本地PDF文件
 CGPDFDocumentRef pdfRefByFilePath(NSString *aFilePath) {
     CFStringRef path;
     CFURLRef url;
     CGPDFDocumentRef document;

     path = CFStringCreateWithCString(NULL, [aFilePath UTF8String], kCFStringEncodingUTF8);
     url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, NO);
     document = CGPDFDocumentCreateWithURL(url);

     CFRelease(path);
     CFRelease(url);
     
     return document;
}


#pragma mark -  获取所有需要显示的PDF所有页面数据
- (void)getDataArrayValue {
    //获取总页数(注意,该页数从1开始)
    size_t totalPages = CGPDFDocumentGetNumberOfPages(self->docRef);
    self.totalPage    = (int)totalPages;

    for(int i = 1; i <= totalPages; i++) {
    
        CGPDFPageRef pageRef = CGPDFDocumentGetPage(self->docRef,i);
        CGRect pageRect      = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
        // CGPDFPageRef 转 NSValue
        NSValue *pageValue   = [NSValue valueWithBytes:&pageRef objCType:@encode(CGPDFPageRef)];
        
        [self.pages addObject:pageValue];
        
        RiderPDFView *view = [[RiderPDFView alloc]initWithFrame:CGRectMake(0,0,pageRect.size.width,self.view.frame.size.height) documentRef: self->docRef andPageNum:i];
        
        [self.dataArray addObject:view];
    }
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.totalPage;
}


- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    return ({
        CollectionViewCell*cell = [collectionView dequeueReusableCellWithReuseIdentifier:pdfCollectionCellReusedId forIndexPath:indexPath];
        cell.cellTapDelegate    =   self;//设置tap事件代理
        cell.showView           =   self.dataArray[indexPath.row];//赋值，设置每个item中显示的内容
        cell;
    });
}


-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    self->currentPage = indexPath.row;
}


#pragma mark - 某一页PDF被点击,根据个人需求写实现即可
- (void)collectioncellTaped:(CollectionViewCell*)cell {
    NSLog(@"点我干啥 ? ");
}


#pragma mark -  当某个item不在当前视图中显示的时候，将它的缩放比例还原 --
- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
    
    for(UIView *view in self->pdfCollectionView.subviews) {
        
        if([view isKindOfClass:[CollectionViewCell class]]) {
            CollectionViewCell*cell = (CollectionViewCell*)view;
            [cell.contentScrollView setZoomScale:1.0];
        }
    }
}


-(NSMutableArray<RiderPDFView *> *)dataArray{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}


#pragma mark - 加载 PPSSignatureView
-(PPSSignatureView*)signatureView{
    
    if (!_signatureView) {
        EAGLContext *context            = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _signatureView                  = [[PPSSignatureView alloc] initWithFrame:CGRectMake(10, 80, 300, 300) context:context];
        _signatureView.backgroundColor  = [UIColor clearColor];
        _signatureView.strokeColor      = [UIColor redColor];
        GLKViewController *glkView      = [[GLKViewController alloc] init];
        glkView.view                    = _signatureView;
        [self addChildViewController:glkView];
    }
    return _signatureView;
}


-(NSMutableArray<NSValue *> *)pages{
    if (!_pages) {
        _pages = [NSMutableArray array];
    }
    return _pages;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
