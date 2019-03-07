//
// MLSpinner.m
// MLUI
//
// Created by Julieta Puente on 18/4/16.
// Copyright © 2016 MercadoLibre. All rights reserved.
//

#import "MLSpinner.h"
#import "MLStyleSheetManager.h"
#import "UIFont+MLFonts.h"
#import "MLUIBundle.h"

/**
   This enum enumerates posible changes on spinner states, this enum
   reduce BOOL properties on this class

   - MLSpinnerStateNone: Dont change spinner state
   - MLSpinnerStateHide: Hide spinner
   - MLSpinnerStateShow: Show spinner
 */
typedef NS_ENUM (NSUInteger, MLSpinnerState) {
	MLSpinnerStateNone,
	MLSpinnerStateHide,
	MLSpinnerStateShow,
};

@interface MLSpinner ()

@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic) CGFloat diameter;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *endColor;
@property (nonatomic, strong) UIColor *startColor;
@property (nonatomic, copy) NSString *spinnerText;
@property (nonatomic) BOOL allowsText;
@property (nonatomic, strong) UIView *view;
@property (weak, nonatomic) IBOutlet UIView *spinnerView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spinnerLabelVerticalSpacing;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spinnerWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spinnerHeightConstraint;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isHidden;

// Indicates if exist a pending state to apply
@property (nonatomic) MLSpinnerState pendingStateChange;

@end

@implementation MLSpinner

static const CGFloat kMLSpinnerStrokeAnimationDuration = 0.75;
static const CGFloat kMLSpinnerColorAnimationDuration = 0.1;
static const CGFloat kMLSpinnerStrokeStartBegin = 0.5;
static const CGFloat kMLSpinnerCycleAnimationDuration = kMLSpinnerStrokeAnimationDuration + kMLSpinnerStrokeStartBegin;
static const CGFloat kMLSpinnerRotationDuration = 2.0;
static const CGFloat kMLSpinnerLabelVerticalSpacing = 32;
static const CGFloat kMLSpinnerSmallDiameter = 20;
static const CGFloat kMLSpinnerBigDiameter = 60;
static const CGFloat kMLSpinnerSmallLineWidth = 2;
static const CGFloat kMLSpinnerBigLineWidth = 3;
static const CGFloat kMLSpinnerAppearenceAnimationDuration = 0.3;

- (id)init
{
	if (self = [self initWithConfig:[self setUpConfigFromStyle:MLSpinnerStyleBlueBig] text:nil]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.pendingStateChange = MLSpinnerStateNone;
	}
	return self;
}

- (id)initWithStyle:(MLSpinnerStyle)style
{
	if (self = [self initWithConfig:[self setUpConfigFromStyle:style] text:nil]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.pendingStateChange = MLSpinnerStateNone;
	}
	return self;
}

- (id)initWithStyle:(MLSpinnerStyle)style text:(NSString *)text
{
	if (self = [self initWithConfig:[self setUpConfigFromStyle:style] text:text]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.pendingStateChange = MLSpinnerStateNone;
	}
	return self;
}

- (id)initWithConfig:(nonnull MLSpinnerConfig *)config text:(NSString *)text
{
	if (self = [super init]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.pendingStateChange = MLSpinnerStateNone;
		self.spinnerText = text;
		[self setUpView];
		[self setUpSpinnerWithConfig:config];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.pendingStateChange = MLSpinnerStateNone;
		[self setUpView];
		// By default the stayle blue big
		MLSpinnerConfig *config = [self setUpConfigFromStyle:MLSpinnerStyleBlueBig];
		[self setUpSpinnerWithConfig:config];
	}
	return self;
}

- (void)loadView
{
	UIView *view = [[MLUIBundle mluiBundle] loadNibNamed:NSStringFromClass([MLSpinner class])
	                                               owner:self
	                                             options:nil].firstObject;
	self.view = view;

	view.translatesAutoresizingMaskIntoConstraints = NO;
	view.backgroundColor = [UIColor clearColor];

	[self addSubview:view];

	NSDictionary *views = @{@"view" : view};
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
	                                                             options:0
	                                                             metrics:nil
	                                                               views:views]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
	                                                             options:0
	                                                             metrics:nil
	                                                               views:views]];
}

- (void)setUpView
{
	// get view from xib
	[self loadView];

	// set view to default values
	self.containerView.backgroundColor = [UIColor clearColor];
	self.backgroundColor = [UIColor clearColor];
	self.label.backgroundColor = [UIColor clearColor];
	self.label.text = nil;
	self.label.font = [UIFont ml_regularSystemFontOfSize:kMLFontsSizeMedium];
	self.label.textColor = MLStyleSheetManager.styleSheet.darkGreyColor;
	self.spinnerView.backgroundColor = [UIColor clearColor];
	self.view.alpha = 0;
	self.isHidden = YES;

	// create spinner layer
	self.circleLayer = [CAShapeLayer layer];
	[self.spinnerView.layer addSublayer:self.circleLayer];
}

