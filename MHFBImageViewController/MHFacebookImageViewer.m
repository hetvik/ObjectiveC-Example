
#import "MHFacebookImageViewer.h"
#import <objc/runtime.h>
#import "Constants.h"
#import "UtilityManager.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "TextLocalizer.h"
@import Firebase;
@import SGImageCache;

static const CGFloat kMinBlackMaskAlpha = 0.3f;
static const CGFloat kMaxImageScale = 2.5f;
static const CGFloat kMinImageScale = 1.0f;

@interface MHFacebookImageViewerCell : UITableViewCell<UIGestureRecognizerDelegate,UIScrollViewDelegate>{
    
    UIImageView * __imageView;
    UIScrollView * __scrollView;
    NSMutableArray *_gestures;
    CGPoint _panOrigin;
    BOOL _isAnimating;
    BOOL _isDoneAnimating;
    BOOL _isLoaded;
}

@property(nonatomic,assign) CGRect originalFrameRelativeToScreen;
@property(nonatomic,weak) UIViewController * rootViewController;
@property(nonatomic,weak) UIViewController * viewController;
@property(nonatomic,weak) UIView * blackMask;
@property(nonatomic,weak) UIButton * doneButton;
@property(nonatomic,weak) UIImageView * senderView;
@property(nonatomic,assign) NSInteger imageIndex;
@property(nonatomic,weak) UIImage * defaultImage;
@property(nonatomic,assign) NSInteger initialIndex;
@property(nonatomic,assign) NSInteger currentIndex;
@property(nonatomic,strong) UIPanGestureRecognizer* panGesture;
@property (nonatomic,weak) MHFacebookImageViewerOpeningBlock openingBlock;
@property (nonatomic,weak) MHFacebookImageViewerClosingBlock closingBlock;
@property(nonatomic,weak) UIView * superView;
@property(nonatomic) UIStatusBarStyle statusBarStyle;

- (void) loadAllRequiredViews;
- (void) setImageURL:(NSURL *)imageURL defaultImage:(UIImage*)defaultImage imageIndex:(NSInteger)imageIndex;

@end

@implementation MHFacebookImageViewerCell

@synthesize originalFrameRelativeToScreen = _originalFrameRelativeToScreen;
@synthesize rootViewController = _rootViewController;
@synthesize viewController = _viewController;
@synthesize blackMask = _blackMask;
@synthesize closingBlock = _closingBlock;
@synthesize openingBlock = _openingBlock;
@synthesize doneButton = _doneButton;
@synthesize senderView = _senderView;
@synthesize imageIndex = _imageIndex;
@synthesize superView = _superView;
@synthesize defaultImage = _defaultImage;
@synthesize initialIndex = _initialIndex;
@synthesize currentIndex = _currentIndex;
@synthesize panGesture = _panGesture;

- (void) loadAllRequiredViews{
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    CGRect frame = [UIScreen mainScreen].bounds;
    __scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 64, frame.size.width, screenHeights-64)];
    __scrollView.delegate = self;
    __scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:__scrollView];
    
    /*UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 95, [UIScreen mainScreen].bounds.size.height - 52, 80, 32)];
    buttonContainer.backgroundColor = [UIColor clearColor];
    buttonContainer.layer.borderWidth = 1.5;
    buttonContainer.layer.borderColor = [UIColor whiteColor].CGColor;
    buttonContainer.layer.cornerRadius = 6.0;
    buttonContainer.clipsToBounds = YES;
    [self.viewController.view addSubview: buttonContainer];*/
    
    
    UIImageView *imgBack = [[UIImageView alloc] initWithFrame:CGRectMake(15, 32, 20, 20)];
    if (IS_IPAD) {
        imgBack.frame = CGRectMake(15, 27, 30, 30);
    }else if (IS_IPHONE_X) {
        imgBack.frame = CGRectMake(15, 52, 20, 20);
    }
    imgBack.image = [UIImage imageNamed:@"back-arrow"];
    [self.viewController.view addSubview:imgBack];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImageEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];  // make click area bigger
    //[closeButton setImage:[UIImage imageNamed:@"back-arrow"] forState:UIControlStateNormal];
    closeButton.frame = CGRectMake(0,20.0f, 50.0f, 44.0f);
    if (IS_IPHONE_X) {
        closeButton.frame = CGRectMake(0, 40.0f, 50.0f, 44.0f);
    }
    
    [closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:closeButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNoti:) name:@"dismissCurrentView" object:nil];

}

