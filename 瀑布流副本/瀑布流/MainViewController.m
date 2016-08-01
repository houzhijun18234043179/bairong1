//
//  MainViewController.m
//  瀑布流
//
//  Created by apple on 13-10-14.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MainViewController.h"
#import "WaterFlowCellView.h"
#import "MGJData.h"
#import "UIImageView+WebCache.h"
#import "PhotoBowserViewController.h"

@interface MainViewController ()

// 数据列表
@property (strong, nonatomic) NSMutableArray *dataList;
// 当前显示列数
@property (assign, nonatomic) NSInteger dataColumns;

#pragma mark - 加载网络数据属性
// 当前是否正在加载数据
@property (assign, nonatomic) BOOL isLoadingData;
// 当前加载字符串数据的索引
@property (assign, nonatomic) NSInteger dataIndex;

@end

@implementation MainViewController

#pragma mark - 私有方法
#pragma mark 加载本地数据
- (void)loadLocalMGJData
{
    self.isLoadingData = YES;
    
    // 设置plist文件名
    NSString *fileName = [NSString stringWithFormat:@"mogujie%02d", self.dataIndex];
    NSString *filePath = [[NSBundle mainBundle]pathForResource:fileName ofType:@"plist"];
    
    // 如果文件不存在，filePath = nil
    if (filePath == nil) {
        NSLog(@"没有新数据");
        return;
    }
    
    NSLog(@"加载数据 %d", self.dataIndex);
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSArray *array = dict[@"result"][@"list"];
    
    if (self.dataList == nil) {
        self.dataList = [NSMutableArray array];
    }
    
    // 对self.dataList直接进行拼接
    for (NSDictionary *dict in array) {
        NSDictionary *showDict = dict[@"show"];
        
        MGJData *data = [[MGJData alloc]init];
        [data setValuesForKeysWithDictionary:showDict];
        
        // 设置大图URL
        NSDictionary *largeDict = dict[@"showLarge"];
        [data setLargeImageUrl:[NSURL URLWithString:largeDict[@"img"]]];
        
        [self.dataList addObject:data];
    }
    
    // 重新刷新数据
    self.isLoadingData = NO;
    
    // 避免初次加载数据时，重复刷新
    if (self.dataIndex > 0) {
        [self.waterFlowView reloadData];
    }

    self.dataIndex++;
}

#pragma mark 加载蘑菇街数据
- (void)loadMGJData
{
    self.isLoadingData = YES;
    
    // 0. 加载沙箱中的查询字符串
    NSURL *localUrl = [[NSBundle mainBundle]URLForResource:@"UrlList" withExtension:@"plist"];
    NSArray *strArray = [NSArray arrayWithContentsOfURL:localUrl];
    
    if (self.dataIndex == strArray.count) {
        NSLog(@"没有找到新数据，请稍后再试！");
        
        self.isLoadingData = NO;
        
        return;
    }     
    // 1. NSString
    NSString *urlStr = nil;
    
    if (self.dataList == 0) {
        urlStr = [NSString stringWithFormat:@"http://www.mogujie.com/app_mgj_v511_book/clothing?_adid=5503509D-800B-45EF-B767-F6586FFF165E&_did=0f607264fc6318a92b9e13c65db7cd3c&_atype=iPhone&_source=NIMAppStore511&_fs=NIMAppStore511&_swidth=640&_network=2&_mgj=%@&title=最热&from=hot_element&login=false&fcid=6550&q=最热&track_id=1377824666&homeType=shopping", strArray[self.dataIndex]];
    } else {
        urlStr = [NSString stringWithFormat:@"http://www.mogujie.com/app_mgj_v511_book/clothing?_adid=5503509D-800B-45EF-B767-F6586FFF165E&_did=0f607264fc6318a92b9e13c65db7cd3c&_atype=iPhone&_source=NIMAppStore511&_fs=NIMAppStore511&_swidth=640&_network=2&_mgj=%@&title=最热&mbook=eyJxIjoiXCJcdTY3MDBcdTcwZWRcIiIsInFfbmF0dXJhbCI6Ilx1NjcwMFx1NzBlZCIsInNvcnQiOiJob3Q3ZGF5IiwiY2Jvb2siOjEsImFjdGlvbiI6ImNsb3RoaW5nIiwicGFnZSI6NCwidHlwZSI6ImFsbCIsImNnb29kcyI6MSwidGltZV9mYWN0b3IiOiIxNV81IiwiZmNpZCI6IjY1NTAiLCJpc19hZF9uZXciOjAsImlzRmlsdGVyIjp0cnVlLCJwZXJwYWdlIjo1MH0%@3D&from=hot_element&login=false&fcid=6550&q=最热&track_id=1377824666&homeType=shopping", strArray[self.dataIndex], @"%"];
    }
    
    // 2. 修改属性
    self.dataIndex++;
    
    // 3. NSURL
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // 4. 此时用同步还是异步呢？用同步可以让用户进入界面稍等几秒即可看到数据
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    // 5. JSON
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSArray *array = dict[@"result"][@"list"];
    
    if (self.dataList == nil) {
        self.dataList = [NSMutableArray array];
    }
    
    // 对self.dataList直接进行拼接
    for (NSDictionary *dict in array) {
        NSDictionary *showDict = dict[@"show"];
        
        MGJData *data = [[MGJData alloc]init];
        [data setValuesForKeysWithDictionary:showDict];
        
        [self.dataList addObject:data];
    }
    
    // 重新刷新数据
    self.isLoadingData = NO;
    [self.waterFlowView reloadData];
    
    // 2. 强烈提醒，需要测试
//    NSLog(@"%@", self.dataList);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self loadMGJData];

    [self loadLocalMGJData];
}

