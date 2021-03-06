//
//  ViewController.m
//  MazeMan
//
//  Created by Eddie Power on 4/11/18.
//  Copyright © 2018 Eddie Power. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/CAAnimation.h>
#import <CoreMotion/CoreMotion.h>
//const time per update tick
#define kUpdateInterval (1.0f / 60.0f)

@interface ViewController ()
@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
   
    //we define the x and y of origin as our ghost 1 center and target is our destination
    //in this case move Y up 124 places/pixels
    CGPoint origin1 = self.ghost1.center;
    CGPoint target1 = CGPointMake(self.ghost1.center.x, self.ghost1.center.y-124);
    
    //as bounce is up and down we use the Y from x,y positions.
    CABasicAnimation *bounce1 = [CABasicAnimation animationWithKeyPath: @"position.y"];
    
    //set the from value as above (start point)
    bounce1.fromValue = [NSNumber numberWithInt: origin1.y];
    
    //set the destination value as target y position as above up 124 pixels.
    bounce1.toValue = [NSNumber numberWithInt: target1.y];
    
    //time for bounce
    bounce1.duration = 2;
    
    //up and down = yes
    bounce1.autoreverses = YES;
    
    //float linux constant - repeat number.
    bounce1.repeatCount = HUGE_VALF;
    
    //now assign the annimation to the ghost image.
    [self.ghost1.layer addAnimation: bounce1 forKey: @"position"];
    
    //ghost 2 as above
    CGPoint origin2 = self.ghost2.center;
    CGPoint target2 = CGPointMake(self.ghost2.center.x, self.ghost2.center.y+284);
    CABasicAnimation *bounce2 = [CABasicAnimation animationWithKeyPath: @"position.y"];
    bounce2.fromValue = [NSNumber numberWithInt:origin2.y];
    bounce2.toValue = [NSNumber numberWithInt:target2.y];
    bounce2.duration = 2;
    bounce2.repeatCount = HUGE_VALF;
    bounce2.autoreverses = YES;
    [self.ghost2.layer addAnimation: bounce2 forKey: @"position"];
    
    //ghost3 as above.
    CGPoint origin3 = self.ghost3.center;
    CGPoint target3 = CGPointMake(self.ghost3.center.x, self.ghost3.center.y-284);
    CABasicAnimation *bounce3 = [CABasicAnimation animationWithKeyPath:@"position.y"];
    bounce3.fromValue = [NSNumber numberWithInt:origin3.y];
    bounce3.toValue = [NSNumber numberWithInt:target3.y];
    bounce3.duration = 2;
    bounce3.repeatCount = HUGE_VALF;
    bounce3.autoreverses = YES;
    [self.ghost3.layer addAnimation:bounce3 forKey:@"position"];

    /*
     * Create the motion / accelerometer manager object,
     * date object last update - will also be used as played date for high scores.
     */
    self.motionManager = [[CMMotionManager alloc]  init];
    self.lastUpdateTime = [[NSDate alloc] init];
    self.currentPoint  = CGPointMake(0, 144);
    self.queue         = [[NSOperationQueue alloc] init];
    
    //Update interval / how ofter it updates accel stored as const float val above.
    self.motionManager.accelerometerUpdateInterval = kUpdateInterval;
    
    //DEBUG STUFF
    //UIImageView *wallLocal1 = [_wall objectAtIndex: 0];
    //NSLog(@"Some Positions of stuff is Pacman: %f %f, Box1: %f, %f", self.pacman.center.x, self.pacman.center.y, wallLocal1.center.x, wallLocal1.center.y);
    
    //setup the score / highscore stuff
    //will be set & retrieved from core data asap.
    self.userId = 0;
    self.userName = @"Eddie";
    self.currentScore = [[NSNumber alloc] initWithInt: 0];
    self.playedDate = [NSDate date];
    self.livesLeft = [[NSNumber alloc] initWithInt: 4];
    
}

//called as the view is drawn to the screen vs when its loaded in memory above - i think.
-(void) viewDidAppear: (BOOL)animated
{
    //set up the Accelerometer to start updating using a que and call back
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:
     ^(CMAccelerometerData *accelerometerData, NSError *error)
     {
         if(error == NULL)
         {
             [(id) self setAcceleration: accelerometerData.acceleration];
             [self performSelectorOnMainThread:@selector(Update) withObject:nil waitUntilDone:NO];
         }
         else
         {
             NSLog(@"Error occured: Message - %@", error.debugDescription);
         }
     }];
}

- (void) Update
{
    NSTimeInterval secondsSinceLastDraw = -([self.lastUpdateTime timeIntervalSinceNow]);
    
    self.pacmanYVelocity = self.pacmanYVelocity - (self.acceleration.x * secondsSinceLastDraw);
    self.pacmanXVelocity = self.pacmanXVelocity - (self.acceleration.y * secondsSinceLastDraw);
    
    CGFloat xDelta = secondsSinceLastDraw * self.pacmanXVelocity * 500;
    CGFloat yDelta = secondsSinceLastDraw * self.pacmanYVelocity * 500;
    
    self.currentPoint = CGPointMake(self.currentPoint.x + xDelta,
                                    self.currentPoint.y + yDelta);
//    NSLog(@"the current x position is: %f \nThe current Y position: %f", self.pacman.center.x, self.pacman.center.y);
    
    [self MovePacman];
    self.lastUpdateTime = [NSDate date];
}

