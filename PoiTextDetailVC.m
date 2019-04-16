//
//  NewDetailViewController.m
//  TR_1708
//
//  Copyright © 2018 Anand Patel. All rights reserved.
//

#import "PoiTextDetailVC.h"
#import "Constants.h"
#import "UIImageView+MHFacebookImageViewer.h"
#import "TextReader.h"
#import "MapsFacade.h"
#import "ContentFacade.h"
#import "UtilityManager.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "SVProgressHUD.h"
#import "OnlineCityMapsVC.h"
#import "UserEventsLogger.h"
#import "TextLocalizer.h"
#import "Constants.h"
@import Firebase;
@import SGImageCache;

@interface PoiTextDetailVC ()<MHFacebookImageViewerDatasource>
{
    ContentFacade* facade;
    NSMutableArray *imagesArray;
    NSMutableArray *fullImages;
    NSMutableArray *arrImages;
    NSMutableArray *loadedImages;
    NSInteger previewImageDownloadIndex;
    CGFloat yPos;
}
@end

@implementation PoiTextDetailVC

@synthesize nodeDict;
@synthesize baseNodeDict;
@synthesize etipsArray;
@synthesize dicCityDetail;
@synthesize strFromCategirized;
@synthesize cityPrefix;

#pragma mark - View Life Cycle
- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    if (IS_IPHONE_X){
        
        CGRect headerViewFrame = blurView.frame;
        headerViewFrame.size.height = 84;
        blurView.frame = headerViewFrame;
        
        CGRect contentViewFrame = contentScrollView.frame;
        contentViewFrame.origin.y = 84;
        contentViewFrame.size.height = screenHeights - 100;
        contentScrollView.frame = contentViewFrame;
        
        CGRect backFrame = btnBack.frame;
        backFrame.origin.y = 40;
        btnBack.frame = backFrame;
        
        CGRect backicnFrame = imgBackicn.frame;
        backicnFrame.origin.y = 52;
        imgBackicn.frame = backicnFrame;
    }
    
    if(IS_IPAD_PRO12_9 || IS_IPAD_PRO10_5){
        CGRect curvbgImgFrame = curveBgView.frame;
        
        if(IS_IPAD_PRO12_9){
            
            CGRect detailImgFrame = detailImgView.frame;
            detailImgFrame.size.height = 450;
            detailImgView.frame = detailImgFrame;
            
            curvbgImgFrame.origin.y = 325;
            //curvbgImgFrame.size.height = screenWidths - 389;
            
        }else if(IS_IPAD_PRO10_5){
            CGRect detailImgFrame = detailImgView.frame;
            detailImgFrame.size.height = 430;
            detailImgView.frame = detailImgFrame;
            
            
            curvbgImgFrame.origin.y = 305;
            //curvbgImgFrame.size.height = screenWidths - 369;
        }
        curveBgView.frame = curvbgImgFrame;
        
        CGRect detailcellFrame = detailCellView.frame;
        detailcellFrame.origin.y = curvbgImgFrame.origin.y + 10;
        detailCellView.frame = detailcellFrame;
        
        CGFloat yPos = detailcellFrame.origin.y + 70;
        CGRect contetnFrameFrame = contentVW.frame;
        contetnFrameFrame.origin.y = yPos;
        //contetnFrameFrame.size.height = screenWidths - (yPos + 64);
        contentVW.frame = contetnFrameFrame;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    imgMicIcon.image = [UIImage imageNamed:@"mic_on_gray_ic"];
    imgMicIconWhite.image = [UIImage imageNamed:@"mic_on_white_ic"];
    
    [[TextReader sharedInstance] stopAudio];
    isReadingContent = NO;
    
    blurView.alpha = 0.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNoti:) name:@"finishedReadingText" object:nil];
    
    self.detector = [SlientSwitchDetector shared];
    __weak typeof(self) weakSelf = self;
    self.detector.silentNotify = ^(BOOL silent){
        
        silentModeON = silent;
        [weakSelf startHTMLReadingBasedOnSlientSwitch];
    };
    
    NSString* strLatitude = @"";
    NSString* strLongitude = @"";
    if ([strFromCategirized isEqualToString:@"1"]) {
        [self filterDataNode];
        strLatitude = [NSString stringWithFormat:@"%@", [self.baseNodeDict objectForKey:@"latitude"]];
        strLongitude = [NSString stringWithFormat:@"%@", [self.baseNodeDict objectForKey:@"longitude"]];
    }else{
        strLatitude = [NSString stringWithFormat:@"%@", [self.nodeDict objectForKey:@"latitude"]];
        strLongitude = [NSString stringWithFormat:@"%@", [self.nodeDict objectForKey:@"longitude"]];
    }
    
    if (![UtilityManager isStringNull:strLatitude] && ![UtilityManager isStringNull:strLongitude]){
        btnMap.hidden = NO;
        mapIcon.hidden = NO;
        btnMapWhite.hidden = NO;
        mapIconWhite.hidden = NO;
    }else{
        btnMap.hidden = YES;
        mapIcon.hidden = YES;
        btnMapWhite.hidden = YES;
        mapIconWhite.hidden = YES;
    }
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleLightContent];

    fullImages = [NSMutableArray array];
    if ([self.nodeDict objectForKey:@"text"] && [strFromCategirized isEqualToString:@"1"]) {
        contentVW.hidden = false;
        [self createTextForCategorizedContent];
        blurLbl.text = [self.nodeDict objectForKey:@"title"];
        PlaceLbl.text = [self.nodeDict objectForKey:@"title"];
        
    }else{
        contentVW.hidden = false;
        facade = [[ContentFacade alloc] init];
        previewImageDownloadIndex = 0;
        imagesArray = [[NSMutableArray alloc] init];
        imagesArray = [[self.nodeDict objectForKey:@"images"] mutableCopy];
        nodeID = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"nodeID"]];
        NSString *strTitle = @"";
        NSString *strDescription = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"htmlPath"]];
        if ([UtilityManager isStringNull:strDescription]) {
            strDescription = @"";
        }
        strTitle = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"nodeAlias"]];
        
        blurLbl.text = strTitle;
        PlaceLbl.text = strTitle;
        
        if ([nodeDict objectForKey:@"previewImagePath"]) {
            NSString* previewPath = [nodeDict objectForKey:@"previewImagePath"];
            UIImage* image = [UIImage imageWithContentsOfFile:previewPath];
            detailImgView.image = image;
            if (image == nil) {
                [detailImgView setImage:[UIImage imageNamed:@"image1"]];
            }
            
            NSString* imageName = [[previewPath componentsSeparatedByString:@"/"]lastObject];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [facade downloadSingleImageFileForPath:imageName withNodeID:nodeID withCityName:cityPrefix withCompletion:^(NSString* imagePath, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        detailImgView.image = [UIImage imageWithContentsOfFile:imagePath];
                        [fullImages insertObject:imagePath atIndex:0];
                    });
                }];
            });
            
        }else{
            [detailImgView setImage:[UIImage imageNamed:@"image1"]];
        }
        //detailImgView.image = [UIImage imageNamed:@"ARButtonBG"];
        
        //lblDescriptions.frame = CGRectMake(18, 15, screenWidths-36, 20);
        NSString *strDetails = [NSString stringWithFormat:@"%@ %@",strTitle, strDescription];
        
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:strDetails];
        NSRange range = [strDetails rangeOfString:strTitle];
        [attString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];
        [self getFilesSingleNodePreviewImageDownload];
    }
    [FIRAnalytics setScreenName:@"PoiTextScreen" screenClass:@"PoiTextDetailVC"];
}

