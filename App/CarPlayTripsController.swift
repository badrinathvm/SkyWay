import CarPlay
import MapKit

/// The Trips tab: start a mileage trip, follow it on a map as its miles and deduction add up,
/// end it as business or personal, and look back at recent trips.
@MainActor
final class CarPlayTripsController: NSObject {
  let rootTemplate: CPListTemplate
  private weak var interfaceController: CPInterfaceController?
  private let store = DriveTripStore.shared
  private var mapTemplate: CPPointOfInterestTemplate?
  /// When the driver opened the car's card, which a refresh would close.
  private var cardOpenedAt: Date?
  private var refreshTimer: Timer?
  private var shownListText: [String] = []
  private var isEnding = false

  /// `carScreenHeight` is the car display's height in points, from the scene's `carWindow`.
  /// Car screens range from short, wide strips to tall portrait displays, so it decides how
  /// many recent trips to fetch.
  init(interfaceController: CPInterfaceController, carScreenHeight: CGFloat) {
    self.interfaceController = interfaceController
    store.recentTripLimit = Self.recentTripLimit(forScreenHeight: carScreenHeight)
    rootTemplate = CPListTemplate(title: "Trips", sections: [])
    rootTemplate.tabTitle = "Trips"
    rootTemplate.tabImage = UIImage(systemName: "car.fill")
    super.init()
    refreshList()
  }

