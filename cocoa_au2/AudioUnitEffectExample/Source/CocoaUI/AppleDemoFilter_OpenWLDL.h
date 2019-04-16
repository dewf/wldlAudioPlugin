//
//  AppleDemoFilter_OpenWLDL.h
//  FilterDemo
//
//  Created by Daniel G on 4/15/19.
//
//

#ifndef __FilterDemo__AppleDemoFilter_OpenWLDL__
#define __FilterDemo__AppleDemoFilter_OpenWLDL__

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

#ifdef __cplusplus
extern "C" {
#endif

NSView *AppleDemoFilter_CreateWLViewFor(AudioUnit inAU, NSSize size);
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__FilterDemo__AppleDemoFilter_OpenWLDL__) */
