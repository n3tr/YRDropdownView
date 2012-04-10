//
//  YRDropdownView.m
//  YRDropdownViewExample
//
//  Created by Eli Perkins on 1/27/12.
//  Copyright (c) 2012 One Mighty Roar. All rights reserved.
//

#import "YRDropdownView.h"
#import <QuartzCore/QuartzCore.h>

@interface UILabel (YRDropdownView)
- (void)sizeToFitFixedWidth:(CGFloat)fixedWidth;
@end

@interface YRDropdownView ()
@property (nonatomic, unsafe_unretained) UIView * parentView;
@property (nonatomic, assign) float hideAfter;
@end

@implementation UILabel (YRDropdownView)


- (void)sizeToFitFixedWidth:(CGFloat)fixedWidth
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, fixedWidth, 0);
    self.lineBreakMode = UILineBreakModeWordWrap;
    self.numberOfLines = 0;
    [self sizeToFit];
}
@end

@interface YRDropdownView ()
- (void)updateTitleLabel:(NSString *)newText;
- (void)updateDetailLabel:(NSString *)newText;
- (void)hideUsingAnimation:(NSNumber *)animated;
- (void)done;
@end


@implementation YRDropdownView
@synthesize titleText;
@synthesize detailText;
@synthesize minHeight;
@synthesize accessoryImage;
@synthesize onTouch;
@synthesize shouldAnimate, hideAfter, parentView;
@synthesize backgroundColors, backgroundColorPositions;

//Using this prevents two alerts to ever appear on the screen at the same time
static YRDropdownView *currentDropdown = nil;
static NSMutableArray *yrQueue = nil; // for queueing - danielgindi@gmail.com
static BOOL isRtl = NO; // keep rtl property here - danielgindi@gmail.com

+ (YRDropdownView *)currentDropdownView
{
    return currentDropdown;
}

#pragma mark - Accessors

- (NSString *)titleText
{
    return titleText;
}

- (void)setTitleText:(NSString *)newText
{
    if ([NSThread isMainThread]) {
		[self updateTitleLabel:newText];
		[self setNeedsLayout];
		[self setNeedsDisplay];
	} else {
		[self performSelectorOnMainThread:@selector(updateTitleLabel:) withObject:newText waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
	}
}

- (NSString *)detailText
{
    return detailText;
}

- (void)setDetailText:(NSString *)newText
{
    if ([NSThread isMainThread]) {
        [self updateDetailLabel:newText];
        [self setNeedsLayout];
        [self setNeedsDisplay];
    } else {
        [self performSelectorOnMainThread:@selector(updateDetailLabel:) withObject:newText waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
    }
}

- (void)updateTitleLabel:(NSString *)newText {
    if (titleText != newText) {
        titleText = [newText copy];
        titleLabel.text = titleText;
    }
}

- (void)updateDetailLabel:(NSString *)newText {
    if (detailText != newText) {
        detailText = [newText copy];
        detailLabel.text = detailText;
    }
}



#pragma mark - Initializers
- (id)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clearsContextBeforeDrawing = NO;
        self.titleText = nil;
        self.detailText = nil;
        self.minHeight = 44.0f;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        detailLabel = [[UILabel alloc] initWithFrame:self.bounds];
        if (isRtl)
        {
            titleLabel.textAlignment = detailLabel.textAlignment = UITextAlignmentRight;
        }
        
        self.backgroundColors = [NSMutableArray arrayWithObjects:[UIColor colorWithRed:0.969 green:0.859 blue:0.475 alpha:1.000], [UIColor colorWithRed:0.937 green:0.788 blue:0.275 alpha:1.000], nil];
        self.backgroundColorPositions = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:1.0f], nil];
        
        // Gentle shadow settings. Path will be set up live, in [layoutSubviews] - danielgindi@gmail.com
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowRadius = 1.0f;
        self.layer.shadowColor = [UIColor colorWithWhite:0.450 alpha:1.000].CGColor;
        self.layer.shadowOpacity = 1.0f;
        
        accessoryImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        
        self.opaque = YES;
        
        onTouch = @selector(hide:);
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Routine to draw the gradient background - danielgindi@gmail.com
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Clear everything
    CGContextClearRect(context, rect);
    
    float * gradientLocations = malloc(sizeof(float)*self.backgroundColors.count);
    
    NSNumber * n;
    NSMutableArray * gradientColors = [NSMutableArray array];
    for (NSUInteger j=0,len = self.backgroundColors.count; j<len; j++)
    {
        [gradientColors addObject:(id)(((UIColor*)[self.backgroundColors objectAtIndex:j]).CGColor)];
        n = [self.backgroundColorPositions objectAtIndex:j];
        if (n) gradientLocations[j] = [n floatValue];
        else gradientLocations[j] = j==0?0.0f:1.0f;
    }
    
    
    // RGB color space. Free this later.
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    
    // create gradient
    CGGradientRef gradient = CGGradientCreateWithColors(rgb, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, rect);
    CGContextDrawLinearGradient(context, 
                                gradient, 
                                CGPointMake(0, rect.origin.y), 
                                CGPointMake(0, rect.origin.y + rect.size.height), 
                                kCGGradientDrawsBeforeStartLocation);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgb);
    
    free(gradientLocations);
    
    [super drawRect:rect]; // I do not know if previous iOS versions depend on that for drawing subviews, or they do it on the CALayer level anyways.
}