-(void)receiveNoti:(NSNotification *)notifcation{
    
    if ([[notifcation name] isEqualToString:@"dismissCurrentView"]){
        [self close:nil];
    }
}

- (void) setImageURL:(NSURL *)imageURL defaultImage:(UIImage*)defaultImage imageIndex:(NSInteger)imageIndex {
    
    __imageView.backgroundColor = [UIColor blueColor];
    _imageIndex = imageIndex;
    _defaultImage = defaultImage;
    
        _senderView.alpha = 0.0f;
        if(!__imageView){
            __imageView = [[UIImageView alloc]init];
            [__scrollView addSubview:__imageView];
            __imageView.contentMode = UIViewContentModeScaleAspectFill;
        }
    
        __block UIImageView * _imageViewInTheBlock = __imageView;
        __block MHFacebookImageViewerCell * _justMeInsideTheBlock = self;
        __block UIScrollView * _scrollViewInsideBlock = __scrollView;
    
    //NSData *dt = [NSData dataWithContentsOfURL:imageURL];
    //__imageView.image = [UIImage imageWithData:dt];
        //__imageView.image = [UIImage imageWithContentsOfFile:imageURL.absoluteString];
    /*[__imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageURL] placeholderImage:defaultImage success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        [_scrollViewInsideBlock setZoomScale:1.0f animated:YES];
        [_imageViewInTheBlock setImage:image];
        _imageViewInTheBlock.frame = [_justMeInsideTheBlock centerFrameFromImage:_imageViewInTheBlock.image];
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        NSLog(@"Image From URL Not loaded");
    }];*/
    
//        [__imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageURL] placeholderImage:defaultImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
//            [_scrollViewInsideBlock setZoomScale:1.0f animated:YES];
//            [_imageViewInTheBlock setImage:image];
//            _imageViewInTheBlock.frame = [_justMeInsideTheBlock centerFrameFromImage:_imageViewInTheBlock.image];
//
//        }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
//            NSLog(@"Image From URL Not loaded");
//        }];
    
        NSString* urlString = [imageURL absoluteString];
        [SGImageCache getImageForURL:urlString thenDo:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_scrollViewInsideBlock setZoomScale:1.0f animated:YES];
                [_imageViewInTheBlock setImage:image];
                _imageViewInTheBlock.frame = [_justMeInsideTheBlock centerFrameFromImage:_imageViewInTheBlock.image];
            });
        }];
    
        __imageView.frame = [self centerFrameFromImage:__imageView.image];
        if(_imageIndex==_initialIndex && !_isLoaded){
            
            __imageView.frame = _originalFrameRelativeToScreen;
            [UIView animateWithDuration:0.4f delay:0.0f options:0 animations:^{
                
                __imageView.frame = [self centerFrameFromImage:__imageView.image];
                CGAffineTransform transf = CGAffineTransformIdentity;
                _rootViewController.view.transform = CGAffineTransformScale(transf, 0.95f, 0.95f);
                _blackMask.alpha = 1;
                
            }completion:^(BOOL finished){
                
                if (finished){
                    
                    _isAnimating = NO;
                    _isLoaded = YES;
                    if(_openingBlock)
                        _openingBlock();
                }
            }];
        }
    
        __imageView.userInteractionEnabled = YES;
        [self addPanGestureToView:__imageView];
        [self addMultipleGesture];
}

