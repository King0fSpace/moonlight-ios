//
//  OSCProfilesManager.m
//  Moonlight
//
//  Created by Long Le on 1/1/23.
//  Copyright © 2023 Moonlight Game Streaming Project. All rights reserved.
//

#import "OSCProfilesManager.h"

@implementation OSCProfilesManager

#pragma mark - Initializer

+ (OSCProfilesManager *) sharedManager {
    static OSCProfilesManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}


#pragma mark - Class Helper Methods

/**
 * Returns the profile whose 'name' property has a value that is equal to the 'name' param
 */
- (OSCProfile *) OSCProfileWithName:(NSString*)name {
    // Get the encoded array of encoded OSC profiles from persistent storage
    NSData *profilesArrayEncoded = [[NSUserDefaults standardUserDefaults] objectForKey:@"OSCProfiles"];
    NSSet *classes = [NSSet setWithObjects:[NSString class], [NSMutableData class], [NSMutableArray class], [OSCProfile class], [OnScreenButtonState class], nil];
    
    // Decode the encoded array itself, NOT the objects contained in the array
    NSMutableArray *profilesEncoded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:profilesArrayEncoded error:nil];
    
    
    /* Decode each OSC profile in the array. Iterate through the array and return the first OSC profile whose 'name' property equals the 'name' parameter passed into this method */
    OSCProfile *profileDecoded;
    for (NSData *profileEncoded in profilesEncoded) {
        
        profileDecoded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:profileEncoded error:nil];
        
        if ([profileDecoded.name isEqualToString:name]) {
            return profileDecoded;
        }
    }
    
    return nil;
}

/**
 * Returns an array of decoded 'OSCProfile'  objects retrieved from persistent storage
 */
- (NSMutableArray *)getAllProfiles {
    
    // Get the encoded array of encoded OSC profiles from persistent storage
    NSData *profilesArrayEncoded = [[NSUserDefaults standardUserDefaults] objectForKey: @"OSCProfiles"];
    NSSet *classes = [NSSet setWithObjects:[NSString class], [NSMutableData class], [NSMutableArray class], [OSCProfile class], [OnScreenButtonState class], nil];
    
    // Decode the encoded array itself, NOT the objects contained in the array
    NSMutableArray *profilesEncoded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:profilesArrayEncoded error:nil];
    
    /* Decode each of the encoded profiles, place them into an array, then return the array */
    NSMutableArray *profilesDecoded = [[NSMutableArray alloc] init];
    OSCProfile *profileDecoded;
    for (NSData *profileEncoded in profilesEncoded) {
        
        profileDecoded = [NSKeyedUnarchiver unarchivedObjectOfClasses: classes fromData:profileEncoded error: nil];
        [profilesDecoded addObject: profileDecoded];
    }
    return profilesDecoded;
}

/**
 * Returns an array of encoded 'OSCProfile' objects from the array of decoded 'OSCProfile' objects passed into this method
 */
- (NSMutableArray *) encodedProfilesFromArray:(NSMutableArray *)profiles {
    
    NSMutableArray *profilesEncoded = [[NSMutableArray alloc] init];
    for (OSCProfile *profile in profiles) {   //add encoded profiles back into an array
        
        NSData *profileEncoded = [NSKeyedArchiver archivedDataWithRootObject:profile requiringSecureCoding:YES error:nil];
        [profilesEncoded addObject:profileEncoded];
    }
    
    return profilesEncoded;
}

/**
 * Replaces one 'OSCProfile' object for another in the 'OSCProfile' objects array stored in persistent storage
 */