-(void)getFilesSingleNodePreviewImageDownload{
    if (previewImageDownloadIndex < imagesArray.count) {
        NSString *strPreivewImage = [imagesArray objectAtIndex:previewImageDownloadIndex];
        NSString* imageName = [strPreivewImage lastPathComponent];
        [facade downloadSingleThumbImageForPath:imageName withCityName:cityPrefix withCompletion:^(BOOL isSuccess, NSError *error) {
            
            NSLog(@"File downloaded = %ld",previewImageDownloadIndex);
            previewImageDownloadIndex = previewImageDownloadIndex + 1;
            [self getFilesSingleNodePreviewImageDownload];
        }];
    }else{
        [self downloadFileWithContent];
    }
}

-(void)downloadFileWithContent {
    NSString *curLang = CurrentContentLanguageGet;
    if ([UtilityManager isStringNull:curLang]) {
        curLang = @"en";
    }
    NSString* nodePrefix = [self.nodeDict objectForKey:@"nodePrefix"];
    NSString* txtToDownload = [NSString stringWithFormat:@"%@-%@.txt",nodePrefix,curLang];
    [SVProgressHUD show];
    [facade downloadSingleFileForPath:txtToDownload withNodeID:nodeID withCityName:cityPrefix withCompletion:^(BOOL isSuccess, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self createHTMLScroll];
            [SVProgressHUD dismiss];
        });
    }];
}