#pragma mark - Add Pan Gesture
- (void) addPanGestureToView:(UIView*)view{
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerDidPan:)];
    _panGesture.cancelsTouchesInView = NO;
    _panGesture.delegate = self;
    
    __weak UIView *weakSuperView = view.superview;
    while (![weakSuperView isKindOfClass:[UITableView class]]){
        
        weakSuperView = weakSuperView.superview;
        if (weakSuperView == Nil)
            break;
    }
    
    if ([weakSuperView isKindOfClass:[UITableView class]])
        [((UITableView*)weakSuperView).panGestureRecognizer requireGestureRecognizerToFail:_panGesture];
    
    [view addGestureRecognizer:_panGesture];
    [_gestures addObject:_panGesture];
}

# pragma mark - Avoid Unwanted Horizontal Gesture
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer{
    
    CGPoint translation = [panGestureRecognizer translationInView:__scrollView];
    return fabs(translation.y) > fabs(translation.x) ;
}

#pragma mark - Gesture recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    _panOrigin = __imageView.frame.origin;
    gestureRecognizer.enabled = YES;
    return !_isAnimating;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    if(gestureRecognizer == _panGesture)
        return YES;
    
    return NO;
}

#pragma mark - Handle Panning Activity
- (void) gestureRecognizerDidPan:(UIPanGestureRecognizer*)panGesture{
    
    if(__scrollView.zoomScale != 1.0f || _isAnimating)return;
    if(_imageIndex==_initialIndex){
        
        if(_senderView.alpha!=0.0f)
            _senderView.alpha = 0.0f;
        
    }else{
        
        if(_senderView.alpha!=1.0f)
            _senderView.alpha = 1.0f;
    }
    
    // Hide the Done Button
    [self hideDoneButton];
    __scrollView.bounces = NO;
    CGSize windowSize = _blackMask.bounds.size;
    CGPoint currentPoint = [panGesture translationInView:__scrollView];
    CGFloat y = currentPoint.y + _panOrigin.y;
    CGRect frame = __imageView.frame;
    frame.origin.y = y;

    __imageView.frame = frame;
    CGFloat yDiff = abs((y + __imageView.frame.size.height/2) - windowSize.height/2);
    _blackMask.alpha = MAX(1 - yDiff/(windowSize.height/0.5),kMinBlackMaskAlpha);
    
    if ((panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) && __scrollView.zoomScale == 1.0f){
        
        if(_blackMask.alpha < 0.85f)
            [self dismissViewController];
        else
            [self rollbackViewController];
    }
}

#pragma mark - Just Rollback
- (void)rollbackViewController{
    
    _isAnimating = YES;
    [UIView animateWithDuration:0.4f delay:0.0f options:0 animations:^{
        
        __imageView.frame = [self centerFrameFromImage:__imageView.image];
        _blackMask.alpha = 1;
        
    }completion:^(BOOL finished){
        
        if (finished)
            _isAnimating = NO;
    }];
}

#pragma mark - Dismiss
- (void)dismissViewController{
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleLightContent];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideHeaderText" object:nil];
    
    _isAnimating = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideDoneButton];
        __imageView.clipsToBounds = YES;
        CGFloat screenHeight1 =  [[UIScreen mainScreen] bounds].size.height;
        CGFloat imageYCenterPosition = __imageView.frame.origin.y + __imageView.frame.size.height/2 ;
        BOOL isGoingUp =  imageYCenterPosition < screenHeight1/2;
        
        [UIView animateWithDuration:0.2f delay:0.0f options:0 animations:^{
            
            if(_imageIndex==_initialIndex)
                __imageView.frame = _originalFrameRelativeToScreen;
            else
                __imageView.frame = CGRectMake(__imageView.frame.origin.x, isGoingUp?-screenHeight1:screenHeight1, __imageView.frame.size.width, __imageView.frame.size.height);
            
            CGAffineTransform transf = CGAffineTransformIdentity;
            _rootViewController.view.transform = CGAffineTransformScale(transf, 1.0f, 1.0f);
            _blackMask.alpha = 0.0f;
            
        }completion:^(BOOL finished){
            
            if (finished){
                
                [_viewController.view removeFromSuperview];
                [_viewController removeFromParentViewController];
                _senderView.alpha = 1.0f;
                [UIApplication sharedApplication].statusBarHidden = NO;
                [UIApplication sharedApplication].statusBarStyle = _statusBarStyle;
                _isAnimating = NO;
                if(_closingBlock)
                    _closingBlock();
            }
        }];
    });
}

