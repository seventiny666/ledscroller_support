#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 测试通过PostScript名称加载字体
        NSArray *fontNames = @[
            @"MatrixSans-Regular",
            @"MatrixSansRaster-Regular",
            @"MatrixSansSmooth-Regular",
            @"MatrixSansVideo-Regular",
            @"MatrixSansScreen-Regular"
        ];
        
        NSLog(@"测试通过PostScript名称加载字体:");
        for (NSString *fontName in fontNames) {
            UIFont *font = [UIFont fontWithName:fontName size:20];
            if (font) {
                NSLog(@"✅ %@ - 加载成功", fontName);
            } else {
                NSLog(@"❌ %@ - 加载失败", fontName);
                
                // 尝试通过Family Name加载
                NSString *familyName = [fontName stringByReplacingOccurrencesOfString:@"-Regular" withString:@""];
                familyName = [familyName stringByReplacingOccurrencesOfString:@"MatrixSans" withString:@"Matrix Sans "];
                familyName = [familyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                NSLog(@"  尝试Family Name: %@", familyName);
                NSArray *fontsInFamily = [UIFont fontNamesForFamilyName:familyName];
                if (fontsInFamily.count > 0) {
                    NSLog(@"  可用字体: %@", fontsInFamily);
                }
            }
        }
    }
    return 0;
}
