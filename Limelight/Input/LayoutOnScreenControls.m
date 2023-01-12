//
//  LayoutOnScreenControls.m
//  Moonlight
//
//  Created by Long Le on 9/26/22.
//  Copyright © 2022 Moonlight Game Streaming Project. All rights reserved.
//

#import "LayoutOnScreenControls.h"
#import "OSCProfilesTableViewController.h"
#import "OnScreenButtonState.h"
#import "OSCProfilesManager.h"


@interface LayoutOnScreenControls ()
@end

@implementation LayoutOnScreenControls {
    
    UIButton *trashCanButton;
    UIView *horizontalGuideline;
    UIView *verticalGuideline;
}

@synthesize layerCurrentlyBeingTouched;
@synthesize _view;
@synthesize layoutChanges;

- (id) initWithView:(UIView*)view controllerSup:(ControllerSupport*)controllerSupport streamConfig:(StreamConfiguration*)streamConfig oscLevel:(int)oscLevel {
    _view = view;
    _view.multipleTouchEnabled = false;
  
    self = [super initWithView:view controllerSup:controllerSupport streamConfig:streamConfig];
    self._level = oscLevel;

    layoutChanges = [[NSMutableArray alloc] init];  // will contain OSC button layout changes the user has made for this profile
            
    [self drawButtons];
    [self drawGuidelines];  // add the blue guidelines that appear when button is being tapped and dragged
    
    return self;
}

/**
 * This method overrides the superclass's drawButtons method. The purpose of this method is to create a dPad parent layer, and add the four dPad buttons to it so that the user can drag the entire dPad around, directional buttons and all, as one unit as is the expected behavior. Note that we do not want the four dPad buttons to be child layers of a parent layer on the game stream view since the touch logic for the four dPad buttons on the game stream view is written assuming the dPad buttons are child layers of the game stream VC's 'view'
 */
- (void) drawButtons {
    [super setDPadCenter];    // Custom position for D-Pad set here
    [super setAnalogStickPositions]; // Custom position for analog sticks set here
    [super drawButtons];
    
    UIImage* downButtonImage = [UIImage imageNamed:@"DownButton"];
    UIImage* rightButtonImage = [UIImage imageNamed:@"RightButton"];
    UIImage* upButtonImage = [UIImage imageNamed:@"UpButton"];
    UIImage* leftButtonImage = [UIImage imageNamed:@"LeftButton"];
    
    //  create dPad background layer
    self._dPadBackground = [CALayer layer];
    self._dPadBackground.name = @"dPad";
    self._dPadBackground.frame = CGRectMake(self.D_PAD_CENTER_X,
                                      self.D_PAD_CENTER_Y,
                                      self._leftButton.frame.size.width * 2 + BUTTON_DIST,
                                      self._leftButton.frame.size.width * 2 + BUTTON_DIST);
    self._dPadBackground.position = CGPointMake(self.D_PAD_CENTER_X, self.D_PAD_CENTER_Y);    // since dPadBackground's dimensions have change you need to reset its position again here
    [self.OSCButtonLayers addObject:self._dPadBackground];
    [_view.layer addSublayer:self._dPadBackground];

    //  add dPad buttons to parent layer
    [self._dPadBackground addSublayer:self._downButton];
    [self._dPadBackground addSublayer:self._rightButton];
    [self._dPadBackground addSublayer:self._upButton];
    [self._dPadBackground addSublayer:self._leftButton];

    /* reposition each dPad button within their parent dPadBackground layer */
    self._downButton.frame = CGRectMake(self._dPadBackground.frame.size.width/3, self._dPadBackground.frame.size.height/2 + D_PAD_DIST, downButtonImage.size.width, downButtonImage.size.height);
    self._rightButton.frame = CGRectMake(self._dPadBackground.frame.size.width/2 + D_PAD_DIST, self._dPadBackground.frame.size.height/3, rightButtonImage.size.width, rightButtonImage.size.height);
    self._upButton.frame = CGRectMake(self._dPadBackground.frame.size.width/3, 0, upButtonImage.size.width, upButtonImage.size.height);
    self._leftButton.frame = CGRectMake(0, self._dPadBackground.frame.size.height/3, leftButtonImage.size.width, leftButtonImage.size.height);
}

/**
 * draws a horizontal and vertical line that is made visible and positioned over whichever button the user is dragging around the screen
 */
- (void) drawGuidelines {
    horizontalGuideline = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self._view.frame.size.width * 2, 2)];
    horizontalGuideline.backgroundColor = [UIColor blueColor];
    horizontalGuideline.hidden = YES;
    [self._view addSubview: horizontalGuideline];
    
    verticalGuideline = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, self._view.frame.size.height * 2)];
    verticalGuideline.backgroundColor = [UIColor blueColor];
    verticalGuideline.hidden = YES;
    [self._view addSubview: verticalGuideline];
}

