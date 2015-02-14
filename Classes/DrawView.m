//
//  DrawView.m
//  DrawView
//
//  Created by Frank Michael on 4/8/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "DrawView.h"
#import "UIBezierPath+Elements.h"

#define drawSpeed 80.0f

@interface DrawView () {
    UIBezierPath *bezierPath;
    CAShapeLayer *animateLayer;
    BOOL isAnimating;
    BOOL isDrawingExisting;
    UIBezierPath *signLine;
}
- (IBAction)undoDrawing:(id)sender;
@end

@implementation DrawView

#pragma mark - Init
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupUI];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI Configuration
- (void)setCanEdit:(BOOL)canEdit {
    _canEdit = canEdit;
    self.userInteractionEnabled = canEdit;
}

- (void)setupUI {
    // Array of all the paths the user will draw.
    bezierPath = [[UIBezierPath alloc] init];
    [bezierPath setLineCapStyle:kCGLineCapRound];
    [bezierPath setLineWidth:_strokeWidth];
    [bezierPath setMiterLimit:0];
    // Default colors for drawing.
    self.backgroundColor = [UIColor clearColor];
    _strokeColor = [UIColor blackColor];
    self.canEdit = YES;
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
}

#pragma mark - View Drawing
- (void)drawRect:(CGRect)rect {
    [bezierPath setLineCapStyle:kCGLineCapRound];
    [bezierPath setLineWidth:_strokeWidth];
    [bezierPath setMiterLimit:0];
    // Drawing code
    if (!isAnimating) {
        [_strokeColor setStroke];
        [bezierPath strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
    }
    
    if (_mode == SignatureMode) {
        [[UIColor lightGrayColor] setStroke];
        [signLine strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
    }
}

- (void)drawPath:(CGPathRef)path {
    isDrawingExisting = YES;
    BOOL previousCanEdit = _canEdit;
    self.canEdit = NO;
    bezierPath = [UIBezierPath new];
    bezierPath.CGPath = path;
    //    bezierPath.lineCapStyle = kCGLineCapRound;
    //    bezierPath.lineWidth = _strokeWidth;
    //    bezierPath.miterLimit = 0.0f;
    // If iPad apply the scale first so the paths bounds is in its final state.
    //    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
    //        [bezierPath setLineWidth:_strokeWidth];
    //        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(2, 2);
    //        [bezierPath applyTransform:scaleTransform];
    //    }
    // Center the drawing within the view.
    //    CGRect charBounds = bezierPath.bounds;
    //    CGFloat charX = CGRectGetMidX(charBounds);
    //    CGFloat charY = CGRectGetMidY(charBounds);
    //    CGRect cellBounds = self.bounds;
    //    CGFloat centerX = CGRectGetMidX(cellBounds);
    //    CGFloat centerY = CGRectGetMidY(cellBounds);
    
    //[bezierPath applyTransform:CGAffineTransformMakeTranslation(centerX - charX, centerY - charY)];
    
    [self setNeedsDisplay];
    
    // Debugging bounds view.
    if (_debugBox) {
        UIView *blockView = [[UIView alloc] initWithFrame:CGRectMake(bezierPath.bounds.origin.x, bezierPath.bounds.origin.y, bezierPath.bounds.size.width, bezierPath.bounds.size.height)];
        [blockView setBackgroundColor:[UIColor blackColor]];
        [blockView setAlpha:0.5];
        [self addSubview:blockView];
    }
    self.canEdit = previousCanEdit;
}

- (void)drawBezier:(UIBezierPath *)path {
    [self drawPath:path.CGPath];
}

- (IBAction)undoDrawing:(id)sender {
    //    [paths removeLastObject];
    bezierPath = [bezierPath bezierPathWithoutLastSubPath];
    [self setNeedsDisplay];
}

- (void)undo {
    BOOL previousEdit = _canEdit;
    self.canEdit = NO;
    [self undoDrawing:nil];
    self.canEdit = previousEdit;
}

- (void)setMode:(DrawingMode)mode {
    _mode = mode;
    if (mode == DrawingModeDefault) {
        signLine = nil;
    }
    else if (mode == SignatureMode) {
        signLine = [UIBezierPath new];
        signLine.lineCapStyle = kCGLineCapRound;
        signLine.lineWidth = 3.0f;
        // Draw the X for the line
        [signLine moveToPoint:CGPointMake(20, self.frame.size.height - 30)];
        [signLine addLineToPoint:CGPointMake(30, self.frame.size.height - 40)];
        [signLine moveToPoint:CGPointMake(30, self.frame.size.height - 30)];
        [signLine addLineToPoint:CGPointMake(20, self.frame.size.height - 40)];
        // Draw the line for signing on
        [signLine moveToPoint:CGPointMake(20, self.frame.size.height - 20)];
        [signLine addLineToPoint:CGPointMake(self.frame.size.width - 20, self.frame.size.height - 20)];
    }
    [self setNeedsDisplay];
}

- (void)refreshCurrentMode {
    [self setMode:_mode];
}

- (void)clearDrawing {
    bezierPath = nil;
    signLine = nil;
    [self setNeedsDisplay];
    [self setupUI];
}

#pragma mark - View Draw Reading
- (UIImage *)imageRepresentation {
    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

- (UIBezierPath *)bezierPathRepresentation {
    return bezierPath;
}

#pragma mark - Animation
- (void)animatePath {
    UIBezierPath *animatingPath = [UIBezierPath new];
    //    if (_canEdit) {
    
    animatingPath = bezierPath;
    
    // Clear out the existing view.
    isAnimating = YES;
    [self setNeedsDisplay];
    // Create shape layer that stores the path.
    animateLayer = [[CAShapeLayer alloc] init];
    animateLayer.fillColor = nil;
    animateLayer.path = animatingPath.CGPath;
    animateLayer.frame = self.frame;
    animateLayer.strokeColor = [_strokeColor CGColor];
    animateLayer.lineWidth = _strokeWidth;
    animateLayer.miterLimit = 0.0f;
    animateLayer.lineCap = @"round";
    // Create animation of path of the stroke end.
    
    CABasicAnimation *animation = [[CABasicAnimation alloc] init];
    animation.duration =  1.0f / drawSpeed * animatingPath.count;
    animation.fromValue = @(0.0f);
    animation.toValue = @(1.0f);
    animation.delegate = self;
    [animateLayer addAnimation:animation forKey:@"strokeEnd"];
    [self.layer addSublayer:animateLayer];
}

#pragma mark - Animation Delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    isAnimating = NO;
    [animateLayer removeFromSuperlayer];
    animateLayer = nil;
    [self setNeedsDisplay];
}

#pragma mark - Touch Detecting
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.canEdit) {
        [bezierPath setLineCapStyle:kCGLineCapRound];
        [bezierPath setLineWidth:_strokeWidth];
        [bezierPath setMiterLimit:0];
        
        UITouch *currentTouch = [[touches allObjects] objectAtIndex:0];
        [bezierPath moveToPoint:[currentTouch locationInView:self]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.canEdit) {
        UITouch *currentTouch = [[touches allObjects] objectAtIndex:0];
        [bezierPath moveToPoint:[currentTouch locationInView:self]];
        [bezierPath addLineToPoint:[currentTouch locationInView:self]];
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.canEdit) {
        UITouch *movedTouch = [[touches allObjects] objectAtIndex:0];
        [bezierPath addLineToPoint:[movedTouch locationInView:self]];
        [self setNeedsDisplay];
    }
}

@end
