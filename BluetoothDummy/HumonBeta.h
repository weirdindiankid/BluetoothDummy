//
//  HumonBeta.h
//  BluetoothDummy
//
//  Created by Dharmesh Tarapore on 6/17/16.
//  Copyright © 2016 Humon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HumonBeta;

// returns an NSArray containing NSNumbers from an NSData
// the NSData contains a series of 32-bit little-endian ints
NSArray *arrayFromData(NSData *data);