#pragma mark - Compute the new size of image relative to width(window)
- (CGRect) centerFrameFromImage:(UIImage*) image{
    
    if(!image) return CGRectZero;

    CGRect windowBounds = CGRectMake(0, 62, _viewController.view.frame.size.width, screenHeights-125);
    CGSize newImageSize = [self imageResizeBaseOnWidth:windowBounds.size.width oldWidth:image.size.width oldHeight:image.size.height];
    newImageSize.height = MIN(windowBounds.size.height,newImageSize.height);
    return CGRectMake(0.0f, windowBounds.size.height/2 - newImageSize.height/2, newImageSize.width, newImageSize.height);
}

- (CGSize)imageResizeBaseOnWidth:(CGFloat) newWidth oldWidth:(CGFloat) oldWidth oldHeight:(CGFloat)oldHeight{
    
    CGFloat scaleFactor = newWidth / oldWidth;
    CGFloat newHeight = oldHeight * scaleFactor;
    return CGSizeMake(newWidth, newHeight);
}

# pragma mark - UIScrollView Delegate
- (void)centerScrollViewContents{
    
    CGSize boundsSize = CGSizeMake(screenWidths, screenHeights-125);
    CGRect contentsFrame = __imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width)
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    else
        contentsFrame.origin.x = 0.0f;

    if (contentsFrame.size.height < boundsSize.height)
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    else
        contentsFrame.origin.y = 0.0f;
    
    __imageView.frame = contentsFrame;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return __imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    _isAnimating = YES;
    [self hideDoneButton];
    [self centerScrollViewContents];
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    _isAnimating = NO;
}

- (void)addMultipleGesture{
    
    UITapGestureRecognizer *twoFingerTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTwoFingerTap:)];
    twoFingerTapGesture.numberOfTapsRequired = 1;
    twoFingerTapGesture.numberOfTouchesRequired = 2;
    [__scrollView addGestureRecognizer:twoFingerTapGesture];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [__scrollView addGestureRecognizer:singleTapRecognizer];

    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDobleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [__scrollView addGestureRecognizer:doubleTapRecognizer];

    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];

    __scrollView.minimumZoomScale = kMinImageScale;
    __scrollView.maximumZoomScale = kMaxImageScale;
    __scrollView.zoomScale = 1;
    [self centerScrollViewContents];
}

#pragma mark - For Zooming
- (void)didTwoFingerTap:(UITapGestureRecognizer*)recognizer{
    
    CGFloat newZoomScale = __scrollView.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, __scrollView.minimumZoomScale);
    [__scrollView setZoomScale:newZoomScale animated:YES];
}

#pragma mark - Showing of Done Button if ever Zoom Scale is equal to 1
- (void)didSingleTap:(UITapGestureRecognizer*)recognizer{
    
    if(_doneButton.superview){
        [self hideDoneButton];
    }else{
        
        if(__scrollView.zoomScale == __scrollView.minimumZoomScale){
            
            if(!_isDoneAnimating){
                
                _isDoneAnimating = YES;
                [self.viewController.view addSubview:_doneButton];
                _doneButton.alpha = 0.0f;
                
                [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    
                    _doneButton.alpha = 1.0f;
                    
                }completion:^(BOOL finished){
                    
                    [self.viewController.view bringSubviewToFront:_doneButton];
                    _isDoneAnimating = NO;
                }];
            }
            
            if (recognizer != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"gotoDetailScreen" object:nil];
            }
            
        }else if(__scrollView.zoomScale == __scrollView.maximumZoomScale){
            
            CGPoint pointInView = [recognizer locationInView:__imageView];
            [self zoomInZoomOut:pointInView];
        }
    }
}

