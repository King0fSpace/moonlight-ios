//
//  OSCProfilesManager.h
//  Moonlight
//
//  Created by Long Le on 1/1/23.
//  Copyright © 2023 Moonlight Game Streaming Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCProfile.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSCProfilesManager : NSObject

@property (nonatomic, strong) NSMutableArray *OSCButtonLayers;

+ (OSCProfilesManager *)sharedManager;
- (OSCProfile *)selectedOSCProfile;
- (void)setOSCProfileAsSelectedWithName: (NSString *)name;
- (NSData *)OSCProfileWithName: (NSString*)name;
- (BOOL)profileNameAlreadyExist: (NSString*)name;
- (void)saveOSCProfileWithName: (NSString*)name;
- (void)replaceOSCProfile: (NSData*)oldProfile withOSCProfile: (NSData*)newProfile;



@end

NS_ASSUME_NONNULL_END
