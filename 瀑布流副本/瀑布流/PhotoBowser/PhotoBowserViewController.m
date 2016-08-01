//
//  PhotoBowserViewController.m
//  瀑布流
//
//  Created by apple on 13-10-18.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "PhotoBowserViewController.h"

@interface PhotoBowserViewController ()
{
    // 上级窗体状态栏隐藏状态
    BOOL    _parentStatusBarHidden;
}

@end

@implementation PhotoBowserViewController
/*
 1. 解耦
    照片浏览器，这个功能是非常普遍的，要实现本视图控制器尽可能与其他视图控制器的解耦，即耦合度不要太高
 2. 状态栏
    因为不同的应用程序状态栏显示的情况不同，在初始化视图时，记录住状态栏的显示情况，退出时恢复状态栏状态
 3. 数据
    由调用方传入PhotoModel的数组，包含要显示图像的url，从而可以独立加载显示
 */

- (void)loadView
{
    // 1. 全屏显示
    // 1) 记录上级视图状态栏显示情况
    _parentStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    // 2) 隐藏状态栏，实现全屏显示显示
    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    // 2. 实例化UIScrollView
    // 1) 实例化
    UIScrollView *scroll = [[UIScrollView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    // 2) 背景颜色
    [scroll setBackgroundColor:[UIColor blackColor]];
    // 3) 隐藏滚动条
    [scroll setShowsHorizontalScrollIndicator:NO];
    [scroll setShowsVerticalScrollIndicator:NO];
    // 4) 允许分页
    [scroll setPagingEnabled:YES];
    
    // 将滚动视图作为根视图
    self.view = scroll;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 添加手势监听
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapView)];
//    [self.view addGestureRecognizer:tap];
}

#pragma mark - 照片视图代理方法
- (void)photoViewSingleTap:(PhotoView *)photoView
{
    // 清除照片视图控制器
    // 0) 恢复状态栏
    [[UIApplication sharedApplication]setStatusBarHidden:_parentStatusBarHidden withAnimation:UIStatusBarAnimationFade];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
}

- (void)photoViewZoomOut:(PhotoView *)photoView
{
    // 1) 清除根视图
    [self.view removeFromSuperview];
    // 2) 清除子视图控制器
    [self removeFromParentViewController];
    
}

#warning 测试视图消失
- (void)tapView
{
    
}

#pragma mark - 成员方法
- (void)show
{
    // 借助UIApplication中的window
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *window = app.keyWindow;
    // 将根视图添加到window中
    [window addSubview:self.view];
    // 记录住视图控制器
    [window.rootViewController addChildViewController:self];
    
    // 显示照片视图
    [self showPhoto];
}

#pragma mark - 私有方法
#pragma mark 显示照片视图
- (void)showPhoto
{
    // 首先先实现一张照片的显示工作
    PhotoView *photoView = [[PhotoView alloc]initWithFrame:self.view.bounds];
    
    PhotoModel *photoModel = _photoList[_currentIndex];
    
    [photoView setPhoto:photoModel];
    [photoView setPhotoDelegate:self];
    
    [self.view addSubview:photoView];
}

@end