- (void) replaceProfile:(OSCProfile*)oldProfile withProfile:(OSCProfile*)newProfile {
    NSMutableArray *profiles = [self getAllProfiles];

    /* Set the new profile as the selected one. The reasoning for this is that this method is currently being used when the user saves over an existing profile with another one of the same name. The expected behavior is that the newly saved profile becomes the selected profile which will show on screen when they launch the game stream view */
    newProfile.isSelected = YES;
  
    /* Remove the old profile from the array and insert the new profile into its place */
    int index = 0;
    for (int i = 0; i < profiles.count; i++) {
        
        if ([[profiles[i] name] isEqualToString: oldProfile.name]) {
            
            index = i;
        }
    }
    [profiles removeObjectAtIndex:index];
    [profiles insertObject:newProfile atIndex:index];
    
    NSMutableArray *profilesEncoded = [self encodedProfilesFromArray:profiles];
    
    /* Encode the array itself, which contains encoded profiles. Save it to persistent storage */
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profilesEncoded requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"OSCProfiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Globally Accessible Methods

- (OSCProfile *)getSelectedProfile {
    NSMutableArray *profiles = [self getAllProfiles];

    for (OSCProfile *profile in profiles) {
                
        if (profile.isSelected) {
            return profile;
        }
    }
    return nil;
}

- (void) setProfileToSelected:(NSString *)name {
    NSMutableArray *profiles = [self getAllProfiles];
    
    /* Iterate through each profile. If its name equals the value of the 'name' parameter passed into this method then set the profile's 'isSelected' property to YES, otherwise set the value to NO*/
    for (OSCProfile *profile in profiles) {
                
        if ([profile.name isEqualToString:name]) {
            profile.isSelected = YES;
        }
        else {
            profile.isSelected = NO;
        }
    }
    
    NSMutableArray *profilesEncoded = [self encodedProfilesFromArray:profiles];
        
    /* Encode the array itself, NOT the objects inside the array*/
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profilesEncoded requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"OSCProfiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveProfileWithName:(NSString*)name andButtonLayers:(NSMutableArray *)buttonLayers {
    /* iterate through each OSC button the user sees on screen, create an 'OnScreenButtonState' object from each button, and then add the object to an array */
    NSMutableArray *OSCButtonStates = [[NSMutableArray alloc] init];
    for (CALayer *buttonLayer in buttonLayers) {

        OnScreenButtonState *onScreenButtonState = [[OnScreenButtonState alloc] initWithButtonName:buttonLayer.name  isHidden:buttonLayer.isHidden andPosition:buttonLayer.position];
        [OSCButtonStates addObject:onScreenButtonState];
    }

    /* Iterate through each 'ButtonState' object, encode them, and place them into an array */
    NSMutableArray *OSCButtonStatesEncoded = [[NSMutableArray alloc] init];
    for (OnScreenButtonState *buttonState in OSCButtonStates) {

        NSData *buttonStateDataObject = [NSKeyedArchiver archivedDataWithRootObject:buttonState requiringSecureCoding:YES error:nil];
        [OSCButtonStatesEncoded addObject: buttonStateDataObject];
    }

    //create a new OSCProfile. Set the button states array created above to the 'buttonStates' property of the new profile
    OSCProfile *newProfile = [[OSCProfile alloc] initWithName:name buttonStates:OSCButtonStatesEncoded isSelected:YES];
    
    /* set all saved OSCProfiles 'isSelected' property to NO since the new profile you're adding will be set as the selected profile */
    NSMutableArray *profiles = [self getAllProfiles];
    for (OSCProfile *profile in profiles) {
        
        profile.isSelected = NO;
    }
    
    if ([self profileNameAlreadyExist:name]) {  //if profile with 'name' already exists then overwrite it
                        
        [self replaceProfile:[self OSCProfileWithName:name] withProfile:newProfile];
    }
    else {  //otherwise encode then add the new profile to the end of the OSCProfiles array
                
        NSData *newProfileEncoded = [NSKeyedArchiver archivedDataWithRootObject:newProfile requiringSecureCoding:YES error:nil];
        NSMutableArray *profilesEncoded = [self encodedProfilesFromArray:profiles];
        [profilesEncoded addObject:newProfileEncoded];
        
        /* Encode the array itself, which contains encoded profiles. Save it to persistent storage */
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profilesEncoded requiringSecureCoding:YES error:nil];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"OSCProfiles"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL) profileNameAlreadyExist:(NSString*)name {
    NSMutableArray *profiles = [self getAllProfiles];
    
    /* Iterate through the decoded profiles and return the first profile whose name property equals the 'name' param passed into this method */
    for (OSCProfile *profile in profiles) {
        
        if ([profile.name isEqualToString:name]) {
            
            return YES;
        }
    }
    
    return NO;
}

@end
