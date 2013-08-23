//
//  NSURLConnection+LBcategory.h
//  Created by Lucian Boboc on 1/27/13.
//

/*

 This NSURLConnection category was created to help you do 3 things easier:
 1. get a UIImage/NSData from a URL
 2. send NSString using POST and get a JSON id object
 3. send JSON NSData using POST and get a JSON id object

 To use this methods you should pass the urlData (string or JSON) to be set on the NSMutableURLRquest for the HTTPBody property and the method (GET/POST).
 If the NSError object is nil, the image/JSON object is returnted.

*/

#import <Foundation/Foundation.h>

#define kTimeoutInteral 30
#define kMaxConcurrentOperations 2




#define kLBErrorDomain @"LBCacheErrorDomain"

#define kImageNotFoundDescription @"The image was not found at the local path in cache."

#define kCantCreateImageDescription @"The image can't be created from NSData object."

typedef NS_ENUM(NSUInteger, LBCacheError){
    // the image was not found at local path in cache
    LBCacheErrorImageNotFound,
    
//    // the image can't be created from the NSData object
    LBCacheErrorCantCreateImage,
};


typedef void (^DownloadImageCompletionBlock)(UIImage *image, NSData *imageData, NSHTTPURLResponse *response, NSError *error);
typedef void (^DownloadJSONObjectCompletionBlock)(id object,NSHTTPURLResponse *response, NSError *error);


@interface NSURLConnection (LBcategory)

+ (NSOperationQueue *) sharedQueue;

// this method should not be called on the main thread, request is created using NSURLRequestReloadIgnoringLocalCacheData
+ (void) synchronousDownloadImageDataFromURLString: (NSString *) urlString completionBlock: (DownloadImageCompletionBlock) theBlock;

+ (void) downloadImageFromURLString: (NSString *) urlString completionBlock: (DownloadImageCompletionBlock) theBlock;

+ (void) downloadJSONObjectFromURLString: (NSString *) urlString urlData: (NSString *) urlData method: (NSString *) method completionBlock: (DownloadJSONObjectCompletionBlock) theBlock;

+ (void) downloadJSONObjectFromURLString: (NSString *) urlString objectForURLData: (id) object method: (NSString *) method completionBlock: (DownloadJSONObjectCompletionBlock) theBlock;




@end