#pragma mark - Zoom in or Zoom out
- (void)didDobleTap:(UITapGestureRecognizer*)recognizer{
    CGPoint pointInView = [recognizer locationInView:__imageView];
    [self zoomInZoomOut:pointInView];
}

- (void) zoomInZoomOut:(CGPoint)point{
    
    CGFloat newZoomScale = __scrollView.zoomScale > (__scrollView.maximumZoomScale/2)?__scrollView.minimumZoomScale:__scrollView.maximumZoomScale;

    CGSize scrollViewSize = __scrollView.bounds.size;
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    [__scrollView zoomToRect:rectToZoomTo animated:YES];
}

#pragma mark - Hide the Done Button
- (void) hideDoneButton{
    
    if(!_isDoneAnimating){
        
        if(_doneButton.superview){
            
            _isDoneAnimating = YES;
            _doneButton.alpha = 1.0f;
            
            [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                
                //_doneButton.alpha = 0.0f;
                
            }completion:^(BOOL finished){
                
                _isDoneAnimating = NO;
                //[_doneButton removeFromSuperview];
                
            }];
        }
    }
}

- (void)close:(UIButton *)sender{
    
    self.userInteractionEnabled = NO;
    [sender removeFromSuperview];
    [self dismissViewController];
}

-(void)saveImagetoPhotos:(UIButton *)sender{
    UIImageWriteToSavedPhotosAlbum(_senderView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo{
    
    /*if (error != nil)
        [kAppDelegate showAlert:@"m_image_saved_error"];
    else
        [kAppDelegate showAlert:@"m_image_saved"];*/
}

@end

@interface MHFacebookImageViewer()<UIGestureRecognizerDelegate,UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate>{
   
    NSMutableArray *_gestures;
    UITableView * _tableView;
    UIView *_blackMask;
    UIImageView * _imageView;
    UIButton * _doneButton;
    //UIButton *nextButton;
    //UIButton *previousButton;
    UIView *headerVW;
    UILabel *lblHeaderTitle;
    UIView * _superView;

    CGPoint _panOrigin;
    CGRect _originalFrameRelativeToScreen;

    BOOL isRedirection;
    BOOL _isAnimating;
    BOOL _isDoneAnimating;
    UIStatusBarStyle _statusBarStyle;
    NSTimer *myTimer;
}
@end

@implementation MHFacebookImageViewer
@synthesize rootViewController = _rootViewController;
@synthesize imageURL = _imageURL;
@synthesize openingBlock = _openingBlock;
@synthesize closingBlock = _closingBlock;
@synthesize senderView = _senderView;
@synthesize initialIndex = _initialIndex;
@synthesize currentIndex = _currentIndex;
@synthesize textLbl;
@synthesize dataArray;
@synthesize cityAlias;
@synthesize isFromDetailPage;

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"gotoDetailScreen" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refressCurrentLabel" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"hideHeaderText" object:nil];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (IS_IPHONE_X){
        
        CGRect currentViewFrame = self.view.frame;
        currentViewFrame.size.height = screenHeights - 50.0;
        self.view.frame = currentViewFrame;
        _tableView.contentOffset = CGPointMake(0, 0);
        _tableView.showsHorizontalScrollIndicator = NO;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    //Google Analytics log screen name
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker set:kGAIScreenName value:@"Image_Detail_Screen"];
//    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    //Firebase log screen name
    [FIRAnalytics setScreenName:@"Image_Detail_Screen" screenClass:@"CityDetail"];
    
}

