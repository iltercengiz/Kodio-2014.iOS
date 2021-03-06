//
//  SponsorCell.h
//  Linz
//
//  Created by Ilter Cengiz on 12/02/14.
//  Copyright (c) 2014 Ilter Cengiz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sponsor;

@interface SponsorCell : UITableViewCell

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UIImageView *sponsorImage;

#pragma mark - Configurator
- (void)configureCellForSponsor:(Sponsor *)sponsor;

@end
