//
//  Speaker.h
//  Linz
//
//  Created by Ilter Cengiz on 17/02/14.
//  Copyright (c) 2014 Ilter Cengiz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Speaker : NSManagedObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSString * detail;
@property (nonatomic, retain) NSString * github;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * twitter;

@end
