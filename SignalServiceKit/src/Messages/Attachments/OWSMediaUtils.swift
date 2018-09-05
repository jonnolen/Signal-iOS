//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import AVFoundation

public enum OWSMediaError: Error {
    case failure(description: String)
}

@objc public class OWSMediaUtils: NSObject {

    @available(*, unavailable, message:"do not instantiate this class.")
    private override init() {
    }

    @objc public class func thumbnail(forImageAtPath path: String, maxDimension: CGFloat) throws -> UIImage {
        guard FileManager.default.fileExists(atPath: path) else {
            throw OWSMediaError.failure(description: "Media file missing.")
        }
        guard NSData.ows_isValidImage(atPath: path) else {
            throw OWSMediaError.failure(description: "Invalid image.")
        }

        guard let originalImage = UIImage(contentsOfFile: path) else {
            throw OWSMediaError.failure(description: "Could not load original image.")
        }
        let originalSize = originalImage.size
        guard originalSize.width > 0 && originalSize.height > 0 else {
            throw OWSMediaError.failure(description: "Original image has invalid size.")
        }
        var thumbnailSize = CGSize.zero
        if originalSize.width > originalSize.height {
            thumbnailSize.width = CGFloat(maxDimension)
            thumbnailSize.height = round(CGFloat(maxDimension) * originalSize.height / originalSize.width)
        } else {
            thumbnailSize.width = round(CGFloat(maxDimension) * originalSize.width / originalSize.height)
            thumbnailSize.height = CGFloat(maxDimension)
        }
        guard thumbnailSize.width > 0 && thumbnailSize.height > 0 else {
            throw OWSMediaError.failure(description: "Thumbnail has invalid size.")
        }
        guard originalSize.width > thumbnailSize.width &&
            originalSize.height > thumbnailSize.height else {
                throw OWSMediaError.failure(description: "Thumbnail isn't smaller than the original.")
        }
        // We use UIGraphicsBeginImageContextWithOptions() to scale.
        // Core Image would provide better quality (e.g. Lanczos) but
        // at perf cost we don't want to pay.  We could also use
        // CoreGraphics directly, but I'm not sure there's any benefit.
        guard let thumbnailImage = originalImage.resizedImage(to: thumbnailSize) else {
            throw OWSMediaError.failure(description: "Could not thumbnail image.")
        }
        return thumbnailImage
    }

//    @objc public class func thumbnail(forImageAtPath path: String, maxDimension : CGFloat) throws -> UIImage {
//        guard FileManager.default.fileExists(atPath: path) else {
//            throw OWSMediaError.failure(description: "Media file missing.")
//        }
//        guard NSData.ows_isValidImage(atPath: path) else {
//            throw OWSMediaError.failure(description: "Invalid image.")
//        }
//        let url = URL(fileURLWithPath: path)
//        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
//            throw OWSMediaError.failure(description: "Could not create image source.")
//        }
//        let imageOptions : [String :Any] = [
//            kCGImageSourceCreateThumbnailFromImageIfAbsent as String: kCFBooleanTrue as NSNumber,
//            kCGImageSourceThumbnailMaxPixelSize as String: maxDimension,
//            kCGImageSourceCreateThumbnailWithTransform as String: kCFBooleanTrue as NSNumber]
//        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, imageOptions as CFDictionary) else {
//            throw OWSMediaError.failure(description: "Could not create image thumbnail.")
//        }
//        let image = UIImage(cgImage: thumbnail)
//        return image
//    }

    private static let kMaxVideoStillSize: CGFloat = 1024

    @objc public class func thumbnail(forVideoAtPath path: String) throws -> UIImage {
        return try thumbnail(forVideoAtPath: path, maxSize: CGSize(width: kMaxVideoStillSize, height: kMaxVideoStillSize))
    }

    @objc public class func thumbnail(forVideoAtPath path: String, maxSize: CGSize) throws -> UIImage {
        var maxSize = maxSize
        maxSize.width = min(maxSize.width, kMaxVideoStillSize)
        maxSize.height = min(maxSize.height, kMaxVideoStillSize)

        guard FileManager.default.fileExists(atPath: path) else {
            throw OWSMediaError.failure(description: "Media file missing.")
        }
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url, options: nil)
        guard isValidVideo(asset: asset) else {
            throw OWSMediaError.failure(description: "Invalid video.")
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = maxSize
        generator.appliesPreferredTrackTransform = true
        let time: CMTime = CMTimeMake(1, 60)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        return image
    }

    @objc public class func isValidVideo(path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else {
            Logger.error("Media file missing.")
            return false
        }
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url, options: nil)
        return isValidVideo(asset: asset)
    }

    private class func isValidVideo(asset: AVURLAsset) -> Bool {
        var maxTrackSize = CGSize.zero
        for track: AVAssetTrack in asset.tracks(withMediaType: .video) {
            let trackSize: CGSize = track.naturalSize
            maxTrackSize.width = max(maxTrackSize.width, trackSize.width)
            maxTrackSize.height = max(maxTrackSize.height, trackSize.height)
        }
        if maxTrackSize.width < 1.0 || maxTrackSize.height < 1.0 {
            Logger.error("Invalid video size: \(maxTrackSize)")
            return false
        }
        let kMaxValidSize: CGFloat = 3 * 1024.0
        if maxTrackSize.width > kMaxValidSize || maxTrackSize.height > kMaxValidSize {
            Logger.error("Invalid video dimensions: \(maxTrackSize)")
            return false
        }
        return true
    }
}