#pragma mark - Defines

#define HORIZONTAL_PADDING 15.0f
#define VERTICAL_PADDING 19.0f
#define IMAGE_PADDING 45.0f
#define TITLE_FONT_SIZE 19.0f
#define DETAIL_FONT_SIZE 13.0f
#define ANIMATION_DURATION 0.3f

#pragma mark - Class methods
#pragma mark View Methods
+ (YRDropdownView *)showDropdownInView:(UIView *)view title:(NSString *)title
{
    return [YRDropdownView showDropdownInView:view title:title detail:nil];
}

+ (YRDropdownView *)showDropdownInView:(UIView *)view title:(NSString *)title detail:(NSString *)detail
{
    return [YRDropdownView showDropdownInView:view title:title detail:detail image:nil animated:YES];
}

+ (YRDropdownView *)showDropdownInView:(UIView *)view title:(NSString *)title detail:(NSString *)detail animated:(BOOL)animated
{
    return [YRDropdownView showDropdownInView:view title:title detail:detail image:nil animated:animated hideAfter:0.0];
}

+ (YRDropdownView *)showDropdownInView:(UIView *)view title:(NSString *)title detail:(NSString *)detail image:(UIImage *)image animated:(BOOL)animated
{
    return [YRDropdownView showDropdownInView:view title:title detail:detail image:image animated:animated hideAfter:0.0];
}

+ (YRDropdownView *)showDropdownInView:(UIView *)view 
                             title:(NSString *)title 
                            detail:(NSString *)detail 
                             image:(UIImage *)image
                          animated:(BOOL)animated
                         hideAfter:(float)hideAfter
{
    YRDropdownView *dropdown = [[YRDropdownView alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, 44)];
    if (currentDropdown) // add to queue - danielgindi@gmail.com
    {
        if (!yrQueue) yrQueue = [NSMutableArray array];
        [yrQueue addObject:dropdown];
    }
    else 
    {
        currentDropdown = dropdown;
    }
    dropdown.titleText = title;

    if (detail) {
        dropdown.detailText = detail;
    } 

    if (image) {
        dropdown.accessoryImage = image;
    }
    
    dropdown.shouldAnimate = animated;
    dropdown.parentView = view;
    dropdown.hideAfter = hideAfter;
    
    if ([view isKindOfClass:[UIWindow class]]) {
        CGRect dropdownFrame = dropdown.frame;
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        dropdownFrame.origin.y = appFrame.origin.y;
        dropdown.frame = dropdownFrame;
    }

    if (currentDropdown == dropdown)
    {
        [dropdown.parentView addSubview:dropdown];
        [dropdown show:animated];
        if (dropdown.hideAfter != 0.0) {
            [dropdown performSelector:@selector(hideUsingAnimation:) withObject:[NSNumber numberWithBool:dropdown.shouldAnimate] afterDelay:dropdown.hideAfter+ANIMATION_DURATION];
        }
    }

    return dropdown;
}

