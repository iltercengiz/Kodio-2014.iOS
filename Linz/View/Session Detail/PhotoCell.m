//
//  PhotoCell.m
//  Linz
//
//  Created by Ilter Cengiz on 12/02/14.
//  Copyright (c) 2014 Ilter Cengiz. All rights reserved.
//

#pragma mark Model
#import "Photo.h"

#pragma mark View
#import "PhotoCell.h"

@interface PhotoCell ()

@property (nonatomic) UIView *selectedOverlay;

@end

@implementation PhotoCell

#pragma mark - Configurator
- (void)configureCellForPhoto:(Photo *)photoEntity {
    
    // Get photo from disk
    NSInteger sessionIdentifier = photoEntity.sessionIdentifier.integerValue;
    NSInteger photoIdentifier = photoEntity.identifier.integerValue;
    
    NSString *photoPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Photo-%li-%li", (long)sessionIdentifier, (long)photoIdentifier]];
    
    UIImage *photo = [UIImage imageWithContentsOfFile:photoPath];
    
    self.imageView.image = photo;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.marked = NO;
    
}

#pragma mark - PhotoCell
- (void)setMarked:(BOOL)marked {
    
    if (marked) {
        self.selectedOverlay = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedOverlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.32];
        
        UIImageView *tick = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tick"]];
        tick.backgroundColor = [UIColor colorWithRed:0.255 green:0.255 blue:0.259 alpha:1];
        tick.layer.cornerRadius = 12.0;
        tick.frame = CGRectOffset(tick.frame, 8.0, 8.0);
        
        [self.selectedOverlay addSubview:tick];
        
        [self addSubview:self.selectedOverlay];
    } else {
        [self.selectedOverlay removeFromSuperview];
        self.selectedOverlay = nil;
    }
    
    _marked = marked;
    
}

- (void)setup {
    
    // Set background color for custom drawing
    self.backgroundColor = [UIColor colorWithRed:0.153 green:0.153 blue:0.157 alpha:1];
    
    // Set frame
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 0.5;
    self.layer.cornerRadius = 12.0;
    
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
