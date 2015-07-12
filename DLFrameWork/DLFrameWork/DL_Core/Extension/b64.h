#import <Foundation/NSData.h>

NSData * b64_encode( NSData * data );
NSData * b64_decode( NSData * data );
void decodeblock( unsigned char in[4], unsigned char out[3] );