#pragma mark - Create HTML scroll
-(void)createHTMLScroll{
    NSString *previewImagePath = @"";
    arrImages = [NSMutableArray array];
    loadedImages =[[NSMutableArray alloc] init];
    //Last
    for (NSString* item in [self.nodeDict objectForKey:@"images"]){
        NSMutableArray* components = [[item componentsSeparatedByString:@"/"] mutableCopy];
        NSInteger index = [components count]-2;
        [components replaceObjectAtIndex:index withObject:@"ThumbImages"];
        NSString* newItem = [components componentsJoinedByString:@"/"];
        [arrImages addObject:newItem];
    }
    
    if (arrImages.count != 0) {
        previewImagePath = [arrImages objectAtIndex:0];
    }
    
    NSString *txtFilePath = [self.nodeDict objectForKey:@"htmlPath"];
    txtFilePath = [txtFilePath stringByReplacingOccurrencesOfString:@".html" withString:@".txt"];
    [imgGalleryWhite setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
        NSLog(@"OPEN!");
        
    }onClose:^{
        NSLog(@"CLOSE!");
        
    }];
    
    [imgGallery setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
        NSLog(@"OPEN!");
        
    }onClose:^{
        NSLog(@"CLOSE!");
    }];
    
    yPos = 10;
    
    if (txtFilePath.length != 0){
        
        NSString *txtFileContent = [NSString stringWithContentsOfFile:txtFilePath encoding:NSUTF8StringEncoding error:nil];
        
        if (![UtilityManager isStringNull:txtFileContent]) {
            
            NSString *titleString = [NSString stringWithFormat:@"%@",[self stringBeforeString:@"\n" inString:txtFileContent]];
            NSString *descriptionString = [NSString stringWithFormat:@"%@",[self stringAfterString:@"\n" inString:txtFileContent]];
            
            strReadableText = [NSString stringWithFormat:@"%@. %@",titleString,descriptionString];
            
            NSMutableArray *arrParagraphs = [[NSMutableArray alloc] init];
            arrParagraphs = [[descriptionString componentsSeparatedByString:@"\n"] mutableCopy];
            
            NSInteger centerElementOfArray = arrParagraphs.count/2;
            
            for (int i = 0; i < arrParagraphs.count; i++) {
                NSString *paragraphString = [NSString stringWithFormat:@"%@",[arrParagraphs objectAtIndex:i]];
                
                if (i == arrParagraphs.count-1){
                    
                    if (![UtilityManager isStringNull:paragraphString]) {
                        
                        if (2 < [arrImages count]){
                            //Image Add
                            [self createTextCell:paragraphString];
                            NSString* previewPath = [NSString stringWithFormat:@"%@",[arrImages objectAtIndex:2]];
                            [self createImageCell:previewPath];
                            
                        }else{
                            
                            //Not Exist
                            if (![UtilityManager isStringNull:paragraphString]) {
                                [self createTextCell:paragraphString];
                            }
                        }
                    }
                    
                }else if (i == centerElementOfArray){
                    
                    if (![UtilityManager isStringNull:paragraphString]) {
                        
                        if (1 < [arrImages count]){
                            
                            [self createTextCell:paragraphString];
                            NSString* previewPath = [NSString stringWithFormat:@"%@",[arrImages objectAtIndex:1]];
                            [self createImageCell:previewPath];
                            
                        }else{
                            
                            //Not Exist
                            if (![UtilityManager isStringNull:paragraphString]) {
                                [self createTextCell:paragraphString];
                            }
                        }
                    }
                    
                }else{
                    
                    if (![UtilityManager isStringNull:paragraphString]) {
                        
                        [self createTextCell:paragraphString];
                    }
                }
            }
            CGRect oldContVW = contentVW.frame;
            oldContVW.size.height = yPos;
            contentVW.frame = oldContVW;
            [contentScrollView setContentSize:CGSizeMake(screenWidths, yPos+oldContVW.origin.y)];
        }
    }
}

