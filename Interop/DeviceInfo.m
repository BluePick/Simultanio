//
//  NSObject+DeviceInfo.m
//  Casting-Tester
//
//  Created by Anders Bech Mellson on 19/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

#import "DeviceInfo.h"

#import <sys/utsname.h>

@implementation DeviceInfo

+ (NSString *)model
{
  struct utsname systemInfo;
  uname(&systemInfo);
  
  return [NSString stringWithCString: systemInfo.machine encoding: NSUTF8StringEncoding];
}

@end