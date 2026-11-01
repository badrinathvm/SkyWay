import Foundation
import SwiftData

/// A trip as the backend stores it. While there's no server yet, `SwiftDataTripBackend` keeps
/// these in a SwiftData store on the iPhone, playing the part of the server's database.
///
/// This is a separate type from `DriveTrip` on purpose: it's the shape of the *backend's* data,
/// which usually differs from the app's (flattened fields, a received date, no display text).
/// When the real server exists, this type and its store can be deleted.
@Model
final class SyncedTripRecord {
  /// The app's `DriveTrip.id`. Unique, so uploading the same trip twice updates one record.
  @Attribute(.unique) var tripID: UUID
  var startDate: Date
  var endDate: Date?
  var miles: Double
  /// `DriveTrip.Purpose.rawValue`: "business" or "personal", as it would travel in JSON.
  var purpose: String?
  var startAddress: String?
  var endAddress: String?
  var startLatitude: Double?
  var startLongitude: Double?
  var endLatitude: Double?
  var endLongitude: Double?
  /// When the backend last received this trip, which a server would set itself.
  var receivedAt: Date

  init(trip: DriveTrip, receivedAt: Date = .now) {
    tripID = trip.id
    startDate = trip.startDate
    miles = trip.miles
    self.receivedAt = receivedAt
    update(from: trip, receivedAt: receivedAt)
  }

  /// Copies every field from the app's trip, for both a new record and a repeat upload.
  func update(from trip: DriveTrip, receivedAt: Date = .now) {
    startDate = trip.startDate
    endDate = trip.endDate
    miles = trip.miles
    purpose = trip.purpose?.rawValue
    startAddress = trip.startAddress
    endAddress = trip.endAddress
    startLatitude = trip.start?.latitude
    startLongitude = trip.start?.longitude
    endLatitude = trip.end?.latitude
    endLongitude = trip.end?.longitude
    self.receivedAt = receivedAt
  }
}
