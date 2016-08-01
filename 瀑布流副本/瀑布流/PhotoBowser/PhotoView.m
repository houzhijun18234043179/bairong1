//
//  PhotoView.m
//  瀑布流
//
//  Created by apple on 13-10-18.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "PhotoView.h"
#import "UIImageView+WebCache.h"

/*
 提示
 
 使用成员变量的方式，在保证变量的数据安全的前提下，性能会比使用属性要略高
 */
@interface PhotoView() <UIScrollViewDelegate>
{
    // 图像视图
    UIImageView *_imageView;
    
    // 记录是否双击
    BOOL        _isDoubleTap;
}

@end

@implementation PhotoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // 1. 设置imageView
        // 1) 实例化
        _imageView = [[UIImageView alloc]initWithFrame:frame];
        // 2) 设置图像的显示比例，按照图像的显示比例显示
        [_imageView setContentMode:UIViewContentModeScaleAspectFit];
        // 3）添加到视图
        [self addSubview:_imageView];
        
        // 2. 设置scrollView属性
        // 1） 滚动条
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        
        // 2） 设置代理，要处理滚动视图的缩放，必须要指定代理
        [self setDelegate:self];
        
        // 3. 添加双击手势监听
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
        [doubleTap setNumberOfTapsRequired:2];
        [self addGestureRecognizer:doubleTap];
        
        // 4. 添加单击手势监听
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap)];
        [singleTap setNumberOfTapsRequired:1];
        [self addGestureRecognizer:singleTap];
    }
    
    return self;
}

#pragma mark 双击事件
- (void)doubleTap:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"双击");
    _isDoubleTap = YES;
    
    // 如果图像视图放大到两倍，还原初始大小
    if (self.zoomScale == self.maximumZoomScale) {
        [self setZoomScale:1.0f animated:YES];
    } else {
        // 否则，从手势触摸位置开始放大
        CGPoint location = [recognizer locationInView:self];
        [self zoomToRect:CGRectMake(location.x, location.y, 1, 1) animated:YES];
    }
}

#pragma mark 单击事件
- (void)hideMe
{
    if (_isDoubleTap) {
        return;
    }
    
    // 1. 缩小图像到初始位置
    [UIView animateWithDuration:1.0f animations:^{
        [_imageView setFrame:_photo.srcFrame];

        // 动画过程中，背景视图透明
        [self.photoDelegate photoViewSingleTap:self];
    } completion:^(BOOL finished) {
        // 动画完成后，通知代理从window中删除
        // 2. 关闭视图控制器
        [self.photoDelegate photoViewZoomOut:self];
    }];
}

// 因为ScrollView默认支持多手势操作，不能直接使用touchBegan方法
- (void)singleTap
{
    _isDoubleTap = NO;
    
    NSLog(@"单击");
    
    [self performSelector:@selector(hideMe) withObject:nil afterDelay:0.2f];
}

#pragma mark - photo setter方法
/*
 SDWebImage缓存选项，默认采用磁盘缓存
 提示：如果使用磁盘缓存，需要有相应的功能提示或者帮助用户清除缓存
 
 * 加载失败后重试
 SDWebImageRetryFailed = 1 << 0,
 
 * 低优先级加载图像
 SDWebImageLowPriority = 1 << 1,
 
 * 仅使用内存缓存，而不使用磁盘缓存
 SDWebImageCacheMemoryOnly = 1 << 2,
 
 * 边下载边显示
 SDWebImageProgressiveDownload = 1 << 3,

 * 刷新已经缓存过的图像
 SDWebImageRefreshCached = 1 << 4
 */
- (void)setPhoto:(PhotoModel *)photo
{
    _photo = photo;
    
    // 如果图像已经存在，就不需要去网络上加载
    if (photo.image) {
        [_imageView setImage:photo.image];
        
        [self adjustFrame];
    } else {
        // 实例化一个空的UIImage，通常在应用中，美工会给我们提供占位图像素材
        UIImage *image = [[UIImage alloc]init];
        
        // 要在block中使用self本类，需要使用__unsafe_unretained描述符定义本类对象
        __unsafe_unretained PhotoView *photoView = self;
        
        // 提示占位图像不能使用nil
        [_imageView setImageWithURL:photo.imageUrl placeholderImage:image options:SDWebImageCacheMemoryOnly | SDWebImageDownloaderProgressiveDownload progress:^(NSUInteger receivedSize, long long expectedSize) {
            // 下载进度
            // 可以自定义一个下载进度的视图，譬如“小菊花”
            // receivedSize / expectedSize 得到的百分比去设置下载比例即可
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            // 下载完成
            // 在block中不能直接对self本类的属性进行赋值
            photoView.photo.image = image;
            
            [photoView adjustFrame];
        }];
    }
}

#pragma mark - 缩放图像
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

#pragma mark - 调整图像边框
// 根据图像大小和屏幕大小去计算合适的显示比例(针对图像和屏幕的宽、高进行计算和比较)
- (void)adjustFrame
{
    // 1. 定义计算参考值
    CGFloat viewW = self.bounds.size.width;
    CGFloat viewH = self.bounds.size.height;
    
    CGFloat imageW = _imageView.image.size.width;
    CGFloat imageH = _imageView.image.size.height;
    
    // 2. 调整图像的思路
    // 1) 如果图像的宽高都分别小于视图的宽高，将图像设置在屏幕中心位置即可
    // 2) 如果图像的宽度小于屏幕宽度，高度大于屏幕高度
    //    不调整图像大小，让图像的顶端与视图顶端对齐，并且设置滚动区域，保证能够滚动查看图像内容
    // 3) 宽度和高度都超过屏幕宽高
    //    缩放图像的宽度，与屏幕宽度一致，高度按比例调整
    //      调整后的高度如果小于屏幕高度，图像居中
    //      调整后的高度如果大于屏幕高度，图像置顶
    
    // 2. 计算缩放比例
    CGFloat scale = viewW / imageW;
    // 如果scale > 1.0 说明图像宽度小于视图宽度，可以不用考虑图像宽度
    if (scale < 1.0) {
        // 计算图像新的高度和宽度
        imageH *= scale;
        imageW = viewW;
    }
    
    CGRect imageFrame = CGRectMake(0, 0, viewW, imageH);
    
    if (imageH < viewH) {
        imageFrame.origin.y = (viewH - imageH) / 2.0;
    } else {
        // 设置滚动区域
        [self setContentSize:CGSizeMake(viewW, imageH)];
    }
    
    if (_photo.firstShow) {
        [_imageView setFrame:_photo.srcFrame];
        
        [UIView animateWithDuration:0.3f animations:^{
            [_imageView setFrame:imageFrame];
        }];
    } else {
        [_imageView setFrame:imageFrame];
    }
    
    // 3. 设置缩放比例
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 2.0;
}

@end
