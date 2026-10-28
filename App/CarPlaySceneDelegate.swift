import CarPlay
import MapKit

/// Shows the next trip on the car's display: when to leave, where to go at the airport, and what's ready.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?
  private var scene: CPTemplateApplicationScene?
  private var tabBar: CPTabBarTemplate?
  private var tripTemplate: CPInformationTemplate?
  private var airportTemplate: CPPointOfInterestTemplate?
  private var refreshTimer: Timer?

  private var trip: Trip { TripStore.trips.first ?? .sample }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    scene = templateApplicationScene

    let tripTemplate = makeTripTemplate()
    let airportTemplate = makeAirportTemplate()
    let tabBar = CPTabBarTemplate(templates: [tripTemplate, airportTemplate, makeChecklistTemplate()])
    self.tripTemplate = tripTemplate
    self.airportTemplate = airportTemplate
    self.tabBar = tabBar
    interfaceController.setRootTemplate(tabBar, animated: true, completion: nil)

    // Keep the leave-by countdown current while the car is connected.
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.refreshTripItems() }
    }
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    refreshTimer?.invalidate()
    refreshTimer = nil
    self.interfaceController = nil
    scene = nil
    tabBar = nil
    tripTemplate = nil
    airportTemplate = nil
  }

  // MARK: - Trip

  private func makeTripTemplate() -> CPInformationTemplate {
    let directions = CPTextButton(title: "Directions", textStyle: .confirm) { [weak self] _ in
      guard let self, let dropOff = AirportSpot.spots(for: trip).first else { return }
      openDirections(to: dropOff)
    }
    let parking = CPTextButton(title: "Airport Options", textStyle: .normal) { [weak self] _ in
      guard let self, let airportTemplate else { return }
      tabBar?.select(airportTemplate)
    }
    let template = CPInformationTemplate(
      title: trip.title,
      layout: .twoColumn,
      items: tripItems(),
      actions: [directions, parking]
    )
    template.tabTitle = "Trip"
    template.tabImage = UIImage(systemName: "airplane")
    return template
  }

  private func tripItems() -> [CPInformationItem] {
    let trip = trip
    let time = Date.FormatStyle(date: .omitted, time: .shortened)
    return [
      CPInformationItem(title: "Leave by", detail: leaveByDetail(for: trip)),
      CPInformationItem(title: "Flight", detail: "\(trip.flightNumber) · On time"),
      CPInformationItem(title: "Route", detail: "\(trip.originCode) → \(trip.destinationCode)"),
      CPInformationItem(title: "Boards", detail: trip.boardingTime.formatted(time)),
      CPInformationItem(title: "Departs", detail: trip.departure.formatted(time)),
      CPInformationItem(title: "Gate", detail: trip.gate),
    ]
  }

  private func leaveByDetail(for trip: Trip, now: Date = .now) -> String {
    let leaveBy = trip.leaveByTime.formatted(date: .omitted, time: .shortened)
    let minutes = Int(trip.leaveByTime.timeIntervalSince(now) / 60)
    if now >= trip.departure {
      return "Departed"
    } else if minutes <= 0 {
      return "Leave now"
    } else if minutes < 120 {
      return "\(leaveBy) · in \(minutes) min"
    } else {
      return leaveBy
    }
  }

  private func refreshTripItems() {
    tripTemplate?.items = tripItems()
  }

  // MARK: - Airport

  private func makeAirportTemplate() -> CPPointOfInterestTemplate {
    let points = AirportSpot.spots(for: trip).map { spot in
      let point = CPPointOfInterest(
        location: MKMapItem(location: CLLocation(latitude: spot.latitude, longitude: spot.longitude), address: nil),
        title: spot.title,
        subtitle: spot.subtitle,
        summary: spot.summary,
        detailTitle: spot.title,
        detailSubtitle: spot.subtitle,
        detailSummary: spot.summary,
        pinImage: UIImage(systemName: spot.systemImage)
      )
      point.primaryButton = CPTextButton(title: "Directions", textStyle: .confirm) { [weak self] _ in
        self?.openDirections(to: spot)
      }
      return point
    }
    let template = CPPointOfInterestTemplate(title: "\(trip.originCode) Airport", pointsOfInterest: points, selectedIndex: 0)
    template.pointOfInterestDelegate = self
    template.tabTitle = "Airport"
    template.tabImage = UIImage(systemName: "map")
    return template
  }

  private func openDirections(to spot: AirportSpot) {
    guard let url = spot.directionsURL else { return }
    scene?.open(url, options: nil, completionHandler: nil)
  }

  // MARK: - Checklist

  private func makeChecklistTemplate() -> CPListTemplate {
    let trip = trip
    let checkedIn = CPListItem(text: "Checked in", detailText: "Group \(trip.boardingGroup) · Seat \(trip.seat)", image: UIImage(systemName: "checkmark.circle.fill"))
    let boardingPass = CPListItem(text: "Boarding pass", detailText: "Ready in Skyway on iPhone", image: UIImage(systemName: "qrcode"))
    boardingPass.accessoryType = .disclosureIndicator
    boardingPass.handler = { [weak self] _, completion in
      self?.showBoardingPass()
      completion()
    }
    let bags = CPListItem(text: "Bag drop", detailText: "1 checked bag · Counter closes 45 min before departure", image: UIImage(systemName: "suitcase.fill"))
    let security = CPListItem(text: "Security", detailText: "About 15 min wait at Terminal 4", image: UIImage(systemName: "person.badge.shield.checkmark.fill"))
    let weather = CPListItem(text: "\(trip.destinationCity) weather", detailText: trip.arrivalWeather, image: UIImage(systemName: "sun.max.fill"))

    let template = CPListTemplate(
      title: "Checklist",
      sections: [
        CPListSection(items: [checkedIn, boardingPass, bags, security], header: "Before you fly", sectionIndexTitle: nil),
        CPListSection(items: [weather], header: "On arrival", sectionIndexTitle: nil),
      ]
    )
    template.tabTitle = "Checklist"
    template.tabImage = UIImage(systemName: "checklist")
    return template
  }

  private func showBoardingPass() {
    let trip = trip
    let template = CPInformationTemplate(
      title: "Boarding pass",
      layout: .twoColumn,
      items: [
        CPInformationItem(title: "Passenger", detail: trip.passengerName),
        CPInformationItem(title: "Confirmation", detail: trip.confirmationCode),
        CPInformationItem(title: "Seat", detail: trip.seat),
        CPInformationItem(title: "Group", detail: trip.boardingGroup),
        CPInformationItem(title: "Gate", detail: trip.gate),
      ],
      actions: []
    )
    interfaceController?.pushTemplate(template, animated: true, completion: nil)
  }
}

extension CarPlaySceneDelegate: CPPointOfInterestTemplateDelegate {
  nonisolated func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {
    // The airport spots are fixed, so there's nothing to reload when the map moves.
  }
}