/* used to determine whether user is dragging an OSC button (of type CALayer) over the trash can with the intent of deleting that button*/
- (BOOL)isLayer:(CALayer *)layer hoveringOverButton:(UIButton *)button {
    CGRect buttonConvertedRect = [self._view convertRect:button.imageView.frame fromView:button.superview];
    
    if (CGRectIntersectsRect(layer.frame, buttonConvertedRect)) {
        return YES;
    }
    else {
        return NO;
    }
}

/* returns reference to button layer object given the button's name*/
- (CALayer*)buttonLayerFromName: (NSString*)name {
    for (CALayer *buttonLayer in self.OSCButtonLayers) {
        
        if ([buttonLayer.name isEqualToString:name]) {
            return buttonLayer;
        }
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch* touch in touches) {
        
        CGPoint touchLocation = [touch locationInView:_view];
        touchLocation = [[touch view] convertPoint:touchLocation toView:nil];
        CALayer *touchedLayer = [_view.layer hitTest:touchLocation];

        if (touchedLayer == _view.layer) { // don't let user move the dark gray background
            return;
        }
        
        if (touchedLayer == super._upButton || touchedLayer == super._downButton || touchedLayer == super._leftButton || touchedLayer == super._rightButton) { // don't let user move individual dPad buttons
            layerCurrentlyBeingTouched = super._dPadBackground;
            
        } else if (touchedLayer == self._rightStick) {  // only let user move right stick background, not the stick itself
            layerCurrentlyBeingTouched = self._rightStickBackground;
            
        } else if (touchedLayer == self._leftStick) {  // only let user move left stick background, not the stick itself
            layerCurrentlyBeingTouched = self._leftStickBackground;
            
        } else {    // let user move whatever other valid button they're touching
            layerCurrentlyBeingTouched = touchedLayer;
        }
        
        /* make guide lines visible and position them over the button the user is touching */
        horizontalGuideline.center = layerCurrentlyBeingTouched.position;
        horizontalGuideline.hidden = NO;
        verticalGuideline.center = layerCurrentlyBeingTouched.position;
        verticalGuideline.hidden = NO;
        
        /* save the name and position of layer being touched in array in case user wants to undo the move later */
        OnScreenButtonState *onScreenButtonState = [[OnScreenButtonState alloc] initWithButtonName:layerCurrentlyBeingTouched.name isHidden:layerCurrentlyBeingTouched.isHidden andPosition:layerCurrentlyBeingTouched.position];
        [layoutChanges addObject:onScreenButtonState];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OSCLayoutChanged" object:self]; // lets the view controller know whether to fade the undo button in or out depending on whether there are any further OSC layout changes the user is allowed to undo
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:_view];
    layerCurrentlyBeingTouched.position = touchLocation; // move object to touch location
    
    horizontalGuideline.center = layerCurrentlyBeingTouched.position;
    verticalGuideline.center = layerCurrentlyBeingTouched.position;
    
    /*
     Telegraph to the user whether the horizontal and/or vertical guidelines line up with one or more of the buttons on screen by doing the following:
     -Change horizontal guideline color to white if its y-position is almost equal to that of one of the buttons on screen.
     -Change vertical guideline color to white if its x-position is almost equal to that of one of the buttons on screen.
     */
    for (CALayer *button in self.OSCButtonLayers) {
        
        if ((layerCurrentlyBeingTouched != button) && !button.isHidden) {
            if ((horizontalGuideline.center.y < button.position.y + 1) &&
                (horizontalGuideline.center.y > button.position.y - 1)) {
                horizontalGuideline.backgroundColor = [UIColor whiteColor];
                break;
            }
        }
        
        // change horizontal guideline back to blue if it doesn't line up with one of the on screen buttons
        horizontalGuideline.backgroundColor = [UIColor blueColor];
    }
    for (CALayer *button in self.OSCButtonLayers) {
        
        if ((layerCurrentlyBeingTouched != button) && !button.isHidden) {
            if ((verticalGuideline.center.x < button.position.x + 1) &&
                (verticalGuideline.center.x > button.position.x - 1)) {
                verticalGuideline.backgroundColor = [UIColor whiteColor];
                break;
            }
        }
        
        //  change vertical guideline back to blue if it doesn't line up with one of the on screen buttons
        verticalGuideline.backgroundColor = [UIColor blueColor];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    layerCurrentlyBeingTouched = nil;
         
    horizontalGuideline.hidden = YES;
    verticalGuideline.hidden = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    layerCurrentlyBeingTouched = nil;
    
    horizontalGuideline.hidden = YES;
    verticalGuideline.hidden = YES;
}




@end
