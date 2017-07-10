//
//  OpenCVWrapper.h
//  caffe2-ios
//
//  Created by Kaiwen Yuan on 2017-04-28.
//  Copyright © 2017 Kaiwen Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface CVWrapper : NSObject

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage;

+ (UIImage*) preprocessImage: (UIImage*) inputImage flip:(Boolean) flip;

//+ (UIImage*) postprocessImage: (NSArray<NSNumber*>*)predictedResult image:(UIImage*) image background:(UIImage*) background height:(NSInteger)H width:(NSInteger)W;

+ (UIImage*) postprocessImage: (NSArray<NSNumber*>*)predictedResult image:(UIImage*) image background:(UIImage*) background flip:(Boolean) flip showMask:(Boolean) showMask showContour:(Boolean) showContour;

+ (UIImage*) drawBBox: (NSArray<NSNumber*>*)predictedResult image:(UIImage*) image;


@end
NS_ASSUME_NONNULL_END
