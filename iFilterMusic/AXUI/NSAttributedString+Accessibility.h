//
//  NSAttributedString+Accessibility.h
//  Work-n-Play
//
//  Created by Volodymyr Sapsai on 7/14/12.
//  Copyright (c) 2012 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Accessibility)

// Receiver is accessibility attributed string, i.e. uses accessibility
// attribute names like NSAccessibilityFontTextAttribute.  Method returns
// attributed string where accessibility attributes are replaced with AppKit
// attributes.
- (NSAttributedString *)attributedStringByUsingAppKitAttributes;

@end
