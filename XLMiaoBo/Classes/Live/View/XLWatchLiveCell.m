
//
//  XLWatchLiveCell.m
//  XLMiaoBo
//
//  Created by XuLi on 16/8/31.
//  Copyright © 2016年 XuLi. All rights reserved.
//

#import "XLWatchLiveCell.h"
#import "XLBottomToolView.h"
#import "XLAnchorInfoView.h"
#import "XLCatEarView.h"
#import "XLLiveEndView.h"
#import "BarrageRenderer.h"
#import "UIViewController+Extension.h"
#import "XLUserInfoView.h"
#import "NSSafeObject.h"
#import "XLLiveTool.h"
#import "UMSocial.h"

@interface XLWatchLiveCell ()
{
    BarrageRenderer *_renderer;
    NSTimer * _timer;
}
/** 直播播放器 */
@property (nonatomic, strong) IJKFFMoviePlayerController *moviePlayer;
/** 底部的工具栏 */
@property(nonatomic, weak) XLBottomToolView *bottomToolView;
/** 顶部主播相关视图 */
@property(nonatomic, weak) XLAnchorInfoView *anchorView;
/** 同类型直播视图 */
@property(nonatomic, weak) XLCatEarView *catEarView;
/** 同一个工会的主播/相关主播 */
@property(nonatomic, weak) UIImageView *otherView;
/** 直播开始前的占位图片 */
@property(nonatomic, weak) UIImageView *placeHolderView;
/** 粒子动画 */
@property(nonatomic, weak) CAEmitterLayer *emitterLayer;
/** 直播结束的界面 */
@property (nonatomic, weak) XLLiveEndView *endView;

@property (nonatomic, weak) XLUserInfoView *userinfoView;

@property (nonatomic, assign) BOOL hidden;
@end

@implementation XLWatchLiveCell
- (UIImageView *)placeHolderView
{
    if (_placeHolderView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = self.contentView.bounds;
            
        imageView.image = [UIImage imageNamed:@"profile_user_414x414"];

        [self.contentView addSubview:imageView];
        [self.parentVC showGifLoding:nil inView:imageView];
        _placeHolderView = imageView;
        // 强制布局
        [_placeHolderView layoutIfNeeded];
    }
    return _placeHolderView;
}

- (XLBottomToolView *)bottomToolView
{
    if (_bottomToolView == nil) {
        
        self.hidden = NO;
        
        XLBottomToolView *bottomToolView = [[XLBottomToolView alloc] init];
        
        [bottomToolView setClickToolBlock:^(NSInteger tag) {
            
            switch (tag) {
                case 0:
                
                self.hidden = !self.hidden;
                self.hidden ? [_renderer start] : [_renderer stop];
                    break;
                    
                case 4:
                    
                    [self shareMethod];
                    break;
                    
                case 5:
                    
                    [self quit];
                    
                    break;
                default:
                    break;
            }
        }];
        
        
        [self.contentView insertSubview:bottomToolView aboveSubview:self.placeHolderView];
        
        [bottomToolView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(@0);
            make.bottom.equalTo(@-10);
            make.height.equalTo(@40);
        }];
        _bottomToolView = bottomToolView;
    }
    return _bottomToolView;
}

- (UIImageView *)otherView
{
    if (!_otherView) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"private_icon_70x70"]];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOther)]];
        [self.moviePlayer.view addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.catEarView);
            make.bottom.equalTo(self.catEarView.mas_top).offset(-40);
        }];
        _otherView = imageView;
    }
    return _otherView;
}

- (XLAnchorInfoView *)anchorView
{
    if (!_anchorView) {
        XLAnchorInfoView *anchorView = [XLAnchorInfoView anchorInfoView];
        
        [anchorView setSelectBlock:^(XLHotModel *hotModel) {
            
            XLUserInfoView *userInfoView = [XLUserInfoView userInfoView];
            self.userinfoView = userInfoView;
            
            [userInfoView userWithHotModel:hotModel ofView:self.parentVC.view];
            
            userInfoView.selectedBlock = ^(){
            
               
                 self.hotModel = hotModel;
            };
        }];
        
       
        
        [self.contentView insertSubview:anchorView aboveSubview:self.placeHolderView];
        [anchorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(@0);
            make.height.equalTo(@190);
            make.top.equalTo(@0);
        }];
        _anchorView = anchorView;
    }
    return _anchorView;
}

- (XLCatEarView *)catEarView
{
    if (_catEarView == nil) {
        XLCatEarView *catEarView = [XLCatEarView catEarView];
        
        [self addSubview:catEarView];
        
        catEarView.hidden = YES;
        
        [catEarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickCatEar)]];
        [catEarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-30);
            make.centerY.equalTo(self);
            make.width.height.equalTo(@98);
        }];
        _catEarView = catEarView;
    }
    return _catEarView;
}