+ (void)removeView 
{
    if (!currentDropdown) {
        return;
    }
    
    [currentDropdown removeFromSuperview];
    
    currentDropdown = nil;
    
    if (yrQueue.count) // no need for nil check
    {
        currentDropdown = [yrQueue objectAtIndex:0];
        [yrQueue removeObjectAtIndex:0];
        [currentDropdown.parentView addSubview:currentDropdown];
        [currentDropdown show:currentDropdown.shouldAnimate];
        if (currentDropdown.hideAfter != 0.0) 
        {
            [currentDropdown performSelector:@selector(hideUsingAnimation:) withObject:[NSNumber numberWithBool:currentDropdown.shouldAnimate] afterDelay:currentDropdown.hideAfter+ANIMATION_DURATION];
        }
    }
}

+ (BOOL)hideDropdownInView:(UIView *)view
{
    return [YRDropdownView hideDropdownInView:view animated:YES];
}

+ (BOOL)hideDropdownInView:(UIView *)view animated:(BOOL)animated
{
    if (currentDropdown) {
        [currentDropdown hideUsingAnimation:[NSNumber numberWithBool:animated]];
        return YES;
    }
    
    UIView *viewToRemove = nil;
    for (UIView *v in [view subviews]) {
        if ([v isKindOfClass:[YRDropdownView class]]) {
            viewToRemove = v;
        }
    }
    if (viewToRemove != nil) {
        YRDropdownView *dropdown = (YRDropdownView *)viewToRemove;
        [dropdown hideUsingAnimation:[NSNumber numberWithBool:animated]];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - Methods

- (void)show:(BOOL)animated
{
    if(animated)
    {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y-self.frame.size.height, self.frame.size.width, self.frame.size.height);
        self.alpha = 0.02;
        [UIView animateWithDuration:ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.alpha = 1.0;
                             self.frame = CGRectMake(self.frame.origin.x, 
                                                     self.frame.origin.y+self.frame.size.height,
                                                     self.frame.size.width, self.frame.size.height);
                         }
                         completion:^(BOOL finished) {
                             if (finished)
                             {
                                 
                             }
                         }];

    }
}

- (void)hide:(BOOL)animated
{
    [self done];
}

- (void)hideUsingAnimation:(NSNumber *)animated {
    if ([animated boolValue]) {
        [UIView animateWithDuration:ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.alpha = 0.02;
                             self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y-self.frame.size.height, self.frame.size.width, self.frame.size.height);
                         }
                         completion:^(BOOL finished) {
                             if (finished)
                             {
                                 [self done];
                             }
                         }];        
    }
    else {
        self.alpha = 0.0f;
        [self done];
    }
}