-(void)createTextForCategorizedContent{
    
    [imgGalleryWhite setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
        NSLog(@"OPEN!");
        
    }onClose:^{
        NSLog(@"CLOSE!");
        
    }];
    
    [imgGallery setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
        NSLog(@"OPEN!");
        
    }onClose:^{
        NSLog(@"CLOSE!");
    }];
    
    yPos = 10;
    
    NSString *previewImagePath = @"";
    NSMutableArray *arrImages = [[nodeDict objectForKey:@"images"] mutableCopy];
    NSString* previewFullImage;
    if (arrImages.count != 0) {
        previewImagePath = [NSString stringWithFormat:@"%@",[[arrImages objectAtIndex:0] objectForKey:@"thumbnail"]];
        previewFullImage = [NSString stringWithFormat:@"%@",[[arrImages objectAtIndex:0] objectForKey:@"image"]];
    }
    [detailImgView setImageWithURL:[NSURL URLWithString:previewImagePath]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [SGImageCache getImageForURL:previewFullImage thenDo:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [detailImgView setImage:image];
            });
            [fullImages insertObject:previewFullImage atIndex:0];
        }];
    });
    
    //[detailImgView setImageWithURL:[NSURL URLWithString:previewImagePath]];
    //detailImgView.image = [UIImage imageNamed:@"ARButtonBG"];
    
    NSString *txtFileContent = [NSString stringWithFormat:@"%@",[self.nodeDict objectForKey:@"text"]];
    
    if (![UtilityManager isStringNull:txtFileContent]) {
        
        
        //NSString *titleString = [NSString stringWithFormat:@"%@",[self stringBeforeString:@"\n" inString:txtFileContent]];
        NSString *titleString = [NSString stringWithFormat:@"%@",[self.nodeDict objectForKey:@"title"]];
        NSString *descriptionString = txtFileContent;//[NSString stringWithFormat:@"%@",[self stringAfterString:@"\n" inString:txtFileContent]];
        
        titleString = [titleString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        descriptionString = [descriptionString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        strReadableText = [NSString stringWithFormat:@"%@. %@",titleString,descriptionString];
        
        NSString *trimmedString = [titleString stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSMutableArray *arrParagraphs = [[NSMutableArray alloc] init];
        arrParagraphs = [[descriptionString componentsSeparatedByString:@"\n"] mutableCopy];
        
        NSInteger centerElementOfArray = arrParagraphs.count/2;
        
        for (int i = 0; i < arrParagraphs.count; i++) {
            NSString *paragraphString = [NSString stringWithFormat:@"%@",[arrParagraphs objectAtIndex:i]];
            
            if (i == arrParagraphs.count-1){
                
                if (![UtilityManager isStringNull:paragraphString]) {
                    
                    if (2 < [arrImages count]){
                        //Image Add
                        [self createTextCell:paragraphString];
                        NSString* previewPath = [NSString stringWithFormat:@"%@",[[arrImages objectAtIndex:2] objectForKey:@"image"]];
                        [self createImageCell:previewPath];
                        
                    }else{
                        
                        //Not Exist
                        if (![UtilityManager isStringNull:paragraphString]) {
                            [self createTextCell:paragraphString];
                        }
                    }
                }
                
            }else if (i == centerElementOfArray){
                
                if (![UtilityManager isStringNull:paragraphString]) {
                    
                    if (1 < [arrImages count]){
                        
                        [self createTextCell:paragraphString];
                        NSString* previewPath = [NSString stringWithFormat:@"%@",[[arrImages objectAtIndex:1] objectForKey:@"thumbnail"]];
                        [self createImageCell:previewPath];
                        
                    }else{
                        
                        //Not Exist
                        if (![UtilityManager isStringNull:paragraphString]) {
                            [self createTextCell:paragraphString];
                        }
                    }
                }
                
            }else{
                
                if (![UtilityManager isStringNull:paragraphString]) {
                    
                    [self createTextCell:paragraphString];
                }
            }
        }
    }
    
    CGRect oldContVW = contentVW.frame;
    oldContVW.size.height = yPos;
    contentVW.frame = oldContVW;
    if (IS_IPAD) {
        [contentScrollView setContentSize:CGSizeMake(screenWidths, yPos+oldContVW.origin.y+60)];
    }else{
        [contentScrollView setContentSize:CGSizeMake(screenWidths, yPos+oldContVW.origin.y)];
    }
    [SVProgressHUD dismiss];
}

-(void)createTextCell:(NSString *)paragraphString {
    
    UILabel *lblDetail = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos, screenWidths-40, 21)];
    lblDetail.numberOfLines = 0;
    
    NSString *trimmedString = [paragraphString stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    lblDetail.text = trimmedString;
    if ([UtilityManager isStringNull:trimmedString]) {
        return;
    }
    
    if ([paragraphString length]<35){
        //Bold Text
        if (IS_IPAD) {
            lblDetail.font = [UIFont fontWithName:@"Nunito-Bold" size:20.0];
        }else{
            lblDetail.font = [UIFont fontWithName:@"Nunito-Bold" size:18.0];
        }
        lblDetail.textColor = [UIColor darkGrayColor];
        [lblDetail sizeToFit];
        yPos = yPos + lblDetail.frame.size.height + 5;
    }else{
        if (IS_IPAD) {
            lblDetail.font = [UIFont fontWithName:@"Nunito" size:20.0];
        }else{
            lblDetail.font = [UIFont fontWithName:@"Nunito" size:18.0];
        }
        
        lblDetail.textColor = [UIColor colorWithRed:165.0/255.0 green:165.0/255.0 blue:165.0/255.0 alpha:1.0];
        
        [lblDetail sizeToFit];
        yPos = yPos + lblDetail.frame.size.height + 10;
    }
    [contentVW addSubview:lblDetail];
}

-(void)createImageCell:(NSString *)previewPath{
    CGFloat imageWidth = screenWidths-40;
    CGFloat imageHeight = 200;
    if (IS_IPAD) {
        imageWidth = 500;
        imageHeight = 250;
    }
    
    CGFloat imX = (screenWidths/2) - (imageWidth/2);
    UIImageView *imgShow = [[UIImageView alloc] initWithFrame:CGRectMake(imX, yPos, imageWidth, imageHeight)];
    
    UIImage* image = [UIImage imageWithContentsOfFile:previewPath];
    imgShow.image = image;
    if (image == nil) {
        [imgShow setImageWithURL:[NSURL URLWithString:previewPath]];
        //[imgShow setImage:[UIImage imageNamed:@"image1"]];
    }
    
    if ([strFromCategirized isEqualToString:@"1"]){
        NSMutableArray *arrayImages = [[nodeDict objectForKey:@"images"] mutableCopy];
        for (NSDictionary* dict in arrayImages){
            NSString* thumb = [dict objectForKey:@"thumbnail"];
            if ([thumb isEqualToString:previewPath]){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [SGImageCache getImageForURL:[dict objectForKey:@"image"] thenDo:^(UIImage *image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [imgShow setImage:image];
                            [fullImages addObject:[dict objectForKey:@"image"]];
                        });
                    }];
                });
            }
        }
    }else{
        NSString* imageName = [[previewPath componentsSeparatedByString:@"/"]lastObject];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [facade downloadSingleImageFileForPath:imageName withNodeID:nodeID withCityName:cityPrefix withCompletion:^(NSString* imagePath, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    imgShow.image = [UIImage imageWithContentsOfFile:imagePath];
                    [fullImages addObject:imagePath];
                });
            }];
        });
    }
    
    imgShow.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton *btnTapOnImg = [UIButton buttonWithType:UIButtonTypeCustom];
    btnTapOnImg.frame = imgShow.frame;
    btnTapOnImg.tag = loadedImages.count;
    [btnTapOnImg addTarget:self action:@selector(tapOnImage:) forControlEvents:UIControlEventTouchUpInside];
    
    [loadedImages addObject:previewPath];
    [contentVW addSubview:imgShow];
    //[contentVW addSubview:btnTapOnImg];
    yPos = yPos + imageHeight + 10;
}

