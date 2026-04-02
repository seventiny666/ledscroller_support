#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSArray *fontPaths = @[
            @"LedScroller/Fonts/MatrixSans-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansSC-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansRaster-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansRasterSC-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansSmooth-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansSmoothSC-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansVideo-Regular.ttf",
            @"LedScroller/Fonts/MatrixSansVideoSC-Regular.ttf"
        ];
        
        for (NSString *path in fontPaths) {
            NSURL *url = [NSURL fileURLWithPath:path];
            CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);
            if (dataProvider) {
                CGFontRef font = CGFontCreateWithDataProvider(dataProvider);
                if (font) {
                    CFStringRef postScriptName = CGFontCopyPostScriptName(font);
                    NSLog(@"%@: %@", [path lastPathComponent], (__bridge NSString *)postScriptName);
                    CFRelease(postScriptName);
                    CGFontRelease(font);
                }
                CGDataProviderRelease(dataProvider);
            }
        }
    }
    return 0;
}
