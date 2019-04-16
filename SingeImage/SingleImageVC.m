//
//  SingleImageVC.m
//  Trip Guider
//
//  Created by Nik on 12/08/17.
//  Copyright © 2017 HKinfoway. All rights reserved.
//

#import "SingleImageVC.h"

@interface SingleImageVC ()

@end

@implementation SingleImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *scr = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, screenWidths, screenHeights-64)];
    if(IS_IPAD)
    {
//        scr.frame = CGRectMake(0, 80, screenWidths, screenHeights-80);
    }
    [scr setContentSize:scr.bounds.size];
    scr.backgroundColor = [UIColor clearColor];
    scr.minimumZoomScale = 1.0  ;
    scr.maximumZoomScale = 5.0;
    scr.delegate = self;
    
    currentImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidths, screenHeights-64)];
    if(IS_IPAD)
    {
//        currentImg.frame = CGRectMake(0, 0, screenWidths, screenHeights-80);
    }
    currentImg.contentMode = UIViewContentModeScaleAspectFit;
    currentImg.image = [UIImage imageWithContentsOfFile:_strPath];
    [scr addSubview:currentImg];
    [self.view addSubview:scr];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    tittleLbl.text = self.nodeAlias;
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return currentImg;
}

-(IBAction)onClickBack:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGSize imgViewSize = currentImg.frame.size;
    CGSize imageSize = currentImg.image.size;
    
    CGSize realImgSize;
    if(imageSize.width / imageSize.height > imgViewSize.width / imgViewSize.height) {
        realImgSize = CGSizeMake(imgViewSize.width, imgViewSize.width / imageSize.width * imageSize.height);
    }
    else {
        realImgSize = CGSizeMake(imgViewSize.height / imageSize.height * imageSize.width, imgViewSize.height);
    }
    
    CGRect fr = CGRectMake(0, 0, 0, 0);
    fr.size = realImgSize;
    currentImg.frame = fr;
    
    CGSize scrSize = scrollView.frame.size;
    float offx = (scrSize.width > realImgSize.width ? (scrSize.width - realImgSize.width) / 2 : 0);
    float offy = (scrSize.height > realImgSize.height ? (scrSize.height - realImgSize.height) / 2 : 0);
    
    // don't animate the change.
    scrollView.contentInset = UIEdgeInsetsMake(offy, offx, offy, offx);
}

@end
