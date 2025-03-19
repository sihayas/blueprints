//
//  MKSymbolShape.swift
//  blueprints
//
//  Created by decoherence on 3/13/25.
//

import SwiftUI
import Vision

/// Takes an input image, turns it black and white, and returns a
/// path that can be used to trace the contours of the image
struct MKSymbolShape: InsettableShape {
    var insetAmount = 0.0
    let imageName: String
    
    var trimmedImage: UIImage {
        // Load the image asset named "xcode"
        guard let imgA = UIImage(named: imageName)?.withTintColor(.black, renderingMode: .alwaysOriginal) else {
            fatalError("Could not load image asset: \(imageName)!")
        }
        
        // Get a cgRef from imgA
        guard let cgRef = imgA.cgImage else {
            fatalError("Could not get cgImage!")
        }
        // Create imgB from the cgRef
        let imgB = UIImage(cgImage: cgRef, scale: imgA.scale, orientation: imgA.imageOrientation)
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        
        // Render it on a white background
        let resultImage = UIGraphicsImageRenderer(size: imgB.size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: imgB.size))
            imgB.draw(at: .zero)
        }
        
        return resultImage
    }
    
    func path(in rect: CGRect) -> Path {
        // cgPath returned from Vision will be in rect 0,0 1.0,1.0 coordinates
        // so we want to scale the path to our view bounds
        
        guard let cgPath = detectVisionContours(from: trimmedImage) else { return Path() }
        
        let scW: CGFloat = (rect.width - CGFloat(insetAmount)) / cgPath.boundingBox.width
        let scH: CGFloat = (rect.height - CGFloat(insetAmount)) / cgPath.boundingBox.height
        
        // We need to invert the Y-coordinate space
        var transform = CGAffineTransform.identity
            .scaledBy(x: scW, y: -scH)
            .translatedBy(x: 0.0, y: -cgPath.boundingBox.height)
        
        if let imagePath = cgPath.copy(using: &transform) {
            return Path(imagePath)
        } else {
            return Path()
        }
    }
    
    func detectVisionContours(from sourceImage: UIImage) -> CGPath? {
        let inputImage = CIImage(cgImage: sourceImage.cgImage!)
        
        let contourRequest = VNDetectContoursRequest()
        contourRequest.revision = VNDetectContourRequestRevision1
        contourRequest.contrastAdjustment = 1.0
        contourRequest.maximumImageDimension = 256
        
        let requestHandler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        try! requestHandler.perform([contourRequest])
        if let contoursObservation = contourRequest.results?.first {
            return contoursObservation.normalizedPath
        }
        
        return nil
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

struct MKSymbolSystemShape: InsettableShape {
    var insetAmount = 0.0
    let systemImageName: String
    
    var trimmedImage: UIImage {
        // Load the system image
        guard let imgA = UIImage(systemName: systemImageName)?.withTintColor(.black, renderingMode: .alwaysOriginal) else {
            fatalError("Could not load system image: \(systemImageName)!")
        }
        
        // Get a cgRef from imgA
        guard let cgRef = imgA.cgImage else {
            fatalError("Could not get cgImage!")
        }
        // Create imgB from the cgRef
        let imgB = UIImage(cgImage: cgRef, scale: imgA.scale, orientation: imgA.imageOrientation)
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        
        // Render it on a white background
        let resultImage = UIGraphicsImageRenderer(size: imgB.size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: imgB.size))
            imgB.draw(at: .zero)
        }
        
        return resultImage
    }
    
    func path(in rect: CGRect) -> Path {
        // cgPath returned from Vision will be in rect 0,0 1.0,1.0 coordinates
        // so we want to scale the path to our view bounds
        
        guard let cgPath = detectVisionContours(from: trimmedImage) else { return Path() }
        
        let scW: CGFloat = (rect.width - CGFloat(insetAmount)) / cgPath.boundingBox.width
        let scH: CGFloat = (rect.height - CGFloat(insetAmount)) / cgPath.boundingBox.height
        
        // We need to invert the Y-coordinate space
        var transform = CGAffineTransform.identity
            .scaledBy(x: scW, y: -scH)
            .translatedBy(x: 0.0, y: -cgPath.boundingBox.height)
        
        if let imagePath = cgPath.copy(using: &transform) {
            return Path(imagePath)
        } else {
            return Path()
        }
    }
    
    func detectVisionContours(from sourceImage: UIImage) -> CGPath? {
        let inputImage = CIImage(cgImage: sourceImage.cgImage!)
        
        let contourRequest = VNDetectContoursRequest()
        contourRequest.revision = VNDetectContourRequestRevision1
        contourRequest.contrastAdjustment = 1.0
        contourRequest.maximumImageDimension = 256
        
        let requestHandler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        try! requestHandler.perform([contourRequest])
        if let contoursObservation = contourRequest.results?.first {
            return contoursObservation.normalizedPath
        }
        
        return nil
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