- (CAEmitterLayer *)emitterLayer
{
    if (!_emitterLayer) {
        CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
        // 发射器在xy平面的中心位置
        emitterLayer.emitterPosition = CGPointMake(self.moviePlayer.view.frame.size.width-50,self.moviePlayer.view.frame.size.height-50);
        // 发射器的尺寸大小
        emitterLayer.emitterSize = CGSizeMake(20, 20);
        // 渲染模式
        emitterLayer.renderMode = kCAEmitterLayerUnordered;
        // 开启三维效果
        //    _emitterLayer.preservesDepth = YES;
        NSMutableArray *array = [NSMutableArray array];
        // 创建粒子
        for (int i = 0; i<10; i++) {
            // 发射单元
            CAEmitterCell *stepCell = [CAEmitterCell emitterCell];
            // 粒子的创建速率，默认为1/s
            stepCell.birthRate = 1;
            // 粒子存活时间
            stepCell.lifetime = arc4random_uniform(4) + 1;
            // 粒子的生存时间容差
            stepCell.lifetimeRange = 1.5;
            // 颜色
            // fire.color=[[UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.1]CGColor];
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"good%d_30x30", i]];
            // 粒子显示的内容
            stepCell.contents = (id)[image CGImage];
            // 粒子的名字
            //            [fire setName:@"step%d", i];
            // 粒子的运动速度
            stepCell.velocity = arc4random_uniform(100) + 100;
            // 粒子速度的容差
            stepCell.velocityRange = 80;
            // 粒子在xy平面的发射角度
            stepCell.emissionLongitude = M_PI+M_PI_2;;
            // 粒子发射角度的容差
            stepCell.emissionRange = M_PI_2/6;
            // 缩放比例
            stepCell.scale = 0.3;
            [array addObject:stepCell];
        }
        
        emitterLayer.emitterCells = array;
        [self.moviePlayer.view.layer insertSublayer:emitterLayer below:self.catEarView.layer];
        _emitterLayer = emitterLayer;
    }
    return _emitterLayer;
}

- (XLLiveEndView *)endView
{
    if (!_endView) {
        XLLiveEndView *endView = [XLLiveEndView liveEndView];
        endView.hotModel = self.hotModel;
        
        [self.contentView addSubview:endView];
        [endView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        [endView setQuitBlock:^{
            [self quit];
        }];
        [endView setLookOtherBlock:^{
            [self clickCatEar];
        }];
        _endView = endView;
    }
    return _endView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.bottomToolView.hidden = NO;
        
        _renderer = [[BarrageRenderer alloc] init];
        _renderer.canvasMargin = UIEdgeInsetsMake(XLScreenH * 0.3, 10, 10, 10);

        [self.contentView addSubview:_renderer.view];
        
        NSSafeObject * safeObj = [[NSSafeObject alloc]initWithObject:self withSelector:@selector(autoSendBarrage)];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:safeObj selector:@selector(excute) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)setHotModel:(XLHotModel *)hotModel
{
    _hotModel = hotModel;
    self.anchorView.hotModel = hotModel;
    
    
    [self plarFLV:hotModel.flv placeHolderUrl:hotModel.bigpic];
    
    [self setAllModels:self.allModels];
}


#pragma mark - private method


- (void)plarFLV:(NSString *)flv placeHolderUrl:(NSString *)placeHolderUrl
{
    if (_moviePlayer) {
        if (_moviePlayer) {
            [self.contentView insertSubview:self.placeHolderView aboveSubview:self.moviePlayer.view];
        }
        if (_catEarView) {
            [_catEarView removeFromSuperview];
            _catEarView = nil;
        }
        [_moviePlayer shutdown];
        [_moviePlayer.view removeFromSuperview];
        _moviePlayer = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    // 如果切换主播, 取消之前的动画
    if (_emitterLayer) {
        [_emitterLayer removeFromSuperlayer];
        _emitterLayer = nil;
    }
    
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:placeHolderUrl] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(image){
            [self.parentVC showGifLoding:nil inView:self.placeHolderView];
            self.placeHolderView.image = [UIImage blurImage:image blur:0.8];
            }
        });
    }];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setPlayerOptionIntValue:1  forKey:@"videotoolbox"];
    
    // 帧速率(fps) （可以改，确认非标准桢率会导致音画不同步，所以只能设定为15或者29.97）
    [options setPlayerOptionIntValue:29.97 forKey:@"r"];
    // -vol——设置音量大小，256为标准音量。（要设置成两倍音量时则输入512，依此类推
    [options setPlayerOptionIntValue:512 forKey:@"vol"];
    IJKFFMoviePlayerController *moviePlayer = [[IJKFFMoviePlayerController alloc] initWithContentURLString:flv withOptions:options];
    moviePlayer.view.frame = self.contentView.bounds;
    // 填充fill
    moviePlayer.scalingMode = IJKMPMovieScalingModeAspectFill;
    // 设置自动播放(必须设置为NO, 防止自动播放, 才能更好的控制直播的状态)
    moviePlayer.shouldAutoplay = NO;
    
    [self.contentView insertSubview:moviePlayer.view atIndex:0];
    
    [moviePlayer prepareToPlay];
    
    self.moviePlayer = moviePlayer;
    
    // 设置监听
    [self initObserver];
    
    // 显示工会其他主播和类似主播
    [moviePlayer.view bringSubviewToFront:self.otherView];
    
    // 开始来访动画
    [self.emitterLayer setHidden:NO];
}