- (void) MovePacman
{
    //Call and test pacman location in these methods in this order:
    [self CollisionWithExit]; //did user win?
    [self CollisionWithGhosts]; //did user die?
    [self CollsionWithWalls]; //did user bang into the wall blocks (walls Array)
    [self CollisionWithBoundaries]; //did user bounce off the boundry
    
    //store the last location (x, y).
    self.previousPoint = self.currentPoint;
    
    //grab pacmans frame to set the x y locations.
    CGRect frame = self.pacman.frame;
    frame.origin.x = self.currentPoint.x;
    frame.origin.y = self.currentPoint.y;
    
    //NSLog(@"Pacman is now in location X: %f Y: %f", self.currentPoint.x, self.currentPoint.y);
    
    //assign the new location fram to pacman image.
    self.pacman.frame = frame;
}

/*
 * Basically resets the pacman position if its in the negative
 * or off screen back to the edge looks like it bounces on edge.
 */
- (void) CollisionWithBoundaries
{
    if (self.currentPoint.x < 0)
    {
        _currentPoint.x = 0;
        self.pacmanXVelocity = -(self.pacmanXVelocity / 2.0);
    }
    
    if (self.currentPoint.y < 0)
    {
        _currentPoint.y = 0;
        self.pacmanYVelocity = -(self.pacmanYVelocity / 2.0);
    }
    
    if (self.currentPoint.x > self.view.bounds.size.width - self.pacman.image.size.width)
    {
        _currentPoint.x = self.view.bounds.size.width - self.pacman.image.size.width;
        self.pacmanXVelocity = -(self.pacmanXVelocity / 2.0);
    }
    
    if (self.currentPoint.y > self.view.bounds.size.height - self.pacman.image.size.height)
    {
        _currentPoint.y = self.view.bounds.size.height - self.pacman.image.size.height;
        self.pacmanYVelocity = -(self.pacmanYVelocity / 2.0);
    }
}

//Triggers end of updates.
- (void) CollisionWithExit
{
    NSNumber *WinScore = [[NSNumber alloc] initWithInt: 25];
    
    if (CGRectIntersectsRect(self.pacman.frame, self.exit.frame))
    {
//        self.currentScore += WinScore;
        
        //stop the tilt mech - stop accelerometer updates.
        [self.motionManager stopAccelerometerUpdates];

        UIAlertController* alertWinning = [UIAlertController alertControllerWithTitle: @"Congratulations!!"
                                                                message: @"You've won the game ~ Big woop"
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction* winningAction = [UIAlertAction actionWithTitle: @"Restart" style: UIAlertActionStyleDefault
                                                              handler: ^(UIAlertAction *action)
                                                              {
                                                                  //Reset pacman and restart game / accel updates.
                                                                  self.currentPoint  = CGPointMake(0, 144);
                                                                  [self viewDidAppear: FALSE];
                                                              }];
        
        [alertWinning addAction:winningAction];
        [self presentViewController: alertWinning animated:YES completion:nil];
    }
}

- (void) CollisionWithGhosts
{
    CALayer *ghostLayer1 = [self.ghost1.layer presentationLayer];
    CALayer *ghostLayer2 = [self.ghost2.layer presentationLayer];
    CALayer *ghostLayer3 = [self.ghost3.layer presentationLayer];
    
    //if the pacman img frame colides with ghost/s
    if (CGRectIntersectsRect(self.pacman.frame, ghostLayer1.frame) || CGRectIntersectsRect(self.pacman.frame, ghostLayer2.frame)
        || CGRectIntersectsRect(self.pacman.frame, ghostLayer3.frame) )
    {
        [self.motionManager stopAccelerometerUpdates];
        NSNumber *lowerBound = [[NSNumber alloc] initWithInt: 25];
        
//        if(self.currentScore >= lowerBound)
//        {
//            self.currentScore -= lowerBound;
//        }
//        else
//        {
//            self.currentScore = 0;
//        }
       UIAlertController* AlertLooser = [UIAlertController alertControllerWithTitle:@"Oops!!!"
                                                                       message:@"Mission Failed - Really is it hard to play..."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
       UIAlertAction* looserAction = [UIAlertAction actionWithTitle:@"Restart" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action)
                                        {
                                           //restart the game / gyro updates
                                           //NSLog(@"Inside the Restart button after death async callback type call");
                                           self.currentPoint  = CGPointMake(0, 144);
                                           [self viewDidAppear: FALSE];
                                        }];
        
        //add action to the alertController
        [AlertLooser addAction: looserAction];
        
        //Call the alertController view / Alert Box pop up.
        [self presentViewController: AlertLooser animated: YES completion: nil];
    }
}

- (void) CollsionWithWalls
{
    CGRect frame = self.pacman.frame;
    frame.origin.x = self.currentPoint.x;
    frame.origin.y = self.currentPoint.y;
    
    for (UIImageView *image in self.wall)
    {
        if (CGRectIntersectsRect(frame, image.frame))
        {
            // Compute collision angle
            CGPoint pacmanCenter = CGPointMake(frame.origin.x + (frame.size.width / 2),
                                               frame.origin.y + (frame.size.height / 2));
            CGPoint imageCenter  = CGPointMake(image.frame.origin.x + (image.frame.size.width / 2),
                                               image.frame.origin.y + (image.frame.size.height / 2));
            CGFloat angleX = pacmanCenter.x - imageCenter.x;
            CGFloat angleY = pacmanCenter.y - imageCenter.y;
            
            if (fabs(angleX) > fabs(angleY))
            {
                _currentPoint.x = self.previousPoint.x;
                self.pacmanXVelocity = -(self.pacmanXVelocity / 2.0);
            }
            else
            {
                _currentPoint.y = self.previousPoint.y;
                self.pacmanYVelocity = -(self.pacmanYVelocity / 2.0);
            }
        }
    }
}

@end
