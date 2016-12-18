//
//  HumonBeta.m
//  HumonBLETest
//
//  Created by Dharmesh Tarapore on 6/17/16.
//  Copyright © 2016 Humon. All rights reserved.
//

#import "HumonBeta.h"

// returns an NSArray containing NSNumbers from an NSData
// the NSData contains a series of 32-bit little-endian ints
NSArray *arrayFromData(NSData *data) {
    void *bytes = [data bytes];
    NSMutableArray *ary = [NSMutableArray array];
    for (NSUInteger i = 0; i < [data length]; i += sizeof(uint16_t)) {
        uint16_t elem = OSReadLittleInt(bytes, i);
        [ary addObject:[NSNumber numberWithInt:elem]];
    }
    return ary;
}

unsigned int stringToHex(const char * s) {
    unsigned int result = 0;
    int c ;
    if ('0' == *s && 'x' == *(s+1)) { s+=2;
        while (*s) {
            result = result << 4;
            if (c=(*s-'0'),(c>=0 && c <=9)) result|=c;
            else if (c=(*s-'A'),(c>=0 && c <=5)) result|=(c+10);
            else if (c=(*s-'a'),(c>=0 && c <=5)) result|=(c+10);
            else break;
            ++s;
        }
    }
    return result;
}