-(IBAction)tapOnImage:(id)sender{
    
    if ([sender tag] < loadedImages.count) {
        
        NSString *srcOfImage = [NSString stringWithFormat:@"%@",[loadedImages objectAtIndex:[sender tag]]];
        SingleImageVC *objSingleImageVC = [[SingleImageVC alloc] initWithNibName:IS_IPAD ? @"SingleImageVC_iPad" : @"SingleImageVC" bundle:nil];
        objSingleImageVC.strPath = srcOfImage;
        objSingleImageVC.nodeAlias = [self.nodeDict objectForKey:@"nodeAlias"];
        UINavigationController *navPresent = [[UINavigationController alloc] initWithRootViewController:objSingleImageVC];
        [navPresent setNavigationBarHidden:YES];
        [self.navigationController presentViewController:navPresent animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSString *)scanString:(NSString *)string startTag:(NSString *)startTag endTag:(NSString *)endTag{
    
    NSString* scanString = @"";
    
    if (string.length > 0) {
        
        NSScanner* scanner = [[NSScanner alloc] initWithString:string];
        
        @try {
            [scanner scanUpToString:startTag intoString:nil];
            scanner.scanLocation += [startTag length];
            [scanner scanUpToString:endTag intoString:&scanString];
        }
        @catch (NSException *exception) {
            return nil;
        }
        @finally {
            return scanString;
        }
    }
    return scanString;
}
-(NSString*)stringBeforeString:(NSString*)match inString:(NSString*)string{
    
    if ([string rangeOfString:match].location != NSNotFound){
        
        NSString *preMatch;
        NSScanner *scanner = [NSScanner scannerWithString:string];
        [scanner scanUpToString:match intoString:&preMatch];
        return preMatch;
        
    }else{
        
        return string;
    }
}
-(NSString*)stringAfterString:(NSString*)match inString:(NSString*)string{
    
    if ([string rangeOfString:match].location != NSNotFound){
        
        NSScanner *scanner = [NSScanner scannerWithString:string];
        [scanner scanUpToString:match intoString:nil];
        NSString *postMatch;
        
        if(string.length == scanner.scanLocation){
            postMatch = [string substringFromIndex:scanner.scanLocation];
        }else{
            postMatch = [string substringFromIndex:scanner.scanLocation + match.length];
        }
        return postMatch;
        
    }else{
        
        return string;
    }
}
- (void)scrollViewDidScroll:(UIScrollView*)scrollView{
    
    float yPos = scrollView.contentOffset.y;
    
    if (!IS_IPAD) {
        if (scrollView.contentOffset.y >= 325) {
            yPos = 325;
        }
    }
    
    float scale = 1.0f + fabs(yPos)  / scrollView.frame.size.height;
    
    scale = MAX(0.0f, scale);
    
    detailImgView.transform = CGAffineTransformMakeScale(scale, scale);
    imgOverlay.transform = CGAffineTransformMakeScale(scale, scale);
    blurView.alpha = fabs(scrollView.contentOffset.y) / 130;
    NSLog(@"%.2f",fabs(scrollView.contentOffset.y));
    NSLog(@"Scall = %.2f",fabs(scale));
    
    float matchScall = 1.45;
    if (IS_IPHONE) {
        matchScall = 1.43;
        if (IS_IPHONE_X) {
            matchScall = 1.35;
        }
    }
    
    if (scale > matchScall)
    {
        navBarView.hidden = NO;
    }
    else
    {
        navBarView.hidden = YES;
    }
}


-(void)showDetailScrlView:(NSString*)detailStrng withParagraphArray:(NSMutableArray*)pragraphArr
{
    CGSize MiddleImageframe;
    
    if (@available(iOS 11.0, *)) {
        detailScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    NSInteger centerElementOfArray = pragraphArr.count/2;
    if (centerElementOfArray==1)
    {
        centerElementOfArray = 2;
    }
    NSArray *imagesArr = [[nodeDict objectForKey:@"images"] mutableCopy];
    NSString *imgPath = @"";
    if ([imagesArr count]>1){
        imgPath = [NSString stringWithFormat:@"%@",[[imagesArr objectAtIndex:1] objectForKey:@"thumbnail"]];

    }else{
        imgPath = [NSString stringWithFormat:@"%@",[[imagesArr objectAtIndex:0] objectForKey:@"thumbnail"]];

    }
    UIFont *textFont = [UIFont fontWithName:@"Nunito-Regular" size:16.0];
    if (IS_IPAD) {
        textFont = [UIFont fontWithName:@"Nunito-Regular" size:21.0];
    }
    
    NSData *dt = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgPath]];
    NSDictionary *attrDict = @{
                               NSFontAttributeName : textFont,
                               NSForegroundColorAttributeName : [UIColor darkGrayColor]
                               };
    NSMutableAttributedString *mainAttributedString = [[NSMutableAttributedString alloc]init];
    for (int i = 0; i < pragraphArr.count; i++)
    {
        if (![UtilityManager isStringNull:[pragraphArr objectAtIndex:i]])
        {
            NSString *pragraphString = [pragraphArr objectAtIndex:i];
            NSMutableAttributedString *attributedString;
            if(pragraphString.length > 40)
            {
                attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n",pragraphString] attributes:attrDict];
            }
            else
            {
                attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",pragraphString] attributes:attrDict];
            }
            
            if (centerElementOfArray == i+1)
            {
                NSMutableAttributedString *SpaceAttributedString = [[NSMutableAttributedString alloc] initWithString:@" \n"];
                [mainAttributedString appendAttributedString:SpaceAttributedString];
                NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                textAttachment.image = [UIImage imageWithData:dt];
                CGFloat oldWidth = textAttachment.image.size.width;
                CGFloat scaleFactor = oldWidth / (detailTxtView.frame.size.width - 10);
                textAttachment.image = [UIImage imageWithCGImage:textAttachment.image.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
                MiddleImageframe = textAttachment.image.size;
                NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
                [mainAttributedString appendAttributedString:attrStringWithImage];
                NSMutableAttributedString *SpaceAttributedString2 = [[NSMutableAttributedString alloc] initWithString:@" \n \n"];
                [mainAttributedString appendAttributedString:SpaceAttributedString2];
            }
            [mainAttributedString appendAttributedString:attributedString];
        }
    }
    
    detailTxtView.attributedText = mainAttributedString;
    
    CGFloat textVWWidth = screenWidths - 16;
    if (IS_IPAD) {
        textVWWidth = screenWidths - 42;
    }
    
    NSString *name = detailStrng;
    CGSize size2 = [self findHeightForText:name havingWidth:textVWWidth];
    
    CGRect textViewFrame = detailTxtView.frame;
    textViewFrame.size.height = size2.height + 100 + MiddleImageframe.height;
    detailTxtView.frame = textViewFrame;
    detailTxtView.userInteractionEnabled = NO;
    
    CGFloat contentHeight = detailCellView.frame.origin.y + detailCellView.frame.size.height + size2.height + 80 + MiddleImageframe.height;
    if(IS_IPAD){
        contentHeight = detailCellView.frame.origin.y + detailCellView.frame.size.height + size2.height + 100 + MiddleImageframe.height;
    }
    
    contentScrollView.scrollEnabled = YES;
    [contentScrollView setContentSize:CGSizeMake(self.view.frame.size.width, contentHeight)];
    
    CGRect currentViewFrame = curveBgView.frame;
    currentViewFrame.size.height = contentHeight;
    curveBgView.frame = currentViewFrame;
}

-(void)setDetailScrollView:(NSString*)detailString
{
    NSLog(@"sdflsdjflsdakjf");
}

- (CGSize)findHeightForText:(NSString *)text havingWidth:(CGFloat)widthValue
{
    CGSize size = CGSizeZero;
    if (text) {
        CGRect frame = [text boundingRectWithSize:CGSizeMake(widthValue, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName:detailTxtView.font } context:nil];
        size = CGSizeMake(frame.size.width, frame.size.height + 1);
    }
    return size;
}

- (IBAction)closeBtnAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    [btnBack sendActionsForControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - AllButtonAction;
-(IBAction)userHandlerActions:(id)sender{
    
    if (sender == btnBack){
        
        //For stop reading
        detailImgView.hidden = YES;
        imgOverlay.hidden = YES;
        [[TextReader sharedInstance] stopAudio];
        [[UserEventsLogger sharedInstance] registerBackBtnClickEventWithName:@"PoiTextScreen_Back" from:self];
        [self.navigationController popViewControllerAnimated:YES];
        
    }else if (sender == btnGallary || sender == btnGallaryWhite){
        [FIRAnalytics logEventWithName:@"PoiScreen_ImagesButtonClick" parameters:nil];
    }else if (sender == btnMap || sender == btnMapWhite){
        
        OnlineCityMapsVC *onlineCityMap = [[OnlineCityMapsVC alloc] initWithNibName:IS_IPAD? @"OnlineCityMapsVC_iPad": @"OnlineCityMapsVC" bundle:nil];
        onlineCityMap.isFromPoiTextDetail = @"1";
        onlineCityMap.strFromCategirized = strFromCategirized;
        
        if ([strFromCategirized isEqualToString:@"1"]) {
            onlineCityMap.etipsArray = etipsArray;
            onlineCityMap.dicCityDetail = dicCityDetail;
            onlineCityMap.baseNodeDict = baseNodeDict;
        }else{
            
            NSString *cPrefix = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"cityPrefix"]];
            NSString *nodeID = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"nodeID"]];
            
            NSMutableDictionary *node = [nodeDict mutableCopy];
            [node setObject:nodeID forKey:@"id"];
            [node setObject:cPrefix forKey:@"prefix"];
            
            
            NSString *nodePrefix = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"nodePrefix"]];
            NSString *nodeTitle = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"nodeAlias"]];
            NSString *nodeLat = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"latitude"]];
            NSString *nodeLong = [NSString stringWithFormat:@"%@",[nodeDict objectForKey:@"longitude"]];
            
            NSMutableDictionary *baseNodeDat = [[NSMutableDictionary alloc] init];
            [baseNodeDat setObject:nodeID forKey:@"id"];
            [baseNodeDat setObject:nodePrefix forKey:@"prefix"];
            [baseNodeDat setObject:nodeTitle forKey:@"title"];
            [baseNodeDat setObject:nodeLat forKey:@"latitude"];
            [baseNodeDat setObject:nodeLong forKey:@"longitude"];
            
            NSMutableArray *etisAr = [[NSMutableArray alloc] init];
            [etisAr addObject:baseNodeDat];
            
            onlineCityMap.etipsArray = [etisAr mutableCopy];
            onlineCityMap.baseNodeDict = node;
        }
        [FIRAnalytics logEventWithName:@"PoiScreen_MapButtonClick" parameters:nil];
        
        [self.navigationController pushViewController:onlineCityMap animated:YES];
        
    }else if (sender == btnMicrophone || sender == btnMicrophoneWhite){
        [FIRAnalytics logEventWithName:@"PoiScreen_MicButtonClick" parameters:nil];
        if (isReadingContent == YES){
            
            imgMicIcon.image = [UIImage imageNamed:@"mic_on_gray_ic"];
            imgMicIconWhite.image = [UIImage imageNamed:@"mic_on_white_ic"];
            [[TextReader sharedInstance] stopAudio];
            isReadingContent = NO;
            
        }else{
            
            NSLog(@"Start HTML Reading");
            
            if (silentModeON == YES){
                
                if (isReadingContent == NO){
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Silent mode" message:@"To hear audio please change to non silent mode" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
                
            }else{
                
                [[TextReader sharedInstance] transformTextToLocalizedVoice:strReadableText];
                imgMicIcon.image = [UIImage imageNamed:@"mic_off_gray_ic"];
                imgMicIconWhite.image = [UIImage imageNamed:@"mic_off_white_ic"];
            }
            
            isReadingContent = YES;
        }
    }
}



