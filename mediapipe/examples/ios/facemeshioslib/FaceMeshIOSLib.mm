// Copyright 2021 Switt Kongdachalert

#import "FaceMeshIOSLib.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPGraph.h"

// NormalizedLandmarkList won't be defined unless we import this header (following FaceMeshGpuViewController's imports)
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"

//#import "mediapipe/objc/MPPLayerRenderer.h"

// The graph name specified is supposed to be the same as in the pb file (binarypb?)
static NSString* const kGraphName = @"pure_face_mesh_mobile_gpu";

// The input node's name
static const char* kInputStream = "input_video";
//static const char* kMemesOutputStream = "memes";

static const char* kNumFacesInputSidePacket = "num_faces";
static const char* kLandmarksOutputStream = "multi_face_landmarks";
static const char* kFaceRectsOutputStream = "face_rects_from_landmarks";

// Max number of faces to detect/process.
static const int kNumFaces = 1;


@interface FaceMeshIOSLib () <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@end

@implementation FaceMeshIOSLib {
}

#pragma mark - Cleanup methods

- (void)dealloc {
  self.mediapipeGraph.delegate = nil;
  [self.mediapipeGraph cancel];
  // Ignore errors since we're cleaning up.
  [self.mediapipeGraph closeAllInputStreamsWithError:nil];
  [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
  // Load the graph config resource.
  NSError* configLoadError = nil;
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  if (!resource || resource.length == 0) {
    return nil;
  }
  NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
  NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
  if (!data) {
    NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
    return nil;
  }

  // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
  mediapipe::CalculatorGraphConfig config;
  config.ParseFromArray(data.bytes, data.length);

  // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
  MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
  
  // Set graph configurations
  [newGraph setSidePacket:(mediapipe::MakePacket<int>(kNumFaces))
                              named:kNumFacesInputSidePacket];
  [newGraph addFrameOutputStream:kLandmarksOutputStream
                          outputPacketType:MPPPacketTypeRaw];
  return newGraph;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
    self.mediapipeGraph.delegate = self;
    
    // // Set maxFramesInFlight to a small value to avoid memory contention
    // // for real-time processing.
    // self.mediapipeGraph.maxFramesInFlight = 2;
    NSLog(@"inited graph %@", kGraphName);
  }
  return self;
}

- (void)startGraph {
  NSError* error;
  if (![self.mediapipeGraph startWithError:&error]) {
    NSLog(@"Failed to start graph: %@", error);
  }
  NSLog(@"Started graph %@", kGraphName);
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
    didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
              fromStream:(const std::string&)streamName {
  NSLog(@"recv pixelBuffer from %@", @(streamName.c_str()));
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
//- (void)mediapipeGraph:(MPPGraph*)graph
//       didOutputPacket:(const ::mediapipe::Packet&)packet
//            fromStream:(const std::string&)streamName {
//  NSLog(@"recv packet @%@ from %@", @(packet.Timestamp().DebugString().c_str()),
//        @(streamName.c_str()));
//  if (streamName == kMemesOutputStream) {
//    if (packet.IsEmpty()) {
//      return;
//    }
//    const auto& memes = packet.Get<std::vector<::mediapipe::Classification>>();
//    if (memes.empty()) {
//      return;
//    }
//    NSMutableArray<Classification*>* result = [NSMutableArray array];
//    for (const auto& meme : memes) {
//      auto* c = [[Classification alloc] init];
//      if (c) {
//        c.index = meme.index();
//        c.score = meme.score();
//        c.label = @(meme.label().c_str());
//        NSLog(@"\tmeme %f: %@", c.score, c.label);
//        [result addObject:c];
//      }
//    }
//    NSLog(@"calling didReceive with %lu memes", memes.size());
//    [_delegate didReceive:result];
//  }
//}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
     didOutputPacket:(const ::mediapipe::Packet&)packet
          fromStream:(const std::string&)streamName {
  if (streamName == kLandmarksOutputStream) {
    if (packet.IsEmpty()) {
      NSLog(@"[TS:%lld] No face landmarks", packet.Timestamp().Value());
      if([self.delegate respondsToSelector:@selector(didReceiveFaces:)]) {
        [self.delegate didReceiveFaces:@[]];
      }
      return;
    }
    const auto& multi_face_landmarks = packet.Get<std::vector<::mediapipe::NormalizedLandmarkList>>();
    NSLog(@"[TS:%lld] Number of face instances with landmarks: %lu", packet.Timestamp().Value(),
          multi_face_landmarks.size());
    NSMutableArray <NSArray <FaceMeshIOSLibFaceLandmarkPoint *>*>*faceLandmarks = [NSMutableArray new];
    
    for (int face_index = 0; face_index < multi_face_landmarks.size(); ++face_index) {
      NSMutableArray *thisFaceLandmarks = [NSMutableArray new];
      const auto& landmarks = multi_face_landmarks[face_index];
//      NSLog(@"\tNumber of landmarks for face[%d]: %d", face_index, landmarks.landmark_size());
      for (int i = 0; i < landmarks.landmark_size(); ++i) {
//        NSLog(@"\t\tLandmark[%d]: (%f, %f, %f)", i, landmarks.landmark(i).x(),
//              landmarks.landmark(i).y(), landmarks.landmark(i).z());
        FaceMeshIOSLibFaceLandmarkPoint *obj_landmark = [FaceMeshIOSLibFaceLandmarkPoint new];
        obj_landmark.x = landmarks.landmark(i).x();
        obj_landmark.y = landmarks.landmark(i).y();
        obj_landmark.z = landmarks.landmark(i).z();
        [thisFaceLandmarks addObject:obj_landmark];
      }
      [faceLandmarks addObject:thisFaceLandmarks];
    }
    if([self.delegate respondsToSelector:@selector(didReceiveFaces:)]) {
      [self.delegate didReceiveFaces:faceLandmarks];
    }
  }
  else if (streamName == kFaceRectsOutputStream) {
    if (packet.IsEmpty()) {
      return;
    }
    const auto& face_rects_from_landmarks = packet.Get<std::vector<::mediapipe::NormalizedRect>>();
    for (int face_index = 0; face_index < face_rects_from_landmarks.size(); ++face_index) {
      const auto& face = face_rects_from_landmarks[face_index];
      float centerX = face.x_center();
      float centerY = face.y_center();
      float height = face.height();
      float width = face.width();
      float rotation = face.rotation();
    }
    // TODO: MAYBE MAKE A DELEGATE METHOD HERE.
  }
}


#pragma mark - MPPInputSourceDelegate methods

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
  const auto ts =
      mediapipe::Timestamp(self.timestamp++ * mediapipe::Timestamp::kTimestampUnitsPerSecond);
  NSError* err = nil;
  NSLog(@"sending imageBuffer @%@ to %s", @(ts.DebugString().c_str()), kInputStream);
  auto sent = [self.mediapipeGraph sendPixelBuffer:imageBuffer
                                        intoStream:kInputStream
                                        packetType:MPPPacketTypePixelBuffer
                                         timestamp:ts
                                    allowOverwrite:NO
                                             error:&err];
  NSLog(@"imageBuffer %s", sent ? "sent!" : "not sent.");
  if (err) {
    NSLog(@"sendPixelBuffer error: %@", err);
  }
}

@end


@implementation FaceMeshIOSLibFaceLandmarkPoint
@end