- (void)done
{
    [self removeFromSuperview];
    currentDropdown = nil;
    if (yrQueue.count) // no need for nil check
    {
        currentDropdown = [yrQueue objectAtIndex:0];
        [yrQueue removeObjectAtIndex:0];
        [currentDropdown.parentView addSubview:currentDropdown];
        [currentDropdown show:currentDropdown.shouldAnimate];
        if (currentDropdown.hideAfter != 0.0) 
        {
            [currentDropdown performSelector:@selector(hideUsingAnimation:) withObject:[NSNumber numberWithBool:currentDropdown.shouldAnimate] afterDelay:currentDropdown.hideAfter+ANIMATION_DURATION];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideUsingAnimation:[NSNumber numberWithBool:self.shouldAnimate]];
}

#pragma mark - Layout

- (void)layoutSubviews 
{
    // Set label properties
    titleLabel.font = [UIFont boldSystemFontOfSize:TITLE_FONT_SIZE];
    titleLabel.adjustsFontSizeToFitWidth = NO;
    titleLabel.opaque = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor colorWithWhite:0.225 alpha:1.0];
    titleLabel.shadowOffset = CGSizeMake(0, 1); // CALayer already translates pixel size
    titleLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    titleLabel.text = self.titleText;
    [titleLabel sizeToFitFixedWidth:self.bounds.size.width - (2 * HORIZONTAL_PADDING)];

    titleLabel.frame = CGRectMake(self.bounds.origin.x + HORIZONTAL_PADDING, 
                                  self.bounds.origin.y + VERTICAL_PADDING - 8, 
                                  self.bounds.size.width - (2 * HORIZONTAL_PADDING), 
                                  titleLabel.frame.size.height);
    
    [self addSubview:titleLabel];
    
    if (self.detailText) {
        detailLabel.font = [UIFont systemFontOfSize:DETAIL_FONT_SIZE];
        detailLabel.numberOfLines = 0;
        detailLabel.adjustsFontSizeToFitWidth = NO;
        detailLabel.opaque = NO;
        detailLabel.backgroundColor = [UIColor clearColor];
        detailLabel.textColor = [UIColor colorWithWhite:0.225 alpha:1.0];
        detailLabel.shadowOffset = CGSizeMake(0, 1);
        detailLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
        detailLabel.text = self.detailText;
        [detailLabel sizeToFitFixedWidth:self.bounds.size.width - (2 * HORIZONTAL_PADDING)];
        
        detailLabel.frame = CGRectMake(self.bounds.origin.x + HORIZONTAL_PADDING, 
                                       titleLabel.frame.origin.y + titleLabel.frame.size.height + 2, 
                                       self.bounds.size.width - (2 * HORIZONTAL_PADDING), 
                                       detailLabel.frame.size.height);

        [self addSubview:detailLabel];
    } else {
        CGRect rc = CGRectMake(titleLabel.frame.origin.x,
                        9,
                        titleLabel.frame.size.width, 
                        titleLabel.frame.size.height);
        if (isRtl) 
        {
            rc.origin.x = self.frame.size.width - rc.origin.x - rc.size.width;
        }
        titleLabel.frame = rc;
    }
    
    if (self.accessoryImage) {
        accessoryImageView.image = self.accessoryImage;
        CGRect rc = CGRectMake(self.bounds.origin.x + HORIZONTAL_PADDING, 
                        self.bounds.origin.y + VERTICAL_PADDING,
                        self.accessoryImage.size.width,
                        self.accessoryImage.size.height);
        if (isRtl) 
        {
            rc.origin.x = self.bounds.origin.x + self.bounds.size.width - HORIZONTAL_PADDING - rc.size.width;
        }
        accessoryImageView.frame = rc;
        
        [titleLabel sizeToFitFixedWidth:self.bounds.size.width - IMAGE_PADDING - (HORIZONTAL_PADDING * 2)];
        rc = CGRectMake(titleLabel.frame.origin.x + IMAGE_PADDING, 
                        titleLabel.frame.origin.y, 
                        titleLabel.frame.size.width, 
                        titleLabel.frame.size.height);
        if (isRtl) 
        {
            rc.origin.x =  self.frame.size.width - rc.origin.x - rc.size.width;
        }
        titleLabel.frame = rc;
        
        if (self.detailText) {
            [detailLabel sizeToFitFixedWidth:self.bounds.size.width - IMAGE_PADDING - (HORIZONTAL_PADDING * 2)];
            rc = CGRectMake(detailLabel.frame.origin.x + IMAGE_PADDING, 
                            detailLabel.frame.origin.y, 
                            detailLabel.frame.size.width, 
                            detailLabel.frame.size.height);
            if (isRtl) 
            {
                rc.origin.x =  self.frame.size.width - rc.origin.x - rc.size.width;
            }
            detailLabel.frame = rc;
        }
        
        [self addSubview:accessoryImageView];
    }
    
    CGFloat dropdownHeight = 44.0f;
    if (self.detailText) {
        dropdownHeight = MAX(CGRectGetMaxY(self.bounds), CGRectGetMaxY(detailLabel.frame));
        dropdownHeight += VERTICAL_PADDING;
    } 
            
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, dropdownHeight)];
}

#pragma mark - rtl

+ (void)setRtl:(BOOL)rtl;
{
    isRtl = rtl;
}

@end