-(void)filterDataNode{
    
    NSArray *imagesArr = [[nodeDict objectForKey:@"images"] mutableCopy];
    nodes = [[NSMutableArray alloc] init];
    for (int i=0; i<imagesArr.count; i++) {
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
        
        NSString *imgPath = [NSString stringWithFormat:@"%@",[[imagesArr objectAtIndex:i] objectForKey:@"thumbnail"]];
        
        [tempDict setObject:imgPath forKey:@"imagePath"];
        
        [nodes addObject:tempDict];
        if (i==0) {
            
            [imgGalleryWhite setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
                NSLog(@"OPEN!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refressCurrentLabel" object:nil userInfo:nil];
            }onClose:^{
                NSLog(@"CLOSE!");
                
            }];
            
            [imgGallery setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
                NSLog(@"OPEN!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refressCurrentLabel" object:nil userInfo:nil];
            }onClose:^{
                NSLog(@"CLOSE!");
            }];
            
            /*imgFistGellry.image = [UIImage imageNamed:@"avtar_place"];
            [imgFistGellry setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
                NSLog(@"OPEN!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refressCurrentLabel" object:nil userInfo:nil];
            }onClose:^{
                NSLog(@"CLOSE!");
                imgFistGellry.alpha = 0.1;
            }];
            
            imgFirstGallryWhite.image = [UIImage imageNamed:@"avtar_place"];
            
            [imgFirstGallryWhite setupImageViewerWithDatasource:self initialIndex:0 onOpen:^{
                NSLog(@"OPEN!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refressCurrentLabel" object:nil userInfo:nil];
            }onClose:^{
                NSLog(@"CLOSE!");
                imgFirstGallryWhite.alpha = 0.1;
            }];*/
        }
    }
}

