//
//  AXUIElementWrapper.h
//  Work-n-Play
//
//  Created by Volodymyr Sapsai on 7/22/12.
//  Copyright (c) 2012 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

// Wraps AXUIElementRef and provides object-oriented API for it.
@interface AXUIElementWrapper : NSObject
{
@private
	AXUIElementRef _UIElement;
}

@property (readonly, nonatomic) AXUIElementRef UIElement;

- (id)initWithUIElement:(AXUIElementRef)uiElement;
+ (id)wrapperWithUIElement:(AXUIElementRef)uiElement;
+ (id)wrapperForApplication:(pid_t)applicationPid;

// NSArray of NSString.
- (NSArray *)attributeNames;
// NSAccessibilityValueAttribute
- (id)elementValue;
// NSArray of AXUIElementWrapper.  NSAccessibilityChildrenAttribute
- (NSArray *)children;
// NSAccessibilityRoleAttribute
- (NSString *)role;
// NSRange value.  NSAccessibilityVisibleCharacterRangeAttribute
- (NSValue *)visibleCharacterRange;
// NSPoint value.  NSAccessibilityPositionAttribute
- (NSValue *)position;
// NSSize value.  NSAccessibilitySizeAttribute
- (NSValue *)size;

- (void)setAttribute:(NSString *)attribute toCFValue:(CFTypeRef)value;
- (void)setAttribute:(NSString *)attribute toValue:(id)value;
- (id)attributeValue:(NSString *)attribute;

// NSArray of NSString.
- (NSArray *)parameterizedAttributeNames;
// NSAccessibilityAttributedStringForRangeParameterizedAttribute
- (NSAttributedString *)attributedStringForRange:(NSRange)range;
// NSRect value. Rect is specified in screen coordinates.  NSAccessibilityBoundsForRangeParameterizedAttribute
- (NSValue *)boundsForRange:(NSRange)range;
// NSAccessibilityLineForIndexParameterizedAttribute
- (NSNumber *)lineForIndex:(NSInteger)index;
// NSRange value.  NSAccessibilityRangeForLineParameterizedAttribute
- (NSValue *)rangeForLine:(NSInteger)line;
@end
