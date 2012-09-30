//
//  UIImage+SRImageProcess.m
//
//  Copyright (c) 2012 Sean Ridenour. All rights reserved.
//

#import "UIImage+SRImageProcess.h"
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CoreGraphics.h>

static void free_image_data_callback(void *info, const void *data, size_t size)
{
	free((void *)data);
}

@implementation UIImage (SRImageProcess)

#pragma mark - Class Methods

+ (UIImage *)imageWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	// Lock the base address of the pixel buffer
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
	size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
	
	uint8_t *imageData = malloc(bufferSize);
	memcpy(imageData, baseAddress, bufferSize);
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	// Create a Quartz direct-access data provider that uses the sample buffer image data
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageData, bufferSize, free_image_data_callback);
	
	CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace,
									   kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
									   dataProvider, NULL, true, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	
	UIImage *image = [[UIImage alloc] initWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
	CGImageRelease(cgImage);
	
	CGColorSpaceRelease(colorSpace);
	
	return image;
}

+ (UIImage *)image:(UIImage *)image scaledToSize:(CGSize)size scaleMode:(SRImageProcessScaleMode)scaleMode
{
    CGSize oldSize = image.size;
    CGFloat horizontalRatio = size.width / image.size.width;
    CGFloat verticalRatio = size.height / image.size.height;
    CGFloat ratio;
	
    switch (scaleMode) {
        case kSRImageProcessScaleAspectFill:
            ratio = fmax(horizontalRatio, verticalRatio);
            break;
        case kSRImageProcessScaleAspectFit:
            ratio = fmin(horizontalRatio, verticalRatio);
            break;
        case kSRImageProcessScaleToFill:
			ratio = 1.0;
    }
	
    CGSize newSize = CGSizeMake(oldSize.width * ratio, oldSize.height * ratio);
    CGRect drawRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	
    [image drawInRect:drawRect];
	
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
    return newImage;
}

@end
