//
//  AXValueWrapper.m
//  Work-n-Play
//
//  Created by Volodymyr Sapsai on 7/14/12.
//  Copyright (c) 2012 Volodymyr Sapsai. All rights reserved.
//

#import "AXValueWrapper.h"

@interface AXValueWrapper()
+ (AXValueRef)createAXValueRefFromNSValue:(NSValue *)nsValue;

- (void)setAXValue:(AXValueRef)value;
@end

#pragma mark -

@implementation AXValueWrapper

@dynamic AXValue;

- (id)initWithAXValueRef:(AXValueRef)valueRef
{
	self = [super init];
	if (nil != self)
	{
		[self setAXValue:valueRef];
	}
	return self;
}

- (id)initWithNSValue:(NSValue *)value
{
	AXValueRef valueRef = [AXValueWrapper createAXValueRefFromNSValue:value];
	self = [self initWithAXValueRef:valueRef];
	if (NULL != valueRef)
	{
		CFRelease(valueRef);
	}
	return self;
}

+ (id)wrapperWithAXValueRef:(AXValueRef)valueRef
{
	return [[self alloc] initWithAXValueRef:valueRef];
}

+ (id)wrapperWithNSValue:(NSValue *)value
{
	return [[self alloc] initWithNSValue:value];
}

- (void)dealloc {
    [self setAXValue:NULL];
}

#pragma mark -

+ (AXValueRef)createAXValueRefFromNSValue:(NSValue *)nsValue
{
	AXValueRef result = NULL;
	if (nil != nsValue)
	{
		const char *valueType = [nsValue objCType];
		if (0 == strcmp(@encode(NSRange), valueType))
		{
			NSRange nsRange = [nsValue rangeValue];
			CFRange range = CFRangeMake(nsRange.location, nsRange.length);
			result = AXValueCreate(kAXValueCFRangeType, &range);
		}
		else if (0 == strcmp(@encode(NSRect), valueType))
		{
			NSRect nsRect = [nsValue rectValue];
			CGRect rect = NSRectToCGRect(nsRect);
			result = AXValueCreate(kAXValueCGRectType, &rect);
		}
		else if (0 == strcmp(@encode(NSPoint), valueType))
		{
			NSPoint nsPoint = [nsValue pointValue];
			CGPoint point = NSPointToCGPoint(nsPoint);
			result = AXValueCreate(kAXValueCGPointType, &point);
		}
		else if (0 == strcmp(@encode(NSSize), valueType))
		{
			NSSize nsSize = [nsValue sizeValue];
			CGSize size = NSSizeToCGSize(nsSize);
			result = AXValueCreate(kAXValueCGSizeType, &size);
		}
	}
	return result;
}

#pragma mark -

- (AXValueRef)AXValue
{
	return _value;
}

- (void)setAXValue:(AXValueRef)value
{
	if (_value != value)
	{
		if (NULL != _value)
		{
			CFRelease(_value);
		}
		_value = ((NULL != value) ? CFRetain(value) : NULL);
	}
}

- (NSValue *)value
{
	NSValue *result = nil;
	AXValueRef valueRef = self.AXValue;
	if (NULL != valueRef)
	{
		AXValueType valueType = AXValueGetType(valueRef);
		switch (valueType)
		{
			case kAXValueCFRangeType:
			{
				CFRange range;
				BOOL isSuccessfully = AXValueGetValue(valueRef, kAXValueCFRangeType, &range);
				NSAssert(isSuccessfully, @"Incorrectly determined AXValueRef type");
				NSAssert((range.location >= 0) && (range.length >= 0),
						 @"Don't know how to convert to NSRange CFRange with negative location or length");
				NSRange nsRange = NSMakeRange(range.location, range.length);
				result = [NSValue valueWithRange:nsRange];
				break;
			}
			case kAXValueCGRectType:
			{
				CGRect rect;
				BOOL isSuccessfully = AXValueGetValue(valueRef, kAXValueCGRectType, &rect);
				NSAssert(isSuccessfully, @"Incorrectly determined AXValueRef type");
				NSRect nsRect = NSRectFromCGRect(rect);
				result = [NSValue valueWithRect:nsRect];
				break;
			}
			case kAXValueCGPointType:
			{
				CGPoint point;
				BOOL isSuccessfully = AXValueGetValue(valueRef, kAXValueCGPointType, &point);
				NSAssert(isSuccessfully, @"Incorrectly determined AXValueRef type");
				NSPoint nsPoint = NSPointFromCGPoint(point);
				result = [NSValue valueWithPoint:nsPoint];
				break;
			}
			case kAXValueCGSizeType:
			{
				CGSize size;
				BOOL isSuccessfully = AXValueGetValue(valueRef, kAXValueCGSizeType, &size);
				NSAssert(isSuccessfully, @"Incorrectly determined AXValueRef type");
				NSSize nsSize = NSSizeFromCGSize(size);
				result = [NSValue valueWithSize:nsSize];
				break;
			}

			default:
				break;
		}
	}
	return result;
}

@end
