//
//  NSURLConnection+LBcategory.m
//  Created by Lucian Boboc on 1/27/13.
//

#import "NSURLConnection+LBcategory.h"

@implementation NSURLConnection (LBcategory)

+ (NSOperationQueue *) sharedQueue
{
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount: kMaxConcurrentOperations];
    });
    return queue;
}




+ (void) synchronousDownloadImageDataFromURLString: (NSString *) urlString completionBlock: (DownloadImageCompletionBlock) theBlock
{
    if(!urlString)
    {
        NSError *error = [NSError errorWithDomain: @"LBErrorDomain" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"Invalid URL."}];
        if(theBlock)
            theBlock(nil,nil,nil,error);        
        return;
    }

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString] cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: kTimeoutInteral];
    [request setAllHTTPHeaderFields: @{@"Accept":@"image/*"}];
    [request setHTTPMethod: @"GET"];
    [request setTimeoutInterval: kTimeoutInteral];    
    
    [request setHTTPShouldUsePipelining: YES];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
    
    NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
    if(error)
    {
        if(theBlock)
        {
#if DEBUG
            NSLog(@"REQUEST URL %@ \nERROR: %@", urlString, error.localizedDescription);
#endif
            theBlock(nil,nil,theResponse, error);
        }
    }
    else
    {
        if(theBlock)
        {

            int statusCode = response.statusCode;
            if(statusCode < 400)
            {
                UIImage *image = [UIImage imageWithData: data];
                if(!image)
                {
                    NSError *error = [NSError errorWithDomain: kLBErrorDomain code: LBCacheErrorCantCreateImage userInfo: @{NSLocalizedDescriptionKey: kCantCreateImageDescription}];
                    theBlock(nil,nil,theResponse,error);
                }
                else
                    theBlock(image,data,theResponse,nil);
            }
            else
            {
                NSError *error = [NSError errorWithDomain: NSURLErrorDomain code: statusCode userInfo: nil];
                theBlock(nil,nil,theResponse,error);
            }
        }
    }
}


+ (void) downloadImageFromURLString: (NSString *) urlString completionBlock: (DownloadImageCompletionBlock) theBlock
{
    if(!urlString)
    {
        NSError *error = [NSError errorWithDomain: @"LBErrorDomain" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"Invalid URL."}];
        if(theBlock)
            theBlock(nil,nil,nil,error);
        return;
    }
    
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setAllHTTPHeaderFields: @{@"Accept":@"image/*"}];
    [request setHTTPMethod: @"GET"];
    [request setTimeoutInterval: kTimeoutInteral];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest: request queue: [NSURLConnection sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        
        NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
        if(error != nil)
        {
            if(theBlock)
            {
#if DEBUG
            NSLog(@"REQUEST URL %@ \nERROR: %@", urlString, error.localizedDescription);
#endif             
                theBlock(nil,nil,theResponse,error);
            }
        }
        else
        {
            if(theBlock)
            {
                int statusCode = theResponse.statusCode;
                if(statusCode < 400)
                {
                    UIImage *image = [UIImage imageWithData: data];
                    if(!image)
                    {
                        NSError *error = [NSError errorWithDomain: kLBErrorDomain code: LBCacheErrorCantCreateImage userInfo: @{NSLocalizedDescriptionKey: kCantCreateImageDescription}];
                        theBlock(nil,nil,theResponse,error);
                    }
                    else
                        theBlock(image,data,theResponse,nil);
                }
                else
                {
                    NSError *error = [NSError errorWithDomain: NSURLErrorDomain code: statusCode userInfo: nil];
                    theBlock(nil,nil,theResponse,error);
                }
            }
        }
    }];
}





+ (void) downloadJSONObjectFromURLString: (NSString *) urlString urlData: (NSString *) urlData method: (NSString *) method completionBlock: (DownloadJSONObjectCompletionBlock) theBlock
{
    
    if(!urlString || !method)
    {
        NSError *error = [NSError errorWithDomain: @"LBErrorDomain" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"Invalid method argument(s)."}];
        if(theBlock)
            theBlock(nil,nil,error);
        return;
    }
    
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setAllHTTPHeaderFields: @{@"Accept":@"application/json"}];
    [request setHTTPMethod: method];
    [request setTimeoutInterval: kTimeoutInteral];
    
    if(urlData)
        [request setHTTPBody: [urlData dataUsingEncoding:NSUTF8StringEncoding]];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest: request queue: [NSURLConnection sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        
        NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
        
        if(error != nil)
        {
            if(theBlock)
            {
#if DEBUG
            NSLog(@"REQUEST URL %@ \nERROR: %@", urlString, error.localizedDescription);
#endif             
                theBlock(nil,theResponse,error);
            }
        }
        else
        {
            if(theBlock)
            {
                int statusCode = theResponse.statusCode;
                if(statusCode < 400)
                {
                    id object = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:&error];
                    if(error != nil)
                    {
#if DEBUG
                        NSLog(@"REQUEST URL %@ \nJSON ERROR: %@", urlString, error.localizedDescription);
#endif
                        theBlock(nil,theResponse,error);
                    }
                    else
                    {
#if DEBUG
                        NSLog(@"REQUEST URL %@ \nJSON RESPONSE: %@", urlString, object);
#endif
                        theBlock(object,theResponse,nil);
                    }
                }
                else
                {
                    NSError *error = [NSError errorWithDomain: NSURLErrorDomain code: statusCode userInfo: nil];
                    theBlock(nil,theResponse,error);
                }
            }
        }
    }];
}


+ (void) downloadJSONObjectFromURLString: (NSString *) urlString objectForURLData: (id) object method: (NSString *) method completionBlock: (DownloadJSONObjectCompletionBlock) theBlock
{
    if(!urlString || !object || !method)
    {
        NSError *error = [NSError errorWithDomain: @"LBErrorDomain" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"Invalid method argument(s)."}];
        if(theBlock)
            theBlock(nil,nil,error);
        return;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: object options: 0 error: &error];
    if(error)
    {
        if(theBlock)
            theBlock(nil,nil,error);
        return;
    }
    
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setAllHTTPHeaderFields: @{@"Accept":@"application/json"}];
    [request setHTTPMethod: method];
    [request setTimeoutInterval: kTimeoutInteral];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue: [NSString stringWithFormat: @"%d",[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: jsonData];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest: request queue: [NSURLConnection sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        
        NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
        
        if(error != nil)
        {
            if(theBlock)
            {
#if DEBUG
                NSLog(@"REQUEST URL %@ \nERROR: %@", urlString, error.localizedDescription);
#endif
                theBlock(nil,theResponse,error);
            }
        }
        else
        {
            if(theBlock)
            {
                int statusCode = theResponse.statusCode;
                if(statusCode < 400)
                {
                    id object = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:&error];
                    if(error != nil)
                    {
#if DEBUG
                        NSLog(@"REQUEST URL %@ \nJSON ERROR: %@", urlString, error.localizedDescription);
#endif
                        theBlock(nil,theResponse,error);
                    }
                    else
                    {
#if DEBUG
                        NSLog(@"REQUEST URL %@ \nJSON RESPONSE: %@", urlString, object);
#endif
                        theBlock(object,theResponse,nil);
                    }
                }
                else
                {
                    NSError *error = [NSError errorWithDomain: NSURLErrorDomain code: statusCode userInfo: nil];
                    theBlock(nil,theResponse,error);
                }
            }
        }
    }];
}

@end
