import CarPlay
import MapKit

/// The Trips tab: start a mileage trip, watch its miles and deduction add up, end it as
/// business or personal, and look back at recent trips.
@MainActor
final class CarPlayTripsController: NSObject {
  let rootTemplate: CPListTemplate
  private weak var interfaceController: CPInterfaceController?
  private let store = DriveTripStore.shared
  private var tripTemplate: CPInformationTemplate?
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
      showTrip(animated: false)
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
    tripTemplate = nil
    mapTemplate = nil
  }

  private func refresh() {
    refreshList()
    if store.isLocationDenied {
      showLocationAlert()
    } else if store.activeTrip == nil, tripTemplate != nil || mapTemplate != nil, !isEnding {
      leaveTrip()
    } else {
      refreshTrip()
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
    showTrip(animated: true)
  }

  // MARK: - Trip in progress

  /// The running totals as label and value rows, with End Trip as the main button.
  private func showTrip(animated: Bool) {
    // Back pops these without telling this controller, so check what's actually showing.
    if let top = interfaceController?.topTemplate, top === tripTemplate || top === mapTemplate { return }
    let template = CPInformationTemplate(
      title: "Trip in Progress",
      layout: .leading,
      items: tripItems(),
      actions: [
        CPTextButton(title: "End Trip", textStyle: .confirm) { [weak self] _ in self?.confirmEnd() },
        CPTextButton(title: "Show Map", textStyle: .normal) { [weak self] _ in self?.showMap() },
      ]
    )
    tripTemplate = template
    mapTemplate = nil
    interfaceController?.pushTemplate(template, animated: animated, completion: nil)
  }

  private func tripItems() -> [CPInformationItem] {
    guard let trip = store.activeTrip else { return [] }
    let status = if store.isParked {
      "Parked · tap End Trip when you're done"
    } else if store.lastMovedAt == nil {
      "Waiting to start moving"
    } else {
      "Driving"
    }
    return [
      CPInformationItem(title: "Status", detail: status),
      CPInformationItem(title: "Distance", detail: trip.milesText),
      CPInformationItem(title: "Deduction", detail: "\(trip.estimatedDeductionText) est. at $0.16/mi"),
      CPInformationItem(title: "Started", detail: "\(trip.startTimeText) · \(trip.minutesText())"),
      CPInformationItem(title: "From", detail: trip.startAddress ?? "Finding the address…"),
    ]
  }

  private func refreshTrip() {
    tripTemplate?.items = tripItems()
  }

  // MARK: - Map

  private func showMap() {
    if let mapTemplate, interfaceController?.topTemplate === mapTemplate { return }
    let template = CPPointOfInterestTemplate(title: "Trip Map", pointsOfInterest: [], selectedIndex: NSNotFound)
    template.pointOfInterestDelegate = self
    // Always reachable, even before the first location fix puts a pin on the map.
    template.trailingNavigationBarButtons = [
      CPBarButton(title: "End Trip") { [weak self] _ in self?.confirmEnd() },
    ]
    mapTemplate = template
    refreshMap()
    interfaceController?.pushTemplate(template, animated: true, completion: nil)
  }

  private func refreshMap() {
    guard let mapTemplate, let trip = store.activeTrip else { return }
    let progress = "\(trip.milesText) · \(trip.estimatedDeductionText) est."
    let elapsed = "Started \(trip.startTimeText) · \(trip.minutesText())"

    // Just the car: every point also gets a row in the side panel, and one trip should read as one card.
    var points: [CPPointOfInterest] = []
    if let current = store.currentLocation {
      points.append(point(at: current, title: progress, subtitle: elapsed, summary: "From \(trip.startAddress ?? "your start")", systemImage: "car.fill"))
    }
    // Select the car, so its card with the running totals is showing. Clearing the selection
    // first makes the map move to the car's new position instead of staying where it was.
    mapTemplate.setPointsOfInterest(points, selectedIndex: NSNotFound)
    if !points.isEmpty {
      mapTemplate.selectedIndex = points.count - 1
    }
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

  private func leaveTrip() {
    tripTemplate = nil
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
    leaveTrip()
    refreshList()
  }

  private func showLocationAlert() {
    store.isLocationDenied = false
    if tripTemplate != nil || mapTemplate != nil {
      leaveTrip()
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
