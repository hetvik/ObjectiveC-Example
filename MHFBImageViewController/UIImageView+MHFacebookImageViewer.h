
#import <Foundation/Foundation.h>
#import "MHFacebookImageViewer.h"

@interface UIImageView (MHFacebookImageViewer)

- (void) setupImageViewer;
- (void) setupImageViewerWithCompletionOnOpen:(MHFacebookImageViewerOpeningBlock)open onClose:(MHFacebookImageViewerClosingBlock)close;
- (void) setupImageViewerWithImageURL:(NSURL*)url;
- (void) setupImageViewerWithImageURL:(NSURL *)url onOpen:(MHFacebookImageViewerOpeningBlock)open onClose:(MHFacebookImageViewerClosingBlock)close;
- (void) setupImageViewerWithDatasource:(id<MHFacebookImageViewerDatasource>)imageDatasource onOpen:(MHFacebookImageViewerOpeningBlock)open onClose:(MHFacebookImageViewerClosingBlock)close;
- (void) setupImageViewerWithDatasource:(id<MHFacebookImageViewerDatasource>)imageDatasource initialIndex:(NSInteger)initialIndex onOpen:(MHFacebookImageViewerOpeningBlock)open onClose:(MHFacebookImageViewerClosingBlock)close;
- (void)removeImageViewer;
@property (retain, nonatomic) MHFacebookImageViewer *imageBrowser;
@end