#pragma mark - TableView datasource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if(!self.imageDatasource) return 1;
    return [self.imageDatasource numberImagesForImageViewer:self];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellID = @"mhfacebookImageViewerCell";
    MHFacebookImageViewerCell *imageViewerCell = [tableView dequeueReusableCellWithIdentifier:cellID];
    //NSLog(@"%i",indexPath.row);
    if(!imageViewerCell){
        
        CGRect windowFrame = [[UIScreen mainScreen] bounds];
        imageViewerCell = [[MHFacebookImageViewerCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        imageViewerCell.transform = CGAffineTransformMakeRotation(M_PI_2);
        imageViewerCell.frame = CGRectMake(0,0,windowFrame.size.width, windowFrame.size.height);
        imageViewerCell.originalFrameRelativeToScreen = _originalFrameRelativeToScreen;
        imageViewerCell.viewController = self;
        imageViewerCell.blackMask = _blackMask;
        imageViewerCell.rootViewController = _rootViewController;
        imageViewerCell.closingBlock = _closingBlock;
        imageViewerCell.openingBlock = _openingBlock;
        imageViewerCell.superView = _senderView.superview;
        imageViewerCell.senderView = _senderView;
        imageViewerCell.doneButton = _doneButton;
        imageViewerCell.initialIndex = _initialIndex;
        imageViewerCell.statusBarStyle = _statusBarStyle;
        [imageViewerCell loadAllRequiredViews];
        imageViewerCell.backgroundColor = [UIColor clearColor];
    }
    if(!self.imageDatasource)
        [imageViewerCell setImageURL:_imageURL defaultImage:_senderView.image imageIndex:0];
    else
        [imageViewerCell setImageURL:[self.imageDatasource imageURLAtIndex:indexPath.row imageViewer:self] defaultImage:[self.imageDatasource imageDefaultAtIndex:indexPath.row imageViewer:self]imageIndex:indexPath.row];

    return imageViewerCell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return _rootViewController.view.bounds.size.width;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSArray *vis = _tableView.indexPathsForVisibleRows;
    if (vis.count > 0) {
        NSIndexPath *indexPath = [vis firstObject];
        
        //NSLog(@"PAGE = %d",indexPath.row);
        
        if (indexPath.row != self.currentIndex) {
            
            NSIndexPath *preIndex = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
            MHFacebookImageViewerCell *imageViewerCell = [_tableView cellForRowAtIndexPath:preIndex];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [imageViewerCell didSingleTap:nil];
            });
        }
        
        self.currentIndex = indexPath.row;
        
        //NSDictionary *albumData = [dataArray objectAtIndex:self.currentIndex];
        //NSString *previewImagePath = [NSString stringWithFormat:@"%@",[albumData valueForKey:@"imageName"]];
        //self.textLbl.text = previewImagePath;
        
        //previousButton.hidden = NO;
        //nextButton.hidden = NO;
        
        if (self.currentIndex == 0) {
            //previousButton.hidden = YES;
        }
        
        NSInteger totalPage = [self.imageDatasource numberImagesForImageViewer:self];
        if (self.currentIndex == totalPage-1) {
           // nextButton.hidden = YES;
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        
    }
    return self;
}

