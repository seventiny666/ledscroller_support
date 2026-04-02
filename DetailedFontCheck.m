#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

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
            NSArray *descriptors = (__bridge_transfer NSArray *)CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)url);
            
            if (descriptors && descriptors.count > 0) {
                CTFontDescriptorRef descriptor = (__bridge CTFontDescriptorRef)descriptors[0];
                
                // Get PostScript name
                CFStringRef psName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute);
                
                // Get family name
                CFStringRef familyName = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute);
                
                // Get full name
                CFStringRef fullName = CTFontDescriptorCopyAttribute(descriptor, kCTFontDisplayNameAttribute);
                
                NSLog(@"\n%@:", [path lastPathComponent]);
                NSLog(@"  PostScript Name: %@", psName ? (__bridge NSString *)psName : @"N/A");
                NSLog(@"  Family Name: %@", familyName ? (__bridge NSString *)familyName : @"N/A");
                NSLog(@"  Full Name: %@", fullName ? (__bridge NSString *)fullName : @"N/A");
                
                if (psName) CFRelease(psName);
                if (familyName) CFRelease(familyName);
                if (fullName) CFRelease(fullName);
            } else {
                NSLog(@"%@: Failed to load font", [path lastPathComponent]);
            }
        }
    }
    return 0;
}
