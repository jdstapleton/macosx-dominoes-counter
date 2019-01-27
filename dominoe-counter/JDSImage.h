#ifndef JDSImage_H
#define JDSImage_H

#if TARGET_OS_IPHONE
#define JDSImage UIImage
#else
#define JDSImage NSImage
#endif
#endif