#pragma mark 从某个方向旋转设备
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // 如果发生设备旋转，重新加载数据
    [self.waterFlowView reloadData];
}

#pragma mark - 数据源方法
#pragma mark - 列数
- (NSInteger)numberOfColumnsInWaterFlowView:(WaterFlowView *)waterFlowView
{
    // 可以根据设备的当前方向，设定要显示的数据列数
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        
        self.dataColumns = 4;
    } else {
        self.dataColumns = 3;
    }
    
    return self.dataColumns;
}

#pragma mark - 行数
- (NSInteger)waterFlowView:(WaterFlowView *)waterFlowView numberOfRowsInColumns:(NSInteger)columns
{
    return self.dataList.count;
}

- (WaterFlowCellView *)waterFlowView:(WaterFlowView *)waterFlowView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"MyCell";
    
    WaterFlowCellView *cell = [waterFlowView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[WaterFlowCellView alloc]initWithResueIdentifier:ID];
    }
    
    // 设置cell
    MGJData *data = self.dataList[indexPath.row];
    
    [cell.textLabel setText:data.price];
    
    // 异步加载图像
    /*
     提示，使用SDWebImage可以指定缓存策略，包括内存缓存 并 磁盘缓存
     */
    [cell.imageView setImageWithURL:data.img];
    
    return cell;
}

#pragma mark - 每个单元格的高度
- (CGFloat)waterFlowView:(WaterFlowView *)waterFlowView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MGJData *data = self.dataList[indexPath.row];
    
    // 计算图像的高度
    // 例如：h = 275 w = 200 目前的宽度是 320 / 3 = 106.667
    CGFloat colWidth = self.view.bounds.size.width / self.dataColumns;
    
    return colWidth / data.w * data.h;
}

#pragma mark - 选中单元格
- (void)waterFlowView:(WaterFlowView *)waterFlowView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"选中单元格： %@", indexPath);
    
//    MGJData *data = self.dataList[indexPath.row];
    // 取大图URL，异步加载并显示相册
    [self showPhotos:indexPath];
}

#pragma mark - 刷新网络数据
- (void)waterFlowViewRefreshData:(WaterFlowView *)waterFlowView
{
    NSLog(@"加载数据。。。");
    
    // 1. 如果当前正在刷新数据，则不在执行后续方法
    if (self.isLoadingData) {
        return;
    }
    
    [self loadLocalMGJData];
}

#pragma mark - 显示照片浏览器
- (void)showPhotos:(NSIndexPath *)indexPath
{
    PhotoBowserViewController *controller = [[PhotoBowserViewController alloc]init];
    
    // 设置照片数组
    NSMutableArray *arrayM = [NSMutableArray arrayWithCapacity:_dataList.count];
    
    NSInteger index = 0;
    for (MGJData *data in _dataList) {
        // 是瀑布流视图在瀑布流的滚动视图中的位置，坐标值中是包含contentOffset
        CGRect frame = [self.waterFlowView.cellFramesArray[index]CGRectValue];
        // 需要将瀑布流视图的坐标转换到照片查看器的坐标
        // 在不同视图之间传递坐标时，是需要坐标转换的！
        CGRect srcFrame = [self.waterFlowView convertRect:frame toView:controller.view];
        
        PhotoModel *p = [PhotoModel photoWithURL:data.largeImageUrl index:index srcFrame:srcFrame];
        
        [arrayM addObject:p];
        
        index++;
    }
    [controller setPhotoList:arrayM];
    [controller setCurrentIndex:indexPath.row];
    
    [controller show];
}

@end
