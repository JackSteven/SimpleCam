//
//  SCFaceDetectorManager.m
//  SimpleCam
//
//  Created by Lyman Li on 2019/6/9.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#include "stasm_lib.h"
#include <opencv2/face.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/imgcodecs/ios.h>
#include <opencv2/imgproc/imgproc.hpp>

#import "SCFaceDetectorManager.h"

@implementation SCFaceDetectorManager

+ (void)detectWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    cv::Mat cvImage = [self grayMatWithSampleBuffer:sampleBuffer];
    cvImage = [self resizeMat:cvImage toWidth:500];
    const char *imgData = (const char *)cvImage.data;
    
    // 是否找到人脸
    int foundface;
    // stasm_NLANDMARKS 表示人脸关键点数，乘 2 表示要分别存储 x， y
    float landmarks[2 * stasm_NLANDMARKS];
    
    // 获取宽高
    int imgCols = cvImage.cols;
    int imgRows = cvImage.rows;
    
    // 训练库的目录，直接传 [NSBundle mainBundle].bundlePath 就可以，会自动找到所有文件
    const char *xmlPath = [[NSBundle mainBundle].bundlePath UTF8String];
    
    // 返回 0 表示出错
    int stasmActionError = stasm_search_single(&foundface,
                                               landmarks,
                                               imgData,
                                               imgCols,
                                               imgRows,
                                               "",
                                               xmlPath);
    // 打印错误信息
    if (!stasmActionError) {
        printf("Error in stasm_search_single: %s\n", stasm_lasterr());
    }
    
    // 释放cv::Mat
    cvImage.release();
    
    // 识别到人脸
    if (foundface) {
        
    }
}

#pragma mark - Private

// 生成灰度图矩阵
+(cv::Mat)grayMatWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    // 检查是否 YUV 编码
    if (format != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        NSLog(@"Only YUV is supported");
        return cv::Mat();
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat colCount = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    if (width != colCount) {
        width = colCount;
    }
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    // CV_8UC1 表示单通道矩阵，转换为单通道灰度图后，可以使识别的计算速度提高
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return mat;
}

// 矩阵缩放
+ (cv::Mat)resizeMat:(cv::Mat)mat toWidth:(CGFloat)width {
    CGFloat orginWidth = mat.cols;
    CGFloat orginHeight = mat.rows;
    int reCols = width;
    int reRows = (int)((CGFloat)reCols * orginHeight) / orginWidth;
    cv::Size reSize = cv::Size(reCols, reRows);
    resize(mat, mat, reSize);
    
    return mat;
}

@end