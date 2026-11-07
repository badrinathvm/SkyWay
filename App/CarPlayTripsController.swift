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
  private var followTimer: Timer?
  /// Where the car was when the map was made.
  private var mapCenter: CLLocation?
  /// Where the car's point sits, which is where CarPlay centered the map. It's offset from the
  /// car so the car shows in the open part of the map; see `focus(for:)`.
  private var mapFocus: CLLocation?
  /// Where the car was when the map before this one was made, for its heading.
  private var previousMapCenter: CLLocation?
  /// When the current map was made, so the regions CarPlay reports while framing it aren't
  /// mistaken for the driver panning.
  private var mapMadeAt: Date?
  /// The part of the map the driver can see, beside the side panel, as CarPlay reported it.
  private var visibleRegion: MKCoordinateRegion?
  /// How far the visible part's center sits from the car's point, in map points, measured from
  /// the last map. CarPlay centers the point on the whole map, panel included, so this says
  /// where to put the point to land the car where it should be in the visible part.
  private var pointToVisibleCenter: (x: Double, y: Double)?
  /// When the driver last panned or zoomed the map, which following waits out.
  private var driverMovedMapAt: Date?
  private var shownListText: [String] = []
  /// Opens a URL on the car's screen, such as Apple Maps or Google Maps, then reports whether it could.
  private let openURL: (URL, @escaping @MainActor (Bool) -> Void) -> Void
  private var isEnding = false

  /// `carScreenHeight` is the car display's height in points. Car screens range from short, wide
  /// strips to tall portrait displays, so it decides how many recent trips to fetch.
  init(interfaceController: CPInterfaceController, carScreenHeight: CGFloat, openURL: @escaping (URL, @escaping @MainActor (Bool) -> Void) -> Void) {
    self.interfaceController = interfaceController
    self.openURL = openURL
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
    // CarPlay frames the map only when it's made, so check often whether the car is
    // nearing the edge.
    followTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.followCar() }
    }
  }

  func didDisconnect() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    followTimer?.invalidate()
    followTimer = nil
    mapTemplate = nil
    mapCenter = nil
    mapFocus = nil
    previousMapCenter = nil
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
    mapFocus = store.currentLocation.map { focus(for: $0) }
    mapCenter = store.currentLocation
    mapMadeAt = .now
    visibleRegion = nil
    let points = carPoints()
    let template = CPPointOfInterestTemplate(title: "Trip in Progress", pointsOfInterest: points, selectedIndex: NSNotFound)
    template.pointOfInterestDelegate = self
    // Always reachable, even before the first location fix puts the car on the map.
    template.trailingNavigationBarButtons = [
      CPBarButton(title: "End Trip") { [weak self] _ in self?.confirmEnd() },
    ]
    // Maps apps turn the map with the car, which this template can't. The trip keeps counting
    // in the background, and its Live Activity keeps the miles in view on the CarPlay screen.
    template.leadingNavigationBarButtons = [
      CPBarButton(image: UIImage(systemName: "map.fill") ?? UIImage()) { [weak self] _ in self?.chooseMapsApp() },
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

  /// Keeps the location dot on screen while driving.
  ///
  /// The Point of Interest template has no way to move or rotate its map, which only Navigation
  /// apps' map template has, and replacing its points doesn't move it either. It frames the map
  /// when it's made, so once the car nears the edge of what the driver can see, swap in a new
  /// map. Each swap redraws the map, so it waits as long as it can: `focus(for:)` starts the car
  /// near the trailing edge, so it crosses most of the map first. Not while the card is open,
  /// so End Trip stays put, and not right after the driver pans or zooms.
  private func followCar() {
    guard let mapTemplate, interfaceController?.topTemplate === mapTemplate, !isEnding,
          let current = store.currentLocation else { return }
    if let cardOpenedAt, Date.now.timeIntervalSince(cardOpenedAt) < 30 { return }
    if let driverMovedMapAt, Date.now.timeIntervalSince(driverMovedMapAt) < 15 { return }
    // A map made before the first location fix has nothing to frame, so CarPlay shows a
    // wide default view; swap it as soon as there's a car to center on.
    guard let mapCenter else { return swapMap() }
    if let visibleRegion, Self.isStreetLevel(visibleRegion) {
      if Self.contains(visibleRegion, current.coordinate, margin: Self.edgeMargin) { return }
    } else if current.distance(from: mapCenter) < 120 {
      // CarPlay hasn't said what's visible, or the driver zoomed out, so fall back to swapping
      // every block.
      return
    }
    swapMap()
  }

  private func swapMap() {
    driverMovedMapAt = nil
    previousMapCenter = mapCenter
    interfaceController?.popTemplate(animated: false) { [weak self] _, _ in
      MainActor.assumeIsolated {
        self?.mapTemplate = nil
        self?.showMap(animated: false)
      }
    }
  }

  /// Just the car: every point also gets a row in the side panel, and one trip should read as one row.
  /// Its pin is invisible, because the map's own location dot already shows where the car is.
  private func carPoints() -> [CPPointOfInterest] {
    guard let trip = store.activeTrip, let current = mapFocus ?? store.currentLocation else { return [] }
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
      pinImage: Self.invisiblePin
    )
    point.primaryButton = CPTextButton(title: "End Trip", textStyle: .confirm) { [weak self] _ in
      self?.confirmEnd()
    }
    return [point]
  }

  /// Where to put the car's invisible point, which CarPlay centers the map on, so the location
  /// dot lands in the open part of the map instead of under the side panel.
  ///
  /// The visible part's center goes ahead of the car, so the car starts near the trailing edge
  /// and drives across most of the map before the next swap, the way navigation apps look ahead.
  /// The point then goes wherever puts that center there, as measured from the last map. Until
  /// there's a last map, it assumes the panel is on the left, where it is in left-hand-drive
  /// cars, and CarPlay's usual zoom for one point, about 0.6 m per screen point.
  private func focus(for car: CLLocation) -> CLLocation {
    let metersPerMapPoint = MKMetersPerMapPointAtLatitude(car.coordinate.latitude)
    var point = MKMapPoint(car.coordinate)
    if let course = heading(of: car) {
      // A third of the way in from the center toward the trailing edge, so most of the
      // visible map lies ahead.
      let visibleSize = visibleRegion.map(Self.size(of:)) ?? Self.typicalVisibleSize
      let ahead = 0.33 * min(visibleSize.width, visibleSize.height) / metersPerMapPoint
      let radians = course * .pi / 180
      // Map y grows southward, and course is clockwise from north.
      point.x += ahead * sin(radians)
      point.y -= ahead * cos(radians)
    }
    if let pointToVisibleCenter {
      point.x -= pointToVisibleCenter.x
      point.y -= pointToVisibleCenter.y
    } else {
      // Map x grows eastward, which is right on a north-up map, so moving the point west moves
      // the visible part's center, and the car with it, right of the panel.
      point.x -= Self.panelShift / metersPerMapPoint
    }
    let coordinate = point.coordinate
    return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }

  /// Records the visible part of the map CarPlay reports. While a new map settles, that's where
  /// CarPlay framed it; after that, it's the driver panning or zooming.
  fileprivate func mapRegionDidChange(to region: MKCoordinateRegion, in template: CPPointOfInterestTemplate) {
    guard template === mapTemplate else { return }
    let isFraming = mapMadeAt.map { Date.now.timeIntervalSince($0) < 3 } ?? false
    if isFraming, let mapFocus, Self.isStreetLevel(region) {
      let focusPoint = MKMapPoint(mapFocus.coordinate)
      let center = MKMapPoint(region.center)
      pointToVisibleCenter = (center.x - focusPoint.x, center.y - focusPoint.y)
    } else if !isFraming {
      driverMovedMapAt = .now
    }
    visibleRegion = region
  }

  /// Whether `region` is zoomed in like CarPlay frames a single point, rather than the wide
  /// view it shows before there's anything to frame.
  private static func isStreetLevel(_ region: MKCoordinateRegion) -> Bool {
    let size = size(of: region)
    return max(size.width, size.height) < 2000
  }

  /// Whether `coordinate` is inside `region`, at least `margin` of its size from every edge.
  private static func contains(_ region: MKCoordinateRegion, _ coordinate: CLLocationCoordinate2D, margin: Double) -> Bool {
    let latInset = region.span.latitudeDelta * (0.5 - margin)
    let lonInset = region.span.longitudeDelta * (0.5 - margin)
    return abs(coordinate.latitude - region.center.latitude) <= latInset
      && abs(coordinate.longitude - region.center.longitude) <= lonInset
  }

  private static func size(of region: MKCoordinateRegion) -> (width: CLLocationDistance, height: CLLocationDistance) {
    let center = region.center
    let west = CLLocation(latitude: center.latitude, longitude: center.longitude - region.span.longitudeDelta / 2)
    let east = CLLocation(latitude: center.latitude, longitude: center.longitude + region.span.longitudeDelta / 2)
    let north = CLLocation(latitude: center.latitude + region.span.latitudeDelta / 2, longitude: center.longitude)
    let south = CLLocation(latitude: center.latitude - region.span.latitudeDelta / 2, longitude: center.longitude)
    return (west.distance(from: east), north.distance(from: south))
  }

  /// The way the car is going: from Core Location when it knows, otherwise from where the
  /// previous map was made.
  private func heading(of car: CLLocation) -> CLLocationDirection? {
    if car.course >= 0 { return car.course }
    guard let previousMapCenter, car.distance(from: previousMapCenter) > 20 else { return nil }
    let from = MKMapPoint(previousMapCenter.coordinate)
    let to = MKMapPoint(car.coordinate)
    let degrees = atan2(to.x - from.x, from.y - to.y) * 180 / .pi
    return degrees < 0 ? degrees + 360 : degrees
  }

  /// How far toward the panel to put the point before the first map is measured: about 100
  /// points at CarPlay's usual zoom.
  private static let panelShift: CLLocationDistance = 60
  /// The visible part of the map at CarPlay's usual zoom for one point, before it's measured.
  private static let typicalVisibleSize: (width: CLLocationDistance, height: CLLocationDistance) = (270, 275)
  /// How close to the edge of the visible map, as a share of its size, the car gets before
  /// the next swap, so the dot never touches the edge.
  private static let edgeMargin = 0.1

  /// A clear pin: without a pin image CarPlay draws its own marker over the location dot. It's
  /// full size, because CarPlay draws a stand-in for one too small to see.
  private static let invisiblePin = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { _ in }

  private func leaveMap() {
    mapTemplate = nil
    mapCenter = nil
    mapFocus = nil
    previousMapCenter = nil
    visibleRegion = nil
    driverMovedMapAt = nil
    interfaceController?.popToRootTemplate(animated: true, completion: nil)
  }

  // MARK: - Maps

  /// Offers Apple Maps and Google Maps. Whether Google Maps is installed can't be checked up front
  /// on iOS 27, so choosing it opens Apple Maps instead when it isn't.
  private func chooseMapsApp() {
    let location = store.currentLocation?.coordinate
    let actions = MapsApp.allCases.map { app in
      CPAlertAction(title: app.title, style: .default) { [weak self] _ in
        self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
        self?.openMaps(app, at: location)
      }
    }
    let cancel = CPAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
      self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
    }
    let sheet = CPActionSheetTemplate(
      title: "Open Map",
      message: "Skyway keeps counting miles while you drive.",
      actions: actions + [cancel]
    )
    interfaceController?.presentTemplate(sheet, animated: true, completion: nil)
  }

  private func openMaps(_ app: MapsApp, at location: CLLocationCoordinate2D?) {
    openURL(app.url(centeredOn: location)) { [weak self] opened in
      if !opened, app != .apple {
        self?.openMaps(.apple, at: location)
      }
    }
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
    // CarPlay may call this off the main thread, so hop to it rather than assume.
    Task { @MainActor [weak self] in
      self?.mapRegionDidChange(to: region, in: pointOfInterestTemplate)
    }
  }

  nonisolated func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest) {
    // CarPlay may call this off the main thread, so hop to it rather than assume.
    let openedAt = Date.now
    Task { @MainActor [weak self] in
      self?.cardOpenedAt = openedAt
    }
  }
}

/// The maps apps a driver can switch to for a map that turns with the car.
private enum MapsApp: CaseIterable {
  case apple
  case google

  var title: String {
    switch self {
    case .apple: "Apple Maps"
    case .google: "Google Maps"
    }
  }

  func url(centeredOn location: CLLocationCoordinate2D?) -> URL {
    var components = URLComponents()
    switch self {
    case .apple:
      components.scheme = "maps"
      components.host = ""
      if let location {
        components.queryItems = [URLQueryItem(name: "ll", value: "\(location.latitude),\(location.longitude)")]
      }
    case .google:
      components.scheme = "comgooglemaps"
      components.host = ""
      if let location {
        components.queryItems = [URLQueryItem(name: "center", value: "\(location.latitude),\(location.longitude)")]
      }
    }
    return components.url!
  }
}
