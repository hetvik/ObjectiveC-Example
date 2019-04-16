//
//  NewDetailViewController.h
//  TR_1708
//
//  Copyright © 2018 Anand Patel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlientSwitchDetector.h"

@interface PoiTextDetailVC : UIViewController
{
    IBOutlet UIVisualEffectView *blurView;
    IBOutlet UIScrollView *detailScrollView;
    IBOutlet UIImageView *detailImgView;
    IBOutlet UIImageView *imgOverlay;
    IBOutlet UIView *curveBgView;
    IBOutlet UIView *detailCellView;
    IBOutlet UITextView *detailTxtView;
    IBOutlet UILabel *PlaceLbl;
    IBOutlet UIScrollView *contentScrollView;
    
    NSString *plainTextFromHTML;
    NSString* strReadableText;
    IBOutlet UILabel *blurLbl;
    IBOutlet UIView *navBarView;
    NSMutableArray *nodes;
    
    IBOutlet UIImageView *imgFistGellry;
    IBOutlet UIImageView *imgFirstGallryWhite;
    IBOutlet UIImageView *imgBackicn;
    IBOutlet UIButton *btnBack;
    IBOutlet UIImageView *imgGallery;
    IBOutlet UIImageView *imgGalleryWhite;
    IBOutlet UIImageView *imgMap;
    IBOutlet UIButton *btnGallary;
    IBOutlet UIButton *btnGallaryWhite;
    IBOutlet UIButton *btnMap;
    IBOutlet UIButton *btnMapWhite;
    IBOutlet UIButton *btnMicrophone;
    IBOutlet UIButton *btnMicrophoneWhite;
    IBOutlet UIImageView *mapIcon;
    IBOutlet UIImageView *mapIconWhite;
    IBOutlet UIImageView *imgMicIcon;
    IBOutlet UIImageView *imgMicIconWhite;
    IBOutlet UIView *ArtPoiTitleView;
    IBOutlet UILabel *artistLbl;
    IBOutlet UILabel *addressLbl;
    NSString *nodeID;
    BOOL isReadingContent;
    BOOL silentModeON;
    
    IBOutlet UIScrollView *scrlMain;
    IBOutlet UIView *contentVW;
}
@property (weak, nonatomic) NSMutableArray *etipsArray;
@property (nonatomic, strong) NSMutableDictionary *dicCityDetail;

@property (nonatomic, retain) NSMutableDictionary *baseNodeDict;
@property (nonatomic, retain) NSMutableDictionary *nodeDict;
@property (nonatomic, retain) NSDictionary *artNodeDict;
@property (nonatomic, retain) NSString *strFromCategirized;
@property (nonatomic, retain) NSString *cityPrefix;

- (IBAction)closeBtnAction:(id)sender;
@property (nonatomic,strong) SlientSwitchDetector * detector;
@end
