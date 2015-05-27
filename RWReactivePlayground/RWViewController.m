//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.signInService = [RWDummySignInService new];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
//  [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
//      NSLog(@"%@", x);
//  }];
    
//    [[self.usernameTextField.rac_textSignal filter:^BOOL(NSString *text) {
//        return text.length > 3;
//    }] subscribeNext:^(id x) {
//        NSLog(@"%@", x);
//    }];
    
//    RACSignal *usernameSourceSignal = self.usernameTextField.rac_textSignal;
//    
//    RACSignal *filteredUsernameSignal = [usernameSourceSignal filter:^BOOL(id value) {
//        NSString *text = value;
//        return text.length > 3;
//    }];
//    
//    [filteredUsernameSignal subscribeNext:^(id x) {
//        NSLog(@"%@", x);
//    }];
    
//    [[[self.usernameTextField.rac_textSignal
//        map:^id(NSString *text) {
//            return @(text.length);
//        }]
//        filter:^BOOL(NSNumber *length) {
//            return [length integerValue] > 3;
//        }]
//        subscribeNext:^(id x) {
//            NSLog(@"%@", x);
//        }];
    
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidUsername:value]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidPassword:value]);
    }];
    
//    [[validPasswordSignal map:^id(NSNumber *passwordValid) {
//        return [passwordValid boolValue] ? [UIColor clearColor]: [UIColor yellowColor];
//    }]
//    subscribeNext:^(UIColor *color) {
//        self.passwordTextField.backgroundColor = color;
//    }];
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
                return [passwordValid boolValue] ? [UIColor clearColor]: [UIColor yellowColor];
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *usernameValid) {
        return [usernameValid boolValue]? [UIColor clearColor]: [UIColor yellowColor];
    }];
    
    RACSignal *signupActiveSignal =
        [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                          reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid) {
                              return @([usernameValid boolValue] && [passwordValid boolValue]);
                          }];
    
    [signupActiveSignal subscribeNext:^(NSNumber *signupActive) {
        self.signInButton.enabled = [signupActive boolValue];
    }];
    
//    [[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        NSLog(@"button clicked");
//    }];
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
        doNext:^(id x) {
            self.signInButton.enabled = NO;
            self.signInFailureText.hidden = YES;
        }]
        flattenMap:^id(id value) {
            return [self signinSignal];
        }]
        subscribeNext:^(NSNumber *signedIn) {
            NSLog(@"Sign in result: %@", signedIn);
            BOOL success = [signedIn boolValue];
            self.signInFailureText.hidden = success;
            if (success) {
                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
            }
        }];
    
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (RACSignal *)signinSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService
            signInWithUsername:self.usernameTextField.text
            password:self.passwordTextField.text complete:^(BOOL success) {
                [subscriber sendNext:@(success)];
                [subscriber sendCompleted];
            }];
        return nil;
    }];
}

@end