-(void)receiveNoti:(NSNotification *)notifcation{
    
    if ([[notifcation name] isEqualToString:@"finishedReadingText"]){
        
        if (silentModeON == YES){
            
            [[TextReader sharedInstance] stopAudio];
            
        }else{
            
            imgMicIcon.image = [UIImage imageNamed:@"mic_on_gray_ic"];
            imgMicIconWhite.image = [UIImage imageNamed:@"mic_on_white_ic"];
            
            [[TextReader sharedInstance] stopAudio];
            isReadingContent = NO;
        }
    }
}
-(void)startHTMLReadingBasedOnSlientSwitch{
    
    NSLog(@"isReadingContent: %d",isReadingContent);
    NSLog(@"silentModeON: %d",silentModeON);
    
    [[TextReader sharedInstance] pauseAudio];
    [[TextReader sharedInstance] stopAudio];
    
    if (isReadingContent == YES && silentModeON == NO){
        
        NSLog(@"Start HTML reading from starting");
        
        imgMicIcon.image = [UIImage imageNamed:@"mic_off_gray_ic"];
        imgMicIconWhite.image = [UIImage imageNamed:@"mic_off_white_ic"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[TextReader sharedInstance] transformTextToLocalizedVoice:strReadableText];
        });
        
        isReadingContent = YES;
        
    }else{
        
        imgMicIcon.image = [UIImage imageNamed:@"mic_on_gray_ic"];
        imgMicIconWhite.image = [UIImage imageNamed:@"mic_on_white_ic"];
        
    }
}

