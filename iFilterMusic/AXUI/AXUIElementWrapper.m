//
//  AXUIElementWrapper.m
//  Work-n-Play
//
//  Created by Volodymyr Sapsai on 7/22/12.
//  Copyright (c) 2012 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXUIElementWrapper.h"
#import "AXValueWrapper.h"
#import "NSAttributedString+Accessibility.h"

@interface AXUIElementWrapper()
- (void)setUIElement:(AXUIElementRef)uiElement;
@end

#pragma mark -

@implementation AXUIElementWrapper

- (id)initWithUIElement:(AXUIElementRef)uiElement
{
	self = [super init];
	if (nil != self)
	{
		[self setUIElement:uiElement];
	}
	return self;
}

+ (id)wrapperWithUIElement:(AXUIElementRef)uiElement
{
	return [[self alloc] initWithUIElement:uiElement];
}

+ (id)wrapperForApplication:(pid_t)applicationPid
{
	AXUIElementWrapper *result = nil;
	AXUIElementRef applicationElement = AXUIElementCreateApplication(applicationPid);
	if (NULL != applicationElement)
	{
		result = [self wrapperWithUIElement:applicationElement];
		CFRelease(applicationElement);
	}
	return result;
}

- (void)dealloc
{
    [self setUIElement:NULL];
}

#pragma mark -

- (AXUIElementRef)UIElement
{
	return _UIElement;
}

- (void)setUIElement:(AXUIElementRef)uiElement
{
	if (_UIElement != uiElement)
	{
		if (NULL != _UIElement)
		{
			CFRelease(_UIElement);
		}
		_UIElement = ((NULL != uiElement) ? CFRetain(uiElement) : NULL);
	}
}

#pragma mark -
#pragma mark Attributes

- (NSArray *)attributeNames
{
	CFArrayRef result = nil;
	AXUIElementCopyAttributeNames(self.UIElement, &result);
    return (__bridge_transfer NSArray*)result;
}

- (id)attributeValue:(NSString *)attribute
{
	CFTypeRef result = nil;
	NSArray *attributeNames = [self attributeNames];
	if ([attributeNames containsObject:attribute]) {
		AXUIElementCopyAttributeValue(self.UIElement, (CFStringRef)attribute, &result);
	}
    return (__bridge_transfer id)result;
}

- (void)setAttribute:(NSString *)attribute toCFValue:(CFTypeRef)value {
    AXUIElementSetAttributeValue(self.UIElement, (CFStringRef)attribute, value);
}

- (void)setAttribute:(NSString *)attribute toValue:(id)value {
    AXUIElementSetAttributeValue(self.UIElement, (CFStringRef)attribute, (__bridge CFTypeRef)value);
}

- (id)elementValue
{
	return [self attributeValue:NSAccessibilityValueAttribute];
}

- (NSArray *)children
{
	NSMutableArray *result = nil;
	NSArray *rawChildren = [self attributeValue:NSAccessibilityChildrenAttribute];
	if ([rawChildren count] > 0)
	{
		result = [NSMutableArray arrayWithCapacity:[rawChildren count]];
		for (NSInteger i = 0; i < [rawChildren count]; i++)
		{
            AXUIElementRef element = (__bridge AXUIElementRef)[rawChildren objectAtIndex:i];
			AXUIElementWrapper *elementWrapper = [AXUIElementWrapper wrapperWithUIElement:element];
			[result addObject:elementWrapper];
		}
	}
	return [result copy];
}

- (NSString *)role
{
	return [self attributeValue:NSAccessibilityRoleAttribute];
}

- (NSValue *)visibleCharacterRange
{
    AXValueRef rangeRef = (__bridge AXValueRef)[self attributeValue:NSAccessibilityVisibleCharacterRangeAttribute];
	AXValueWrapper *rangeWrapper = [AXValueWrapper wrapperWithAXValueRef:rangeRef];
	return rangeWrapper.value;
}

- (NSValue *)position
{
    AXValueRef positionRef = (__bridge AXValueRef)[self attributeValue:NSAccessibilityPositionAttribute];
	AXValueWrapper *positionWrapper = [AXValueWrapper wrapperWithAXValueRef:positionRef];
	return positionWrapper.value;
}

- (NSValue *)size
{
    AXValueRef sizeRef = (__bridge AXValueRef)[self attributeValue:NSAccessibilitySizeAttribute];
	AXValueWrapper *sizeWrapper = [AXValueWrapper wrapperWithAXValueRef:sizeRef];
	return sizeWrapper.value;
}

#pragma mark -
#pragma mark Parameterized attributes

- (NSArray *)parameterizedAttributeNames
{
	CFArrayRef result = nil;
	AXUIElementCopyParameterizedAttributeNames(self.UIElement, &result);
    return (__bridge NSArray*)result;
}

// Type of parameter is CFTypeRef because parameter is usually not toll-free
// bridged.  For example, AXValueRef is not toll-free bridged with NSValue.
- (id)parameterizedAttributeValue:(NSString *)attribute forParameter:(CFTypeRef)parameter
{
	CFTypeRef result = nil;
	NSArray *attributeNames = [self parameterizedAttributeNames];
	if ([attributeNames containsObject:attribute])
	{
		AXUIElementCopyParameterizedAttributeValue(self.UIElement, (CFStringRef)attribute, parameter, &result);
	}
    return (__bridge_transfer id)result;
}

- (NSAttributedString *)attributedStringForRange:(NSRange)range
{
	AXValueWrapper *rangeWrapper = [AXValueWrapper wrapperWithNSValue:[NSValue valueWithRange:range]];
	NSAttributedString *attributedString = [self parameterizedAttributeValue:NSAccessibilityAttributedStringForRangeParameterizedAttribute forParameter:rangeWrapper.AXValue];
	return [attributedString attributedStringByUsingAppKitAttributes];
}

- (NSValue *)boundsForRange:(NSRange)range
{
	AXValueWrapper *rangeWrapper = [AXValueWrapper wrapperWithNSValue:[NSValue valueWithRange:range]];
    AXValueRef boundsRef = (__bridge AXValueRef)[self parameterizedAttributeValue:NSAccessibilityBoundsForRangeParameterizedAttribute forParameter:rangeWrapper.AXValue];
	AXValueWrapper *boundsWrapper = [AXValueWrapper wrapperWithAXValueRef:boundsRef];
	return boundsWrapper.value;
}

- (NSNumber *)lineForIndex:(NSInteger)index
{
	NSNumber *line = [self parameterizedAttributeValue:NSAccessibilityLineForIndexParameterizedAttribute forParameter:(CFNumberRef)[NSNumber numberWithInteger:index]];
	return line;
}

- (NSValue *)rangeForLine:(NSInteger)line
{
    AXValueRef rangeRef = (__bridge AXValueRef)[self parameterizedAttributeValue:NSAccessibilityRangeForLineParameterizedAttribute forParameter:(CFNumberRef)[NSNumber numberWithInteger:line]];
	AXValueWrapper *rangeWrapper = [AXValueWrapper wrapperWithAXValueRef:rangeRef];
	return rangeWrapper.value;
}

@end