- (MLSpinnerConfig *)setUpConfigFromStyle:(MLSpinnerStyle)style
{
	MLSpinnerConfig *config;
	switch (style) {
		case MLSpinnerStyleBlueBig: {
			config = [[MLSpinnerConfig alloc] initWithSize:MLSpinnerSizeBig primaryColor:MLStyleSheetManager.styleSheet.primaryColor secondaryColor:MLStyleSheetManager.styleSheet.secondaryColor];
			break;
		}

		case MLSpinnerStyleWhiteBig: {
			config = [[MLSpinnerConfig alloc] initWithSize:MLSpinnerSizeBig primaryColor:MLStyleSheetManager.styleSheet.whiteColor
			                                secondaryColor :MLStyleSheetManager.styleSheet.secondaryColor];
			break;
		}

		case MLSpinnerStyleBlueSmall: {
			config = [[MLSpinnerConfig alloc] initWithSize:MLSpinnerSizeSmall primaryColor:MLStyleSheetManager.styleSheet.secondaryColor secondaryColor:MLStyleSheetManager.styleSheet.secondaryColor];
			break;
		}

		case MLSpinnerStyleWhiteSmall: {
			config = [[MLSpinnerConfig alloc] initWithSize:MLSpinnerSizeSmall primaryColor:MLStyleSheetManager.styleSheet.whiteColor secondaryColor:MLStyleSheetManager.styleSheet.whiteColor];
			break;
		}

		default: {
			break;
		}
	}
	return config;
}

- (void)setUpSpinnerWithConfig:(MLSpinnerConfig *)config
{
	self.endColor = config.secondaryColor;
	self.startColor = config.primaryColor;
	self.allowsText = config.spinnerSize == MLSpinnerSizeBig ? YES : NO;
	self.diameter = config.spinnerSize == MLSpinnerSizeBig ? kMLSpinnerBigDiameter : kMLSpinnerSmallDiameter;
	self.spinnerWidthConstraint.constant = config.spinnerSize == MLSpinnerSizeBig ? kMLSpinnerBigDiameter : kMLSpinnerSmallDiameter;
	self.spinnerHeightConstraint.constant = config.spinnerSize == MLSpinnerSizeBig ? kMLSpinnerBigDiameter : kMLSpinnerSmallDiameter;
	self.lineWidth = config.spinnerSize == MLSpinnerSizeBig ? kMLSpinnerBigLineWidth : kMLSpinnerSmallLineWidth;

	if (self.spinnerView) {
		// If we don't use performSelector, the spinner animation is not visible when the controller is presented
		[self performSelector:@selector(setUpLayer) withObject:nil afterDelay:0];
		[self performSelector:@selector(setUpLabel) withObject:nil afterDelay:0];
	}
}

