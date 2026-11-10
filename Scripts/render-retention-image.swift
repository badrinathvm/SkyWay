// Builds the "Here's what you'd lose" retention message assets from Docs/RetentionAssets:
//
// 1. Renders the icons-only image, feature-icons.png. It has no words, so one PNG serves every
//    language. Apple's full-size retention images are 3840 px wide, 160–2160 px tall, PNG, and opaque.
// 2. Checks each language in messages.json against Apple's limits: header 66, body 144, and
//    alt text 150 characters.
// 3. Renders Previews/<locale>.png, showing each language the way the "From the Developer" card
//    lays it out, for reviewing with translators. Previews are for checking only; don't upload them.
//
// Usage: swift Scripts/render-retention-image.swift [--check-only]
// Exits with status 1 if any text is over a limit.

import AppKit
import SwiftUI

// MARK: Icons

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

// MARK: Message text

struct MessageCopy: Decodable {
  var locale: String
  var header: String
  var body: String
  var altText: String
}

/// A text field and Apple's maximum length for it.
struct Field {
  var name: String
  var text: String
  var limit: Int

  var count: Int { text.count }
  var fits: Bool { count <= limit }
}

extension MessageCopy {
  var fields: [Field] {
    [
      Field(name: "Header", text: header, limit: 66),
      Field(name: "Body", text: body, limit: 144),
      Field(name: "Alt text", text: altText, limit: 150),
    ]
  }

  var fits: Bool { fields.allSatisfy(\.fits) }
}

// MARK: Previews

/// One language's message, laid out like the "From the Developer" card, with its character counts.
struct MessagePreview: View {
  var copy: MessageCopy
  var image: CGImage

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(copy.locale)
          .font(.system(size: 15, weight: .bold))
        Spacer()
        Text(copy.fits ? "Fits Apple's limits" : "Over a limit")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(copy.fits ? Color.green : Color.red)
      }

      VStack(alignment: .leading, spacing: 0) {
        Text("From the Developer")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
          .padding(.vertical, 9)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(white: 0.94))

        VStack(alignment: .leading, spacing: 10) {
          Image(decorative: image, scale: 1)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(.rect(cornerRadius: 10))
          Text(copy.header)
            .font(.system(size: 17, weight: .semibold))
          Text(copy.body)
            .font(.system(size: 15))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
      }
      .background(.white)
      .clipShape(.rect(cornerRadius: 18))
      .overlay {
        RoundedRectangle(cornerRadius: 18).strokeBorder(Color(white: 0.85), lineWidth: 1)
      }

      VStack(alignment: .leading, spacing: 4) {
        ForEach(copy.fields, id: \.name) { field in
          HStack {
            Text(field.name)
            Spacer()
            Text("\(field.count) / \(field.limit)")
              .monospacedDigit()
              .foregroundStyle(field.fits ? Color.secondary : Color.red)
          }
        }
        Text("Alt text (read by VoiceOver): \(copy.altText)")
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 4)
      }
      .font(.system(size: 12))
    }
    .padding(20)
    .frame(width: 390)
    .background(Color(white: 0.97))
    .environment(\.colorScheme, .light)
  }
}

// MARK: Rendering

enum RenderError: Error {
  case renderFailed(String)
}

/// Renders a view to a PNG without an alpha channel: Apple rejects images with transparency.
@MainActor
func writeOpaquePNG(of view: some View, scale: CGFloat, to url: URL) throws -> CGImage {
  let renderer = ImageRenderer(content: view)
  renderer.scale = scale
  guard let image = renderer.cgImage else { throw RenderError.renderFailed(url.lastPathComponent) }

  guard let context = CGContext(
    data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  ) else { throw RenderError.renderFailed(url.lastPathComponent) }
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  guard let opaque = context.makeImage(),
    let png = NSBitmapImageRep(cgImage: opaque).representation(using: .png, properties: [:])
  else { throw RenderError.renderFailed(url.lastPathComponent) }

  try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try png.write(to: url)
  return opaque
}

// MARK: Main

@MainActor
func run() throws -> Bool {
  let folderPath = "Docs/RetentionAssets"
  let folder = URL(fileURLWithPath: folderPath)
  let checkOnly = CommandLine.arguments.contains("--check-only")

  let data = try Data(contentsOf: folder.appending(path: "messages.json"))
  let messages = try JSONDecoder().decode([MessageCopy].self, from: data)

  print("Checking \(messages.count) languages against Apple's limits")
  for copy in messages {
    let counts = copy.fields.map { "\($0.name) \($0.count)/\($0.limit)\($0.fits ? "" : " ✗")" }
    print("  \(copy.fits ? "✓" : "✗") \(copy.locale.padding(toLength: 6, withPad: " ", startingAt: 0))  \(counts.joined(separator: "  "))")
  }
  let allFit = messages.allSatisfy(\.fits)
  guard !checkOnly else { return allFit }

  let image = try writeOpaquePNG(of: FeatureIcons(), scale: 1, to: folder.appending(path: "feature-icons.png"))
  print("Wrote \(folderPath)/feature-icons.png (\(image.width) × \(image.height))")

  for copy in messages {
    let url = folder.appending(path: "Previews/\(copy.locale).png")
    _ = try writeOpaquePNG(of: MessagePreview(copy: copy, image: image), scale: 3, to: url)
    print("Wrote \(folderPath)/Previews/\(copy.locale).png")
  }
  return allFit
}

let allFit = try MainActor.assumeIsolated { try run() }
if !allFit {
  print("Some text is over Apple's limits. Shorten it in messages.json.")
  exit(1)
}
