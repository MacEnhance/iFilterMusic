//
//  AXValueWrapper.h
//  Work-n-Play
//
//  Created by Volodymyr Sapsai on 7/14/12.
//  Copyright (c) 2012 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

// AXValueWrapper wraps AXValueRef and provides converting between AXValueRef
// and NSValue.
@interface AXValueWrapper : NSObject
{
@private
	AXValueRef _value;
}

// Returns wrapped AXValueRef.
@property (readonly, nonatomic) AXValueRef AXValue;
// Returns NSValue corresponding to wrapped AXValueRef.
@property (readonly, nonatomic) NSValue *value;

- (id)initWithAXValueRef:(AXValueRef)valueRef;
- (id)initWithNSValue:(NSValue *)value;

+ (id)wrapperWithAXValueRef:(AXValueRef)valueRef;
+ (id)wrapperWithNSValue:(NSValue *)value;

@end
