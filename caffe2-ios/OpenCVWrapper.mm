//
//  OpenCVWrapper.m
//  caffe2-ios
//
//  Created by Kaiwen Yuan on 2017-04-28.
//  Copyright © 2017 Kaiwen Yuan. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation CVWrapper

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
    return inputImage;
}

+ (UIImage*) preprocessImage: (UIImage*) inputImage
{
    //Transform UIImage to cv::Mat
    cv::Mat imageMat;
    UIImageToMat(inputImage, imageMat);
    cv::Mat flipImageMat;
    cv::transpose(imageMat, flipImageMat);
    cv::flip(flipImageMat, flipImageMat, 1);
    int H = flipImageMat.rows;
    int W = flipImageMat.cols;
    int npixels = H * W;
    
    int C = imageMat.channels();
    float b_mean = 104.00698793f;
    float g_mean = 116.66876762f;
    float r_mean = 122.67891434f;
    
    // rgb, minus mean
    cv::Mat bgra(H, W, CV_32FC4);
    
    for(int i=0; i<H; i++){
        for(int j=0; j<W; j++){
            bgra.at<cv::Vec4f>(i,j)[0]= flipImageMat.at<cv::Vec4b>(i,j)[0] - b_mean;
            bgra.at<cv::Vec4f>(i,j)[1]= flipImageMat.at<cv::Vec4b>(i,j)[1] - g_mean;
            bgra.at<cv::Vec4f>(i,j)[2]= flipImageMat.at<cv::Vec4b>(i,j)[2] - r_mean;
            bgra.at<cv::Vec4f>(i,j)[3]= flipImageMat.at<cv::Vec4b>(i,j)[3];
        }
    }
    
//    cv::Mat bgr;
//    cv::cvtColor(imageMat, bgr, cv::COLOR_BGRA2BGR);
//    int nchan = bgr.channels();
//    float * input_data = new float[npixels*nchan];
//    
//    uchar * ptr = bgr.data;
//    for (int i=0; i<H; i++){
//        for(int j=0; j<W; j++){
//            input_data[i*W + j] = bgr.at<cv::Vec3b>(i,j)[0] - b_mean;
//            input_data[i*W + j + npixels] = bgr.at<cv::Vec3b>(i,j)[1] - g_mean;
//            input_data[i*W + j + npixels*2] = bgr.at<cv::Vec3b>(i,j)[2] - r_mean;
//        }
//    }
//    UIImage(*input_data);
    return MatToUIImage(bgra);
    
}

+ (UIImage*) postprocessImage: (NSArray<NSNumber*>*)predictedResult image:(UIImage*) image background:(UIImage*) background
{
    cv::Mat seg;
    UIImageToMat(image, seg);
    
    // rotate clockwise 90 degree
    cv::Mat flipSeg;
    cv::transpose(seg, flipSeg);
    cv::flip(flipSeg, flipSeg, 1);
    int H = flipSeg.rows;
    int W = flipSeg.cols;
    int h = H/8+1;
    int w = W/8+1;
    int C = flipSeg.channels();
    int o_size = predictedResult.count;
    int o_npixels = o_size>>1;
    //    assert(h*w == o_npixels);
    
    
    //    Mat raw_score(h, w, CV_8UC1);
    //    for(int i=0; i<o_npixels; i++){
    //        float score_p = exp(2*(res[i+o_npixels] - res[i]));
    //        raw_score.ptr<uchar>()[i] = uchar(255.0 * score_p / (1+score_p));
    //    }
    //
    //    Mat resized;
    //    resize(raw_score, resized, Size(dstW, dstH));
    //    cvtColor(resized, seg, COLOR_GRAY2RGBA);
    //
    
    cv::Mat raw_score(h, w, CV_32FC1);
    for(int i=0; i<o_npixels; i++){
        //        raw_score.ptr<float>()[i] = res[i+o_npixels] > res[i];
        float score_p = exp(predictedResult[i+o_npixels].floatValue - predictedResult[i].floatValue);
        raw_score.ptr<float>()[i] = score_p / (1+score_p);
    }
    
    cv::Mat resized;
    cv::resize(raw_score, resized, cv::Size(W, H));
    
    //    Mat filtered(resized.size(), resized.type());
    //    bilateralFilter(resized, filtered, 3, 6, 3);
    
    cv::Mat bg;
    cv::Mat backgroundMat;
    UIImageToMat(background, bg);
    cv::resize(bg, backgroundMat, cv::Size(W, H));
    int tmp = backgroundMat.channels();
    for(int i=0; i<H; i++){
        for(int j=0; j<W; j++){
            for(int k=0; k<3; k++){
                flipSeg.at<cv::Vec4b>(i, j)[k] =
                int(flipSeg.at<cv::Vec4b>(i, j)[k] * resized.ptr<float>()[i*W+j] +
                    backgroundMat.at<cv::Vec4b>(i, j)[k] * (1 - resized.ptr<float>()[i*W+j])); // backgroundMat and flipSeg(derived frome image:UIImage) have identical rgba/bgra format
//                int(255*resized.ptr<float>()[i*W+j]);
            }
        }
    }

    
    return MatToUIImage(flipSeg);
}

@end
