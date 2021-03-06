//
//  Manager.m
//  Linz
//
//  Created by Ilter Cengiz on 16/02/14.
//  Copyright (c) 2014 Ilter Cengiz. All rights reserved.
//

#pragma mark Manager
#import "Manager.h"

#pragma mark Networking
#import "LinzAPIClient.h"

#pragma mark Model
#import "Sponsor.h"
#import "Session.h"
#import "Speaker.h"

#pragma mark Pods
#import <MagicalRecord/CoreData+MagicalRecord.h>

@interface Manager () <UIAlertViewDelegate>

@property NSMutableDictionary *localVersion;
@property NSMutableDictionary *localStatus;

@end

@implementation Manager

@synthesize speakers = _speakers;
@synthesize sessions = _sessions;
@synthesize sponsors = _sponsors;

#pragma mark - Singleton
+ (instancetype)sharedManager {
    static Manager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [Manager new];
    });
    return sharedManager;
}

#pragma mark - Getter
- (NSArray *)speakers {
    _speakers = [Speaker MR_findAllSortedBy:@"identifier" ascending:YES];
    return _speakers;
}
- (NSArray *)sessions {
    _sessions = [Session MR_findAllSortedBy:@"sortingIndex" ascending:YES];
    return _sessions;
}
- (NSArray *)sponsors {
    _sponsors = [[Sponsor MR_findAll] sortedArrayUsingDescriptors:@[
                                                                    [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                                                    [NSSortDescriptor sortDescriptorWithKey:@"subpriority" ascending:YES]
                                                                    ]];
    return _sponsors;
}

#pragma mark - Setter
- (void)setSpeakers:(NSArray *)speakers {
    _speakers = speakers;
}
- (void)setSessions:(NSArray *)sessions {
    _sessions = sessions;
}
- (void)setSponsors:(NSArray *)sponsors {
    _sponsors = sponsors;
}

#pragma mark - Setup
- (void)setupWithCompletion:(void (^)())completion {
    
    // Get the latest download version info
    self.localVersion = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"version"] mutableCopy];
    // If there isn't any version stored, create a version data with zeros
    if (!self.localVersion) {
        self.localVersion = [@{@"speakers": @0, @"sessions": @0, @"sponsors": @0} mutableCopy];
    }
    
    // Initiate localStatus
    if (!self.localStatus) {
        self.localStatus = [@{@"speakers": @NO, @"sessions": @NO, @"sponsors": @NO} mutableCopy];
    }
    
    // Error block
    // Will be used to terminate the app if there is an connection error and there's not any stored data
    void (^errorBlock)(NSError *error) = ^(NSError *error) {
        // NSLog(@"Error: %@", error.description);
        // Inform user that applciation will exit
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No connection", nil)
                                                        message:NSLocalizedString(@"Internet needed", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
    };
    
    // Completion block
    void (^completionBlock)(NSString *identifier, NSNumber *versionNumber, BOOL success) = ^(NSString *identifier, NSNumber *versionNumber, BOOL success) {
        
        // Get to main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // identifier is either @"speakers" or @"sessions" or @"sponsors"
            // Check success status
            if (success) {
                [self.localVersion setObject:versionNumber forKey:identifier]; // Update local version
                [self.localStatus setObject:@YES forKey:identifier]; // Update local status
            } else {
                // Check if there is any local data
                NSArray *array = [self valueForKey:identifier]; // This gets either speakers or sessions or sponsors
                if (array.count) {
                    [self.localStatus setObject:@YES forKey:identifier]; // Update local status
                } else {
                    errorBlock(nil);
                }
            }
            
            // Check if all statuses are O.K.
            if ([self.localStatus[@"speakers"] boolValue] &&
                [self.localStatus[@"sessions"] boolValue] &&
                [self.localStatus[@"sponsors"] boolValue])
            {
                
                // Call completion
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
                
                // Save the version data
                [[NSUserDefaults standardUserDefaults] setObject:self.localVersion forKey:@"version"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }
            
        });
        
    };
    
    // Fetch the latest version numbers
    [[LinzAPIClient sharedClient] GET:@"/version"
                           parameters:nil
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  [self setupSessionsWithRemoteVersion:responseObject completion:completionBlock];
                                  [self setupSponsorsWithRemoteVersion:responseObject completion:completionBlock];
                                  [self setupSpeakersWithRemoteVersion:responseObject completion:completionBlock];
                              } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  
                                  double speakers = [self.localVersion[@"speakers"] doubleValue];
                                  double sessions = [self.localVersion[@"sessions"] doubleValue];
                                  double sponsors = [self.localVersion[@"sponsors"] doubleValue];
                                  
                                  // Check the latest download version
                                  // And decide to proceed or terminate
                                  if (speakers >= 1.0 && sessions >= 1.0 && sponsors >= 1.0) {
                                      // proceedBlock(nil, YES, self.localVersion);
                                      completion();
                                  } else {
                                      errorBlock(error);
                                  }
                              }];
}

