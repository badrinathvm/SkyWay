// Renders the icons-only image for the "Here's what you'd lose" retention message.
//
// The image has no words, so one PNG serves every language; the feature names live in the
// message body, which App Store Connect translates. Apple's full-size retention images are
// 3840 px wide, 160–2160 px tall, PNG, and opaque.
//
// Usage: swift Scripts/render-retention-image.swift [output.png]

import AppKit
import SwiftUI

struct Feature {
  var symbol: String
  var tile: Color
}

/// In the same order as the message body, so the icons read like a bulleted list.
let features = [
  Feature(symbol: "receipt", tile: Color(red: 0.98, green: 0.82, blue: 0.79)),            // Snap receipts
  Feature(symbol: "sparkle", tile: Color(red: 0.80, green: 0.95, blue: 0.45)),            // Intuit AI
  Feature(symbol: "building.columns", tile: Color(red: 0.66, green: 0.88, blue: 0.99)),   // Bank transactions
  Feature(symbol: "doc.text", tile: Color(red: 0.80, green: 0.76, blue: 0.99)),           // Invoices
  Feature(symbol: "creditcard", tile: Color(red: 1.00, green: 0.88, blue: 0.53)),         // Expenses and bills
  Feature(symbol: "mappin.and.ellipse", tile: Color(red: 0.70, green: 0.93, blue: 0.82)), // Trips
]

let width: CGFloat = 3840
let height: CGFloat = 760
let tileSize: CGFloat = 440
let ink = Color(red: 0.11, green: 0.11, blue: 0.25)

struct FeatureIcons: View {
  var body: some View {
    HStack(spacing: 160) {
      ForEach(features.indices, id: \.self) { index in
        RoundedRectangle(cornerRadius: tileSize * 0.26, style: .continuous)
          .fill(features[index].tile)
          .frame(width: tileSize, height: tileSize)
          .overlay {
            Image(systemName: features[index].symbol)
              .font(.system(size: tileSize * 0.42, weight: .semibold))
              .foregroundStyle(ink)
          }
      }
    }
    .frame(width: width, height: height)
    // A soft neutral rather than pure white, so the image isn't glaring in dark mode.
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
  }
}

@MainActor
func render(to url: URL) throws {
  let renderer = ImageRenderer(content: FeatureIcons())
  renderer.scale = 1
  guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }

  // Redraw without an alpha channel: Apple rejects images with transparency.
  guard let context = CGContext(
    data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  ) else { throw CocoaError(.fileWriteUnknown) }
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  guard let opaque = context.makeImage(),
    let png = NSBitmapImageRep(cgImage: opaque).representation(using: .png, properties: [:])
  else { throw CocoaError(.fileWriteUnknown) }
  try png.write(to: url)
}

let output = CommandLine.arguments.dropFirst().first ?? "Docs/RetentionAssets/feature-icons.png"
let url = URL(fileURLWithPath: output)
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
try MainActor.assumeIsolated { try render(to: url) }
print("Wrote \(output)")
