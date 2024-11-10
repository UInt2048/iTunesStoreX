#import "CustomURLProtocol.h"

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface CustomURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation CustomURLProtocol

static NSString* outputDictionary(NSDictionary* inputDict) {
    NSMutableString * outputString = [NSMutableString stringWithCapacity:256];
    NSArray * allKeys = [inputDict allKeys];

    for (NSString * key in allKeys) {
        if ([[inputDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            [outputString appendString: outputDictionary((NSDictionary *)inputDict)];
        }
        else {
            [outputString appendString: key];
            [outputString appendString: @": "];
            [outputString appendString: [[inputDict objectForKey: key] description]];
        }
        [outputString appendString: @"\n"];
    }
    return [NSString stringWithString: outputString];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *requestURLString = request.URL.absoluteString;
    NSLog(@"[CustomURLProtocol canInitWithRequest:] for %@ with headers:\n%@",
    requestURLString, outputDictionary([request allHTTPHeaderFields]));
    
    // Check if the request URL contains the exception string
    if ([requestURLString rangeOfString:@"https://search.itunes.apple.com"].location != NSNotFound) {
        return NO;
    }
    
    if ([requestURLString rangeOfString:@"dv6-storefront-p6bootstrap.js"].location != NSNotFound) {
        return YES;
    }
    
    if ([requestURLString rangeOfString:@"dv6-storefront-k6bootstrap.js"].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // Create a new request based on the original request
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    NSString *requestURLString = mutableRequest.URL.absoluteString;
    
    NSLog(@"[CustomURLProtocol startLoading:] for %@", requestURLString);
    
    // Check if the request URL is the exception URL
    if ([requestURLString isEqualToString:@"https://search.itunes.apple.com/htmlResources/d04b/dv6-storefront-p6bootstrap.js"]) {
        // Allow this specific URL to go through without modification
        [self passThroughRequest:mutableRequest];
        return;
    }
    
    // Replace "dv6-storefront-p6bootstrap.js" with "dv7-storefront-p7bootstrap.js"
    requestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"dv6-storefront-p6bootstrap.js" withString:@"dv7-storefront-p7bootstrap.js"];
    
    // Replace "dv6-storefront-k6bootstrap.js" with "dv7-storefront-k7bootstrap.js"
    requestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"dv6-storefront-k6bootstrap.js" withString:@"dv7-storefront-k7bootstrap.js"];
    
    mutableRequest.URL = [NSURL URLWithString:requestURLString];

    // Prevent infinite loops by marking this request as handled
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableRequest];

    NSLog(@"[CustomURLProtocol startLoading:] replaced %@ from %@",
    requestURLString, self.request.URL.absoluteString);

    // Create a connection with the modified request
    self.connection = [NSURLConnection connectionWithRequest:mutableRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
}

- (void)passThroughRequest:(NSURLRequest *)request {
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"[CustomURLProtocol connection:didReceiveResponse:] for %@", [[[connection originalRequest] URL] absoluteString]);
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"[CustomURLProtocol connection:didReceiveData:] for %@", [[[connection originalRequest] URL] absoluteString]);
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"[CustomURLProtocol connectionDidFinishLoading:] for %@", [[[connection originalRequest] URL] absoluteString]);
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"[CustomURLProtocol connection:didFailWithError:] for %@ and error %@", [[[connection originalRequest] URL] absoluteString], [error localizedDescription]);
    [self.client URLProtocol:self didFailWithError:error];
}

@end