- (void)setupSpeakersWithRemoteVersion:(NSDictionary *)remoteVersion completion:(void (^)(NSString *identifier, NSNumber *versionNumber, BOOL success))completion {
    // Check version and download new data if needed
    if ([self.localVersion[@"speakers"] compare:remoteVersion[@"speakers"]] == NSOrderedAscending) {
        // Remove local data
        [Speaker MR_truncateAll];
        // Fetch all speakers
        [[LinzAPIClient sharedClient] GET:@"/speakers"
                               parameters:nil
                                  success:^(NSURLSessionDataTask *task, id responseObject) {
                                      // responseObject holds info for all speakers
                                      for (NSDictionary *speakerInfo in responseObject) {
                                          // Create a speaker entity
                                          Speaker *speaker = [Speaker MR_createInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
                                          speaker.name = speakerInfo[@"full_name"];
                                          speaker.title = speakerInfo[@"title"];
                                          speaker.detail = speakerInfo[@"detail"];
                                          speaker.identifier = speakerInfo[@"id"];
                                          speaker.avatar = [speakerInfo[@"avatar"] isEqualToString:@""] ? nil : [@"http://linz.kod.io/public/images/speakers/" stringByAppendingString:speakerInfo[@"avatar"]];
                                          speaker.github = [speakerInfo[@"github"] isEqualToString:@""] ? nil : [@"http://github.com/" stringByAppendingString:speakerInfo[@"github"]];
                                          speaker.twitter = [speakerInfo[@"twitter"] isEqualToString:@""] ? nil : [@"http://twitter.com/" stringByAppendingString:speakerInfo[@"twitter"]];
                                      }
                                      
                                      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                          // if (success) NSLog(@"Save successful!");
                                          // else NSLog(@"Save failed with error: %@", error);
                                      }];
                                      
                                      completion(@"speakers", remoteVersion[@"speakers"], YES);
                                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      completion(@"speakers", remoteVersion[@"speakers"], NO);
                                  }];
    } else {
        completion(@"speakers", self.localVersion[@"speakers"], YES);
    }
}
- (void)setupSessionsWithRemoteVersion:(NSDictionary *)remoteVersion completion:(void (^)(NSString *identifier, NSNumber *versionNumber, BOOL success))completion {
    // Check version and download new data if needed
    if ([self.localVersion[@"sessions"] compare:remoteVersion[@"sessions"]] == NSOrderedAscending) {
        // Remove local data
        [Session MR_truncateAll];
        // Fetch all sessions
        [[LinzAPIClient sharedClient] GET:@"/sessions"
                               parameters:nil
                                  success:^(NSURLSessionDataTask *task, id responseObject) {
                                      // responseObject holds info for all sessions
                                      NSInteger sortingIndex = 0;
                                      for (NSDictionary *sessionInfo in responseObject) {
                                          // Add a small dictionary object to specify time cells
                                          // Check type and track values of the sessions for appropriate placing
                                          if ([sessionInfo[@"track"] isEqualToNumber:@0] || [sessionInfo[@"track"] isEqualToNumber:@1]) { // We check the track info instead of type to not to add time data twice for simultaneous sessions
                                              // Create a session entity
                                              Session *session = [Session MR_createInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
                                              session.track = @(-1); // Track -1 means time cell level
                                              session.type = sessionInfo[@"type"]; // Type will help us to adjust the width
                                              session.timeInterval = sessionInfo[@"time"];
                                              session.sortingIndex = @(sortingIndex);
                                              // Increment index
                                              sortingIndex++;
                                          }
                                          // Create a session entity
                                          Session *session = [Session MR_createInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
                                          session.title = sessionInfo[@"title"];
                                          session.detail = sessionInfo[@"detail"];
                                          session.track = sessionInfo[@"track"];
                                          session.type = sessionInfo[@"type"];
                                          session.timeInterval = sessionInfo[@"time"];
                                          session.speakerIdentifier = sessionInfo[@"speaker"];
                                          session.sortingIndex = @(sortingIndex);
                                          session.identifier = sessionInfo[@"id"];
                                          // Increment index
                                          sortingIndex++;
                                      }
                                      
                                      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                          // if (success) NSLog(@"Save successful!");
                                          // else NSLog(@"Save failed with error: %@", error);
                                      }];
                                      
                                      completion(@"sessions", remoteVersion[@"sessions"], YES);
                                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      completion(@"sessions", remoteVersion[@"sessions"], NO);
                                  }];
    } else {
        completion(@"sessions", self.localVersion[@"sessions"], YES);
    }
}
- (void)setupSponsorsWithRemoteVersion:(NSDictionary *)remoteVersion completion:(void (^)(NSString *identifier, NSNumber *versionNumber, BOOL success))completion {
    // Check version and download new data if needed
    if ([self.localVersion[@"sponsors"] compare:remoteVersion[@"sponsors"]] == NSOrderedAscending) {
        // Remove local data
        [Sponsor MR_truncateAll];
        // Fetch all sponsors
        [[LinzAPIClient sharedClient] GET:@"/sponsors"
                               parameters:nil
                                  success:^(NSURLSessionDataTask *task, id responseObject) {
                                      // responseObject holds info for all sponsors
                                      for (NSDictionary *groupInfo in responseObject) {
                                          
                                          NSArray *sponsors = groupInfo[@"sponsors"];
                                          
                                          NSString *type = groupInfo[@"type"];
                                          NSInteger priority = [responseObject indexOfObject:groupInfo];
                                          
                                          for (NSDictionary *sponsorInfo in sponsors) {
                                              NSInteger subpriority = [sponsors indexOfObject:sponsorInfo];
                                              // Create a sponsor entity
                                              Sponsor *sponsor = [Sponsor MR_createInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
                                              sponsor.type = type;
                                              sponsor.imageURL = sponsorInfo[@"imageURL"];
                                              sponsor.websiteURL = sponsorInfo[@"websiteURL"];
                                              sponsor.priority = @(priority);
                                              sponsor.subpriority = @(subpriority);
                                              sponsor.identifier = sponsorInfo[@"id"];
                                          }
                                      }
                                      
                                      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                          // if (success) NSLog(@"Save successful!");
                                          // else NSLog(@"Save failed with error: %@", error);
                                      }];
                                      
                                      completion(@"sponsors", remoteVersion[@"sponsors"], YES);
                                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      completion(@"sponsors", remoteVersion[@"sponsors"], NO);
                                  }];
    } else {
        completion(@"sponsors", self.localVersion[@"sponsors"], YES);
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    exit(0); // Kill the app!
}

@end