#pragma mark - FacebookImageViewer
- (NSInteger) numberImagesForImageViewer:(MHFacebookImageViewer *)imageViewer{
    
    if ([strFromCategirized isEqualToString:@"1"]) {
        return [nodes count];
    }else{
        return arrImages.count;
    }
}

- (NSURL*) imageURLAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer *)imageViewer{
    
    if ([strFromCategirized isEqualToString:@"1"]) {
        imageViewer.dataArray = nodes;
        imageViewer.isFromDetailPage = @"1";
        imageViewer.currentNavigationController = self;
        
        NSDictionary *albumData = [nodes objectAtIndex:index];
        NSString *previewImagePath = [NSString stringWithFormat:@"%@",[albumData valueForKey:@"imagePath"]];
        if (previewImagePath.length == 0) {
            previewImagePath = @"";
        }
        if (index < [fullImages count]){
            previewImagePath = [NSString stringWithFormat:@"%@",[fullImages objectAtIndex:index]];
        }
        return [NSURL URLWithString:previewImagePath];
    }else{
        
        imageViewer.isFromDetailPage = @"1";
        imageViewer.currentNavigationController = self;
        NSString *previewImagePath = [NSString stringWithFormat:@"%@",[arrImages objectAtIndex:index]];
        if (index < [fullImages count]){
            previewImagePath = [NSString stringWithFormat:@"%@",[fullImages objectAtIndex:index]];
        }
        
        if (previewImagePath.length == 0) {
            previewImagePath = @"";
        }
        return [NSURL fileURLWithPath:previewImagePath];
    }
}

- (UIImage*) imageDefaultAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer *)imageViewer{
    return [UIImage imageNamed:@"avtar_place"];
}

-(NSString *)getScreenTitle {
    [FIRAnalytics logEventWithName:@"PoiScreen_ImagesButtonClick" parameters:nil];
    return blurLbl.text;
}

@end