  /// Call once the Trips tab is on screen.
  func didConnect() {
    store.resumeTrackingIfNeeded()
    store.syncPendingTrips()
    // Pick up trips uploaded since the car was last connected, including from other devices once
    // there's a real server.
    store.refreshRecentTrips()
    if store.activeTrip != nil {
      showMap(animated: false)
    }
    // CarPlay templates aren't observable views, so poll: this keeps the trip current
    // and picks up trips started or ended with Siri.
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.refresh() }
    }
  }

  func didDisconnect() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    mapTemplate = nil
  }

  private func refresh() {
    refreshList()
    if store.isLocationDenied {
      showLocationAlert()
    } else if store.activeTrip == nil, mapTemplate != nil, !isEnding {
      leaveMap()
    } else {
      refreshMap()
    }
  }

  // MARK: - List

  private func refreshList() {
    let startItem: CPListItem
    if let trip = store.activeTrip {
      startItem = CPListItem(
        text: "Trip in progress · \(trip.milesText)",
        detailText: "Started \(trip.startTimeText) · \(trip.estimatedDeductionText) est.",
        image: Self.statusDot
      )
    } else {
      startItem = CPListItem(
        text: "Start a Trip",
        detailText: "Tracks miles from where you are now",
        image: Self.icon("play.fill", .systemBlue)
      )
    }
    startItem.accessoryType = .disclosureIndicator
    startItem.handler = { [weak self] _, completion in
      self?.startOrShowTrip()
      completion()
    }

    let recentItems = store.recentTrips.map { trip in
      let item = CPListItem(
        text: trip.routeText,
        detailText: trip.summaryText,
        image: trip.purpose == .business ? Self.icon("briefcase.fill", .systemBrown) : Self.icon("car.fill", .systemRed)
      )
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        self?.showDetails(of: trip)
        completion()
      }
      return item
    }

    // Only replace the sections when something changed, so the list doesn't flicker every refresh.
    let listText = ([startItem] + recentItems).flatMap { [$0.text ?? "", $0.detailText ?? ""] }
    guard listText != shownListText else { return }
    shownListText = listText

    var sections = [CPListSection(items: [startItem])]
    if !recentItems.isEmpty {
      sections.append(CPListSection(items: recentItems, header: "Recent Trips", sectionIndexTitle: nil))
    }
    rootTemplate.updateSections(sections)
  }

  /// Six recent trips when the screen has room to show them, five otherwise.
  ///
  /// CarPlay doesn't say how tall its rows are, so this estimates how many trip rows fit below
  /// the navigation bar, the Start a Trip row, and the Recent Trips header. On the common
  /// 800×480 screen that's about 7, so it shows 6; on a short 360-point screen about 4, so it
  /// still shows 5 and the driver scrolls for the last one. More than 6 isn't worth the
  /// glances it takes to read while driving.
  private static func recentTripLimit(forScreenHeight height: CGFloat) -> Int {
    let navigationBarHeight = 44.0
    let startRowHeight = 44.0
    let sectionHeaderHeight = 28.0
    let tripRowHeight = 50.0  // two lines of text
    let fittingRows = Int((height - navigationBarHeight - startRowHeight - sectionHeaderHeight) / tripRowHeight)
    return min(max(fittingRows, 5), 6)
  }

  /// CarPlay draws text and symbol images in its own colors, so draw the symbol into a plain
  /// bitmap, which keeps the color.
  private static func icon(_ systemName: String, _ color: UIColor) -> UIImage? {
    let configuration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
    guard let symbol = UIImage(systemName: systemName, withConfiguration: configuration)?
      .withTintColor(color, renderingMode: .alwaysOriginal) else { return nil }
    return UIGraphicsImageRenderer(size: symbol.size).image { _ in
      symbol.draw(at: .zero)
    }
  }

  /// A small green light, like the mockup's, centered in a full-size row image so it isn't scaled up.
  private static let statusDot = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { _ in
    UIColor.systemGreen.setFill()
    UIBezierPath(ovalIn: CGRect(x: 12, y: 12, width: 16, height: 16)).fill()
  }

  private func startOrShowTrip() {
    if store.activeTrip == nil {
      store.startTrip()
      refreshList()
    }
    showMap(animated: true)
  }

  // MARK: - Trip in progress

  /// The trip in progress: the car on a map, its totals in the side panel, and End Trip in the
  /// navigation bar, so ending a trip is always one tap.
  private func showMap(animated: Bool) {
    // Back pops the map without telling this controller, so check what's actually showing.
    if let mapTemplate, interfaceController?.topTemplate === mapTemplate { return }
    let points = carPoints()
    let template = CPPointOfInterestTemplate(title: "Trip in Progress", pointsOfInterest: points, selectedIndex: NSNotFound)
    template.pointOfInterestDelegate = self
    // Always reachable, even before the first location fix puts the car on the map.
    template.trailingNavigationBarButtons = [
      CPBarButton(title: "End Trip") { [weak self] _ in self?.confirmEnd() },
    ]
    mapTemplate = template
    interfaceController?.pushTemplate(template, animated: animated, completion: nil)
  }

  private func refreshMap() {
    guard let mapTemplate else { return }
    // Replacing the points closes the car's card, and CarPlay only redraws a point when it's
    // replaced, so hold the card open for a while to give the driver time to tap End Trip.
    if let cardOpenedAt, Date.now.timeIntervalSince(cardOpenedAt) < 30 { return }
    cardOpenedAt = nil
    // Leave it unselected: selecting from code only highlights the row, and CarPlay may report
    // it as the driver opening the card.
    mapTemplate.setPointsOfInterest(carPoints(), selectedIndex: NSNotFound)
  }

  /// Just the car: every point also gets a row in the side panel, and one trip should read as one row.
  private func carPoints() -> [CPPointOfInterest] {
    guard let trip = store.activeTrip, let current = store.currentLocation else { return [] }
    // An emoji keeps its color where CarPlay text can't, standing in for a status light.
    // Short enough to fit the side panel's row; End Trip sits in the navigation bar.
    let status = if store.isParked {
      "🟢 Parked"
    } else if store.lastMovedAt == nil {
      "🟢 Trip in progress"
    } else {
      "🟢 Driving"
    }
    let point = CPPointOfInterest(
      location: MKMapItem(location: current, address: nil),
      title: "\(trip.milesText) · \(trip.estimatedDeductionText) est.",
      subtitle: "\(status) · \(trip.minutesText())",
      summary: "From \(trip.startAddress ?? "your start")",
      detailTitle: "\(trip.milesText) · \(trip.estimatedDeductionText) est.",
      detailSubtitle: "Started \(trip.startTimeText) · \(trip.minutesText())",
      detailSummary: "\(status)\nFrom \(trip.startAddress ?? "your start")",
      pinImage: UIImage(systemName: "car.fill")
    )
    point.primaryButton = CPTextButton(title: "End Trip", textStyle: .confirm) { [weak self] _ in
      self?.confirmEnd()
    }
    return [point]
  }

  private func leaveMap() {
    mapTemplate = nil
    interfaceController?.popToRootTemplate(animated: true, completion: nil)
  }

  // MARK: - Ending

  private func confirmEnd() {
    guard store.activeTrip != nil, !isEnding else { return }
    isEnding = true
    Task { [weak self] in
      guard let self else { return }
      let address = await store.endingAddress()
      guard var trip = store.activeTrip else {
        isEnding = false
        return
      }
      // The car may still be moving while the sheet is up, so save the totals it shows.
      let endDate = Date.now
      trip.endDate = endDate
      let business = CPAlertAction(title: "Business (\(trip.estimatedDeductionText))", style: .default) { [weak self] _ in
        self?.finish(as: .business, miles: trip.miles, endDate: endDate)
      }
      let personal = CPAlertAction(title: "Personal", style: .default) { [weak self] _ in
        self?.finish(as: .personal, miles: trip.miles, endDate: endDate)
      }
      let keepDriving = CPAlertAction(title: "Keep Driving", style: .cancel) { [weak self] _ in
        self?.isEnding = false
        self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
      }
      let message = [address.map { "Ended at \($0)." }, "Was this trip for business?"]
        .compactMap { $0 }
        .joined(separator: " ")
      let sheet = CPActionSheetTemplate(
        title: "Trip Ended · \(trip.milesText) · \(trip.minutesText())",
        message: message,
        actions: [business, personal, keepDriving]
      )
      interfaceController?.presentTemplate(sheet, animated: true, completion: nil)
    }
  }

  private func finish(as purpose: DriveTrip.Purpose, miles: Double, endDate: Date) {
    interfaceController?.dismissTemplate(animated: true, completion: nil)
    store.endTrip(as: purpose, miles: miles, endDate: endDate)
    isEnding = false
    leaveMap()
    refreshList()
  }

  private func showLocationAlert() {
    store.isLocationDenied = false
    if mapTemplate != nil {
      leaveMap()
    }
    let ok = CPAlertAction(title: "OK", style: .cancel) { [weak self] _ in
      self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
    }
    let alert = CPAlertTemplate(
      titleVariants: ["Allow Location on iPhone to Track Miles", "Allow Location on iPhone"],
      actions: [ok]
    )
    interfaceController?.presentTemplate(alert, animated: true, completion: nil)
  }

  // MARK: - Details

  private func showDetails(of trip: DriveTrip) {
    let time = Date.FormatStyle(date: .omitted, time: .shortened)
    let range = [trip.startDate.formatted(time), trip.endDate?.formatted(time)].compactMap { $0 }.joined(separator: " – ")
    let template = CPInformationTemplate(
      title: "Trip Details",
      layout: .twoColumn,
      items: [
        CPInformationItem(title: "Date", detail: "\(trip.startDate.formatted(date: .abbreviated, time: .omitted)), \(range)"),
        CPInformationItem(title: "Distance", detail: trip.milesText),
        CPInformationItem(title: "From", detail: trip.startAddress ?? "Unknown"),
        CPInformationItem(title: "To", detail: trip.endAddress ?? "Unknown"),
        CPInformationItem(title: "Purpose", detail: trip.purpose?.title ?? "Not set"),
        CPInformationItem(title: "Deduction", detail: trip.purpose == .business ? "\(trip.deductionText) at $0.16/mi" : trip.deductionText),
      ],
      actions: []
    )
    interfaceController?.pushTemplate(template, animated: true, completion: nil)
  }
}

extension CarPlayTripsController: CPPointOfInterestTemplateDelegate {
  nonisolated func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {
    // The pins follow the trip, not the visible region, so there's nothing to reload.
  }

  nonisolated func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest) {
    // CarPlay may call this off the main thread, so hop to it rather than assume.
    let openedAt = Date.now
    Task { @MainActor [weak self] in
      self?.cardOpenedAt = openedAt
    }
  }
}
