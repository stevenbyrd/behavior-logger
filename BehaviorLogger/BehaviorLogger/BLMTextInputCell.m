//
//  BLMTextInputCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMTextInputCell.h"
#import "BLMPaddedTextField.h"
#import "BLMViewUtils.h"
#import "BLMUtils.h"


@interface BLMTextInputCell () <UITextFieldDelegate>

@end


@implementation BLMTextInputCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _label = [[UILabel alloc] initWithFrame:CGRectZero];

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.label];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeRight lessThanOrEqualToItem:self.contentView attribute:NSLayoutAttributeRight constant:-30.0]];

    _textField = [[BLMPaddedTextField alloc] initWithHorizontalPadding:8.0 verticalPadding:6.0];

    self.textField.delegate = self;
    self.textField.minimumFontSize = 10.0;
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.borderStyle = UITextBorderStyleLine;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;

    [self.textField addTarget:self action:@selector(handleEditingChangedForTextField:) forControlEvents:UIControlEventEditingChanged];

    [self.contentView addSubview:self.textField];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeRight equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeLeft equalToItem:self.label attribute:NSLayoutAttributeRight constant:5.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeHeight greaterThanOrEqualToItem:self.label attribute:NSLayoutAttributeHeight constant:0.0]];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);

    [super layoutSubviews];
}


- (void)handleEditingChangedForTextField:(UITextField *)textField {
    assert([BLMUtils isObject:textField equalToObject:self.textField]);
    [self.delegate didChangeInputForTextInputCell:self];
    [self updateTextAttributes];
}


- (void)updateTextAttributes {
    NSDictionary *attributes = ([self.delegate shouldAcceptInputForTextInputCell:self] ? nil : [BLMTextInputCell errorAttributes]);

    if (![BLMUtils isDictionary:attributes equalToDictionary:self.textField.defaultTextAttributes]) {
        self.textField.defaultTextAttributes = attributes;
    }
}


- (void)updateContent {
    [super updateContent];

    self.label.text = [self.delegate labelForTextInputCell:self];
    self.textField.text = [self.delegate defaultInputForTextInputCell:self];
    self.textField.attributedPlaceholder = [self.delegate attributedPlaceholderForTextInputCell:self];

    [self updateTextAttributes];
}


+ (NSDictionary *)errorAttributes {
    static NSDictionary *errorAttributes;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        errorAttributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:BLMColorHexCodeRed alpha:1.0] };
    });

    return errorAttributes;
}

#pragma UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate shouldAcceptInputForTextInputCell:self]) {
        [self.delegate didAcceptInputForTextInputCell:self];
    } else {
        [self updateContent];
    }
}

@end