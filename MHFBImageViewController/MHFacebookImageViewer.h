
#import <UIKit/UIKit.h>

typedef void (^MHFacebookImageViewerOpeningBlock)(void);
typedef void (^MHFacebookImageViewerClosingBlock)(void);

@class MHFacebookImageViewer;
@protocol MHFacebookImageViewerDatasource <NSObject>
@required
- (NSInteger) numberImagesForImageViewer:(MHFacebookImageViewer*) imageViewer;
- (NSURL*) imageURLAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer*) imageViewer;
- (UIImage*) imageDefaultAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer*) imageViewer;
@optional
-(NSString *)getScreenTitle;
@end

@interface MHFacebookImageViewer : UIViewController
@property (weak, readonly, nonatomic) UIViewController *rootViewController;
@property (nonatomic,strong) UIViewController *currentNavigationController;
@property (nonatomic,strong) NSURL * imageURL;
@property (nonatomic,strong) UIImageView * senderView;
@property (nonatomic,strong) UILabel *textLbl;
@property (nonatomic,strong) UIButton *textLblOverlay;
@property (nonatomic,strong)NSMutableArray *dataArray;
@property (nonatomic,strong)NSString *isFromDetailPage;
@property (nonatomic,weak) MHFacebookImageViewerOpeningBlock openingBlock;
@property (nonatomic,weak) MHFacebookImageViewerClosingBlock closingBlock;
@property (nonatomic,weak) id<MHFacebookImageViewerDatasource> imageDatasource;
@property(nonatomic,assign) NSInteger currentIndex;
@property (nonatomic,assign) NSInteger initialIndex;
@property (nonatomic,assign) NSString* cityAlias;

- (void)presentFromRootViewController;
- (void)presentFromViewController:(UIViewController *)controller;

@end

@interface MHFacebookImageViewerTapGestureRecognizer : UITapGestureRecognizer
@property(nonatomic,strong) NSURL * imageURL;
@property(nonatomic,strong) MHFacebookImageViewerOpeningBlock openingBlock;
@property(nonatomic,strong) MHFacebookImageViewerClosingBlock closingBlock;
@property(nonatomic,weak) id<MHFacebookImageViewerDatasource> imageDatasource;
@property(nonatomic,assign) NSInteger initialIndex;
@property(nonatomic,assign) NSInteger currentIndex;

@end