- (void)setUpLayer
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	// Set circle layer bounds
	self.circleLayer.bounds = CGRectMake(0, 0, self.diameter, self.diameter);
	CGSize size = [self.spinnerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	self.circleLayer.position = CGPointMake(size.width / 2, size.height / 2);

	// Set circle layer path
	UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.circleLayer.bounds];
	self.circleLayer.path = circle.CGPath;

	self.circleLayer.fillColor = [UIColor clearColor].CGColor;
	self.circleLayer.lineWidth = self.lineWidth;

	[CATransaction commit];

	// Stroke animation
	CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
	strokeEndAnimation.duration = kMLSpinnerStrokeAnimationDuration;
	strokeEndAnimation.beginTime = 0;
	strokeEndAnimation.fromValue = @0;
	strokeEndAnimation.toValue = @1;

	CABasicAnimation *strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
	strokeStartAnimation.duration = kMLSpinnerStrokeAnimationDuration;
	strokeStartAnimation.beginTime = kMLSpinnerStrokeStartBegin;
	strokeStartAnimation.fromValue = @0;
	strokeStartAnimation.toValue = @1;

	CAAnimationGroup *strokeAnimationGroup = [CAAnimationGroup animation];
	strokeAnimationGroup.duration = kMLSpinnerCycleAnimationDuration;
	strokeAnimationGroup.repeatCount = INFINITY;
	[strokeAnimationGroup setAnimations:[NSArray arrayWithObjects:strokeEndAnimation, strokeStartAnimation, nil]];

	// Color animation
	CABasicAnimation *colorEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
	colorEndAnimation.duration = kMLSpinnerColorAnimationDuration;
	colorEndAnimation.beginTime = 0;
	colorEndAnimation.toValue = (id)self.endColor.CGColor;
	colorEndAnimation.fillMode = kCAFillModeForwards;
	colorEndAnimation.timeOffset = 0;

	CABasicAnimation *colorStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
	colorStartAnimation.duration = kMLSpinnerColorAnimationDuration;
	colorStartAnimation.beginTime = kMLSpinnerCycleAnimationDuration;
	colorStartAnimation.toValue = (id)self.startColor.CGColor;
	colorStartAnimation.fillMode = kCAFillModeForwards;
	colorStartAnimation.timeOffset = 0;

	CAAnimationGroup *colorAnimationGroup = [CAAnimationGroup animation];
	colorAnimationGroup.duration = kMLSpinnerCycleAnimationDuration * 2;
	colorAnimationGroup.repeatCount = INFINITY;
	[colorAnimationGroup setAnimations:[NSArray arrayWithObjects:colorEndAnimation, colorStartAnimation, nil]];

	// Rotation animation
	CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotateAnimation.duration = kMLSpinnerRotationDuration;
	rotateAnimation.fromValue = @0;
	rotateAnimation.toValue = [NSNumber numberWithDouble:2 * M_PI];
	rotateAnimation.repeatCount = INFINITY;
	rotateAnimation.fillMode = kCAFillModeForwards;
	rotateAnimation.additive = YES;

	colorAnimationGroup.removedOnCompletion = NO;
	strokeAnimationGroup.removedOnCompletion = NO;
	rotateAnimation.removedOnCompletion = NO;

	[self.circleLayer addAnimation:strokeAnimationGroup forKey:@"animateStroke"];
	[self.circleLayer addAnimation:colorAnimationGroup forKey:@"animateColor"];
	[self.circleLayer addAnimation:rotateAnimation forKey:@"animateRotation"];
}

- (void)setUpLabel
{
	if (self.allowsText && self.spinnerText) {
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.lineSpacing = 5;
		paragraphStyle.alignment = NSTextAlignmentCenter;

		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.spinnerText];
		[attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, self.spinnerText.length)];

		self.label.attributedText = attributedString;
		self.spinnerLabelVerticalSpacing.constant = kMLSpinnerLabelVerticalSpacing;
	} else {
		self.spinnerLabelVerticalSpacing.constant = 0;
		self.label.text = @"";
	}
}

- (void)setText:(NSString *)spinnerText
{
	_spinnerText = spinnerText;
	[self setUpLabel];
}

- (void)setStyle:(MLSpinnerStyle)style
{
	[self setUpSpinnerWithConfig:[self setUpConfigFromStyle:style]];
}

- (void)showOrHideSpinnerIfNeeded
{
	switch (self.pendingStateChange) {
		case MLSpinnerStateHide: {
			[self hideSpinner];
			break;
		}

		case MLSpinnerStateShow: {
			[self showSpinner];
			break;
		}

		default: {
			break;
		}
	}
}

- (void)showSpinner
{
	// if already in the requested state, and no next change state scheduled
	if (!self.isHidden && self.pendingStateChange == MLSpinnerStateNone) {
		return;
	}

	// if changing state, schedule nextState to show
	if (self.isAnimating) {
		self.pendingStateChange = MLSpinnerStateShow;
		return;
	}

	// Change state to show
	self.pendingStateChange = MLSpinnerStateNone;
	self.isHidden = NO;
	self.view.alpha = 0;
	self.isAnimating = YES;
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:kMLSpinnerAppearenceAnimationDuration animations: ^{
	    weakSelf.view.alpha = 1;
	} completion: ^(BOOL finished) {
	    weakSelf.isAnimating = NO;
	    [weakSelf showOrHideSpinnerIfNeeded];
	}];
}

- (void)hideSpinner
{
	// if already in the requested state, and no next change state scheduled
	if (self.isHidden && self.pendingStateChange == MLSpinnerStateNone) {
		return;
	}

	// if changing state, schedule nextState to show
	if (self.isAnimating) {
		self.pendingStateChange = MLSpinnerStateHide;
		return;
	}

	// Change state to show
	self.pendingStateChange = MLSpinnerStateNone;
	self.isHidden = YES;
	self.isAnimating = YES;

	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:kMLSpinnerAppearenceAnimationDuration animations: ^{
	    weakSelf.view.alpha = 0;
	} completion: ^(BOOL finished) {
	    weakSelf.isAnimating = NO;
	    [weakSelf showOrHideSpinnerIfNeeded];
	}];
}

@end