- (void)loadView{
    
    //_statusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
    [UIApplication sharedApplication].statusBarHidden = NO;
    CGRect windowBounds = [[UIScreen mainScreen] bounds];
    
    // Compute Original Frame Relative To Screen
    CGRect newFrame = [_senderView convertRect:windowBounds toView:nil];
    newFrame.origin = CGPointMake(newFrame.origin.x, newFrame.origin.y);
    newFrame.size = _senderView.frame.size;
    _originalFrameRelativeToScreen = newFrame;
    
    self.view = [[UIView alloc] initWithFrame:windowBounds];
    //    NSLog(@"WINDOW :%@",NSStringFromCGRect(windowBounds));
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Add a Tableview
    _tableView = [[UITableView alloc]initWithFrame:windowBounds style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    //rotate it -90 degrees
    _tableView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _tableView.frame = CGRectMake(0,0,windowBounds.size.width,windowBounds.size.height);
    _tableView.pagingEnabled = YES;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delaysContentTouches = YES;
    [_tableView setShowsVerticalScrollIndicator:NO];
    _tableView.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _tableView.hidden = NO;
        [_tableView setContentOffset:CGPointMake(0, _initialIndex * windowBounds.size.width)];
    });
    
    if (@available(iOS 11.0, *)) {
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    _blackMask = [[UIView alloc] initWithFrame:windowBounds];
    _blackMask.backgroundColor = [UIColor whiteColor];
    _blackMask.alpha = 0.0f;
    _blackMask.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:_blackMask atIndex:0];
    
    headerVW = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidths, 64)];
    if (IS_IPHONE_X) {
        headerVW = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidths, 84)];
    }
    //headerVW.backgroundColor = [UIColor colorWithRed:254.0/255.0 green:162.0/255.0 blue:113.0/255.0 alpha:1];
    headerVW.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:headerVW];
    
    
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //[_doneButton setImage:[UIImage imageNamed:@"ic_back_icon"] forState:UIControlStateNormal];
    _doneButton.frame = CGRectMake(0, 20.0f, 50.0f, 44.0f);
    if (IS_IPHONE_X) {
        _doneButton.frame = CGRectMake(0, 40.0f, 50.0f, 44.0f);
    }
    [_doneButton addTarget:self action:@selector(tapOnBackButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_doneButton];
    
    lblHeaderTitle = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, screenWidths-80, 64)];
    if (IS_IPHONE_X) {
        lblHeaderTitle = [[UILabel alloc] initWithFrame:CGRectMake(40, 22, screenWidths-80, 80)];
    }
    lblHeaderTitle.textColor = [UIColor blackColor];
    lblHeaderTitle.text = LocalizedString(@"TourPhotos", @"Tour Photos");
    
    if ([self.imageDatasource respondsToSelector:@selector(getScreenTitle)]) {
        NSString *strTitle = [self.imageDatasource getScreenTitle];
        if (strTitle != nil && ![strTitle isEqualToString:@""]) {
            strTitle = [strTitle stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            lblHeaderTitle.text = strTitle;
        }
    }
    
    if (IS_IPAD){
        lblHeaderTitle.font = [UIFont fontWithName:@"Nunito-Regular" size:23.0];
    }else{
        if (IS_IPHONE_X) {
            lblHeaderTitle.font = [UIFont fontWithName:@"Nunito-Regular" size:16.0];
        }else{
            lblHeaderTitle.font = [UIFont fontWithName:@"Nunito-Regular" size:18.0];
        }
    }
    
    lblHeaderTitle.numberOfLines = 2;
    lblHeaderTitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:lblHeaderTitle];
    
    
    /*previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    previousButton.frame = CGRectMake(10, screenHeights/2-20, 40, 40);
    [previousButton setImage:[UIImage imageNamed:@"backBtn_ic"] forState:UIControlStateNormal];
    previousButton.layer.masksToBounds = YES;
    previousButton.layer.cornerRadius = 20.0;
    [previousButton addTarget:self action:@selector(nextPreviButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    previousButton.backgroundColor = [UIColor whiteColor];
    
    nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = CGRectMake(screenWidths-50, screenHeights/2-20, 40, 40);
    nextButton.layer.cornerRadius = 20.0;
    nextButton.layer.masksToBounds = YES;
    nextButton.backgroundColor = [UIColor whiteColor];
    [nextButton setImage:[UIImage imageNamed:@"NextArrow"] forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextPreviButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:previousButton];
    [self.view addSubview:nextButton];*/
    
    /*if (IS_IPHONE_X){
        self.textLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, screenHeights-90, screenWidths, 50)];
    }else{
        self.textLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, screenHeights-65, screenWidths, 50)];
    }
    
    self.textLbl.numberOfLines = 0;
    self.textLbl.font = [UIFont fontWithName:@"Montserrat-SemiBold" size:20.0];
    self.textLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.textLbl];*/
    
    self.textLblOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.textLblOverlay addTarget:self action:@selector(textLblOverlayClick:)
     forControlEvents:UIControlEventTouchUpInside];
    self.textLblOverlay.frame = self.textLbl.frame;
    [self.view addSubview:self.textLblOverlay];
    
    
    NSInteger totalPage = [self.imageDatasource numberImagesForImageViewer:self];
    self.currentIndex = self.initialIndex;
    if (self.currentIndex == 0) {
        //previousButton.hidden = YES;
    }
    
    if (self.currentIndex == totalPage-1) {
        //nextButton.hidden = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNoti:) name:@"refressCurrentLabel" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"gotoDetailScreen" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNoti:) name:@"gotoDetailScreen" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNoti:) name:@"hideHeaderText" object:nil];
    
    isRedirection = NO;
}

