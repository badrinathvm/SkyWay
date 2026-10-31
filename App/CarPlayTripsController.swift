import CarPlay
import MapKit

/// The Trips tab: start a mileage trip, follow it on a map, end it as business or personal,
/// and look back at recent trips.
@MainActor
final class CarPlayTripsController: NSObject {
  let rootTemplate: CPListTemplate
  private weak var interfaceController: CPInterfaceController?
  private let store = DriveTripStore.shared
  private var mapTemplate: CPPointOfInterestTemplate?
  private var refreshTimer: Timer?
  private var shownListText: [String] = []
  private var isEnding = false

  init(interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
    rootTemplate = CPListTemplate(title: "Trips", sections: [])
    rootTemplate.tabTitle = "Trips"
    rootTemplate.tabImage = UIImage(systemName: "car.fill")
    super.init()
    refreshList()
  }

  /// Call once the Trips tab is on screen.
  func didConnect() {
    store.resumeTrackingIfNeeded()
    if store.activeTrip != nil {
      showMap(animated: false)
    }
    // CarPlay templates aren't observable views, so poll: this keeps the map current
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
        text: "Trip in Progress · \(trip.milesText)",
        detailText: "Started \(trip.startTimeText) · \(trip.estimatedDeductionText) est.",
        image: UIImage(systemName: "record.circle")
      )
    } else {
      startItem = CPListItem(
        text: "Start a Trip",
        detailText: "Tracks miles from where you are now",
        image: UIImage(systemName: "play.circle.fill")
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
        image: UIImage(systemName: trip.purpose == .business ? "briefcase.fill" : "car.fill")
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

  private func startOrShowTrip() {
    if store.activeTrip == nil {
      store.startTrip()
      refreshList()
    }
    showMap(animated: true)
  }

  // MARK: - Map

  private func showMap(animated: Bool) {
    guard mapTemplate == nil else { return }
    let template = CPPointOfInterestTemplate(title: "Trip in Progress", pointsOfInterest: [], selectedIndex: NSNotFound)
    template.pointOfInterestDelegate = self
    // Always reachable, even before the first location fix puts a pin on the map.
    template.trailingNavigationBarButtons = [
      CPBarButton(title: "End Trip") { [weak self] _ in self?.confirmEnd() },
    ]
    mapTemplate = template
    refreshMap()
    interfaceController?.pushTemplate(template, animated: animated, completion: nil)
  }

  private func refreshMap() {
    guard let mapTemplate, let trip = store.activeTrip else { return }
    let progress = "\(trip.milesText) · \(trip.estimatedDeductionText) est."
    let elapsed = "Started \(trip.startTimeText) · \(trip.minutesText())"

    var points: [CPPointOfInterest] = []
    if let start = trip.start {
      points.append(point(at: start.location, title: "Start", subtitle: trip.startAddress ?? elapsed, summary: progress, systemImage: "flag.fill"))
    }
    if let current = store.currentLocation {
      points.append(point(at: current, title: progress, subtitle: elapsed, summary: "From \(trip.startAddress ?? "your start")", systemImage: "car.fill"))
    }
    // Select the car, so its card with the running totals is the one showing.
    mapTemplate.setPointsOfInterest(points, selectedIndex: points.isEmpty ? NSNotFound : points.count - 1)
  }

  private func point(at location: CLLocation, title: String, subtitle: String, summary: String, systemImage: String) -> CPPointOfInterest {
    let point = CPPointOfInterest(
      location: MKMapItem(location: location, address: nil),
      title: title,
      subtitle: subtitle,
      summary: summary,
      detailTitle: title,
      detailSubtitle: subtitle,
      detailSummary: summary,
      pinImage: UIImage(systemName: systemImage)
    )
    point.primaryButton = CPTextButton(title: "End Trip", textStyle: .confirm) { [weak self] _ in
      self?.confirmEnd()
    }
    return point
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
      guard let trip = store.activeTrip else {
        isEnding = false
        return
      }
      let business = CPAlertAction(title: "Business (\(trip.estimatedDeductionText))", style: .default) { [weak self] _ in
        self?.finish(as: .business)
      }
      let personal = CPAlertAction(title: "Personal", style: .default) { [weak self] _ in
        self?.finish(as: .personal)
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

  private func finish(as purpose: DriveTrip.Purpose) {
    interfaceController?.dismissTemplate(animated: true, completion: nil)
    store.endTrip(as: purpose)
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
}
