//
//  SingleImageVC.h
//  Trip Guider
//
//  Created by Nik on 12/08/17.
//  Copyright © 2017 HKinfoway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface SingleImageVC : UIViewController <UIScrollViewDelegate>
{
    UIImageView *currentImg;
    IBOutlet UILabel *tittleLbl;
}
@property (strong, nonatomic) NSString *strPath;
@property (strong, nonatomic) NSString *nodeAlias;

@end