-(IBAction)textLblOverlayClick:(id)sender{
    
    if ([isFromDetailPage isEqualToString:@"1"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissCurrentView" object:nil];
        return;
    }
    
    NSDictionary *nodeDict = [[dataArray objectAtIndex:self.currentIndex] valueForKey:@"nodeDetail"];
    NSLog(@"nodeDict: %@",nodeDict);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissCurrentView" object:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (isRedirection == NO) {
            
        }
        isRedirection = YES;
    });
}

-(void)receiveNoti:(NSNotification *)notifcation{
    
    if ([[notifcation name] isEqualToString:@"refressCurrentLabel"]){
        
        if (dataArray.count != 0){
            NSDictionary *albumData = [dataArray objectAtIndex:self.currentIndex];
            NSString *previewImagePath = [NSString stringWithFormat:@"%@",[albumData valueForKey:@"imageName"]];
            self.textLbl.text = previewImagePath;
            
        }
        
    }else if ([[notifcation name] isEqualToString:@"gotoDetailScreen"]){
        
        [myTimer invalidate];
        myTimer = nil;
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(textLblOverlayClick:) userInfo:nil repeats:NO];
        
    }else if ([[notifcation name] isEqualToString:@"hideHeaderText"]){
        
        _tableView.hidden = YES;
        //lblHeaderTitle.hidden = YES;
    }
}

-(IBAction)tapOnBackButton:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissCurrentView" object:nil];
}

/*-(IBAction)nextPreviButtonAction:(id)sender{

    NSIndexPath *prev = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    MHFacebookImageViewerCell *imageViewerCell = [_tableView cellForRowAtIndexPath:prev];
    [imageViewerCell didSingleTap:nil];
    
    NSInteger totalPage = [self.imageDatasource numberImagesForImageViewer:self];
    if ([sender isEqual:nextButton]) {
        
        if (self.currentIndex < totalPage-1) {
            self.currentIndex = self.currentIndex + 1;
        }
    }else{
        if (self.currentIndex != 0) {
            self.currentIndex = self.currentIndex - 1;
        }
    }
    
    previousButton.hidden = NO;
    nextButton.hidden = NO;
    
    if (self.currentIndex == 0) {
        previousButton.hidden = YES;
    }
    
    if (self.currentIndex == totalPage-1) {
        nextButton.hidden = YES;
    }
    
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]
                     atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    NSDictionary *albumData = [dataArray objectAtIndex:self.currentIndex];
    NSString *previewImagePath = [NSString stringWithFormat:@"%@",[albumData valueForKey:@"imageName"]];
    self.textLbl.text = previewImagePath;

}*/

#pragma mark - Show
- (void)presentFromRootViewController{
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [self presentFromViewController:rootViewController];
}

- (void)presentFromViewController:(UIViewController *)controller{
    
    _rootViewController = controller;
    [[[[UIApplication sharedApplication]windows]objectAtIndex:0]addSubview:self.view];
    [controller addChildViewController:self];
    [self didMoveToParentViewController:controller];
}

- (void) dealloc{
    
    _rootViewController = nil;
    _imageURL = nil;
    _senderView = nil;
    _imageDatasource = nil;
}

@end

#pragma mark - Custom Gesture Recognizer that will Handle imageURL
@interface MHFacebookImageViewerTapGestureRecognizer()
@end

@implementation MHFacebookImageViewerTapGestureRecognizer
@synthesize imageURL;
@synthesize openingBlock;
@synthesize closingBlock;
@synthesize imageDatasource;
@end
