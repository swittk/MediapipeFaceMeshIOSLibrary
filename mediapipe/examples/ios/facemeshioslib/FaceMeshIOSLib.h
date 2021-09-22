// Copyright 2021 Switt Kongdachalert

#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

@interface FaceMeshIOSLibFaceLandmarkPoint : NSObject
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@end

@interface FaceMeshIOSLibNormalizedRect : NSObject
@property (nonatomic) float centerX;
@property (nonatomic) float centerY;
@property (nonatomic) float height;
@property (nonatomic) float width;
@property (nonatomic) float rotation;
@end

@protocol FaceMeshIOSLibDelegate <NSObject>
@optional
/** 
 * Array of faces, with faces represented by arrays of face landmarks 
*/
- (void)didReceiveFaces:(NSArray <NSArray<FaceMeshIOSLibFaceLandmarkPoint *>*>*)faces;
/** 
 * Array of faces, with faces represented by arrays of face landmarks 
*/
- (void)didReceiveFaceBoxes:(NSArray <FaceMeshIOSLibNormalizedRect *>*)faces;
@end

@interface FaceMeshIOSLib : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property(weak, nonatomic) id<FaceMeshIOSLibDelegate> delegate;
@property(nonatomic) size_t timestamp;
@end