- (void)initObserver
{
    [self.moviePlayer play];
    
    //    // 监听视频是否播放完成
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinish) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateDidChange) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
}

- (void)clickOther
{
    NSLog(@"相关的主播");
}

- (void)clickCatEar
{
    self.hotModel = self.catEarView.hotModel;
}

#pragma mark - notify method

- (void)stateDidChange
{
    if ((self.moviePlayer.loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        if (!self.moviePlayer.isPlaying) {
            [self.moviePlayer play];
            
            [self.parentVC hideGufLoding];
            
            [_renderer start];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_placeHolderView) {
                    [_placeHolderView removeFromSuperview];
                    _placeHolderView = nil;
                    [self.moviePlayer.view addSubview:_renderer.view];
                    
                    //显示猫耳朵
                    self.catEarView.hidden = NO;
                }
            });
        }
    }else if (self.moviePlayer.loadState & IJKMPMovieLoadStateStalled){ // 网速不佳, 自动暂停状态
        [self.parentVC showGifLoding:nil inView:self.moviePlayer.view];
    }

    
// 如果是网络状态不好, 断开后恢复, 也需要去掉加载
    if (self.parentVC.gifView.isAnimating) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.parentVC hideGufLoding];
    });
    }
}

- (void)didFinish
{
    NSLog(@"加载状态...%ld %ld %s", self.moviePlayer.loadState, self.moviePlayer.playbackState, __func__);
    // 因为网速或者其他原因导致直播stop了, 也要显示GIF
    if (self.moviePlayer.loadState & IJKMPMovieLoadStateStalled && !self.parentVC.gifView) {
        [self.parentVC showGifLoding:nil inView:self.moviePlayer.view];
        return;
    }
    //    方法：
    //      1、重新获取直播地址，服务端控制是否有地址返回。
    //      2、用户http请求该地址，若请求成功表示直播未结束，否则结束
    __weak typeof(self)weakSelf = self;    [XLLiveTool GetWithURL:self.hotModel.flv success:^(id result) {
        
    } failure:^(NSError *error) {
        
        [weakSelf.moviePlayer shutdown];
        [weakSelf.moviePlayer.view removeFromSuperview];
        weakSelf.moviePlayer = nil;
        weakSelf.endView.hidden = NO;

    }];
    
}



- (void)quit
{
    if (_bottomToolView){
        
        [_bottomToolView removeFromSuperview];
        _bottomToolView = nil;
    }
    
    if (_anchorView) {
        
        [_anchorView removeFromSuperview];
        _anchorView = nil;
    }
    
    if (_catEarView) {
        [_catEarView removeFromSuperview];
        _catEarView = nil;
    }
    
    if (_moviePlayer) {
        [self.moviePlayer shutdown];
        [self.moviePlayer.view removeFromSuperview];
        self.moviePlayer = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [_renderer stop];
    [_renderer.view removeFromSuperview];
    _renderer = nil;
    [self.parentVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)autoSendBarrage
{
    NSInteger spriteNumber = [_renderer spritesNumberWithName:nil];
    if (spriteNumber <= 50) { // 限制屏幕上的弹幕量
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L]];
    }
}

#pragma mark - 弹幕描述符生产方法

long _index = 0;
/// 生成精灵描述 - 过场文字弹幕
- (BarrageDescriptor *)walkTextSpriteDescriptorWithDirection:(NSInteger)direction
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"text"] = self.danMuText[arc4random_uniform((uint32_t)self.danMuText.count)];
    descriptor.params[@"textColor"] = XLColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256));
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"clickAction"] = ^{
        
        [MBProgressHUD showAlertMessage:@"弹幕被点击"];
        
    };
    return descriptor;
}

- (NSArray *)danMuText
{
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"danmu.plist" ofType:nil]];
}

- (void)setAllModels:(NSArray *)allModels
{
    _allModels = allModels;
    
    self.anchorView.allModels = allModels;
    
    self.catEarView.hotModel = allModels[arc4random_uniform((int)allModels.count)];
}

/** 分享 */
- (void)shareMethod
{
    if (self.moviePlayer.isPlaying){
        
        self.placeHolderView.hidden = YES;
    }
    
    NSString *text = [NSString stringWithFormat:@"  主播昵称：%@/n  主播房间号：%@/n  个性签名：%@/n  在线粉丝数：%@",_hotModel.myname, _hotModel.roomid, _hotModel.signatures, _hotModel.allnum];
    
    UIImage *image = self.placeHolderView.image;
    
    [UMSocialSnsService presentSnsIconSheetView:self.parentVC appKey:UmengAppkey shareText:text shareImage:image shareToSnsNames:nil delegate:nil];
}


- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
