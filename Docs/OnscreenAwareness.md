# Onscreen Awareness in SkyWay

How SkyWay tells Siri and Apple Intelligence what's on screen, so requests like "Where is this trip going?" or "Tell me about the second one" resolve to real app data.

## The three pieces

| Piece | Written | Purpose | In SkyWay |
| --- | --- | --- | --- |
| **Entity** | Once per *kind of thing* | Describes what it is and which fields Siri can read (`@Property`) | `TripEntity`, `TravelActionEntity` |
| **Query** | Once, alongside the entity | How the system looks an entity up from its ID | `TripEntityQuery`, `TravelActionEntityQuery` |
| **Annotation** | On each screen that shows it | "These are the ones visible right now" | `.userActivity` / `.appEntityIdentifier` |

The annotation carries only an **ID**. When Siri needs the details, it calls the entity's query with that ID. Annotations say *which* things are on screen; entities and queries say *what* they are.

You don't create a new entity per screen. If a trip appears on another tab, reuse `TripEntity` and add a one-line annotation there.

`IndexedEntity` is optional. It adds Spotlight search on top of `AppEntity`. Onscreen awareness only needs `AppEntity`. `TripEntity` is indexed; `TravelActionEntity` isn't.

## `.userActivity` vs `.appEntityIdentifier`

### `.userActivity` + `appEntityIdentifier`: one item for the whole screen

```swift
.userActivity(TripEntity.viewTripActivityType) { activity in
  activity.title = trip.title
  activity.appEntityIdentifier = EntityIdentifier(for: TripEntity.self, identifier: trip.id)
}
```

- Marks what the person is doing right now ("viewing the San Francisco trip").
- **Only one user activity is current at a time**, so it can describe only one entity.
- Requires iOS 18.2+. The activity type must be listed in `NSUserActivityTypes` (`Project.json`).
- User activities also power Handoff and state restoration.
- Used in `TravelView.swift` and `BoardingPassView.swift`.

### `.appEntityIdentifier(_:)`: tags a specific view

```swift
.appEntityIdentifier(EntityIdentifier(for: TravelActionEntity.self, identifier: action.id))
```

- Attaches an entity to the view it modifies: a row, a card, or a whole screen.
- Applied **per row**, so each row says "I'm *Track your bags*", "I'm *Inflight menu*", and so on. It doesn't capture the whole screen.
- Lets Siri resolve "this one", "the second one", or an item by name.
- Requires iOS 18.4+. No activity type or `Info.plist` entry needed.
- Used in `SearchView.swift`.

### `.appEntityIdentifier(forSelectionType:)`: selectable lists

```swift
.appEntityIdentifier(forSelectionType: EventEntity.ID.self) { eventID in
  EntityIdentifier(for: EventEntity.self, identifier: eventID)
}
```

- Maps a list's **selection** values to entities (see Apple's CometCal sample).
- Only applies when rows are selectable. SkyWay's search rows aren't, so they use the per-row modifier instead.

## When to use which

| Screen shows… | `.appEntityIdentifier` | `.userActivity` |
| --- | --- | --- |
| One main item (detail screen) | ✅ on the screen's root view | ✅ |
| Several items (list, grid) | ✅ on each item | ❌ only one activity can be current |

**Rule of thumb:**

- **Default to `.appEntityIdentifier`.** It works for both cases: on the root view for one item, on each item for many.
- **Use `.userActivity` only when you also want what user activities add:**
  - Handoff to another device
  - Restoring where the person was on relaunch
  - Supporting iOS 18.2–18.3, where `.appEntityIdentifier` isn't available

SkyWay targets iOS 27 and doesn't use Handoff or state restoration, so `.appEntityIdentifier` would work on the Travel and boarding pass screens too. They use `.userActivity` only to follow Apple's CometCal sample.

## Why "Where is my trip?" needs an App Shortcut

General questions like "Where is my trip to?" don't refer to the screen, so Siri answers them from personal context (Calendar, Mail, Messages). Apple Intelligence schema domains cover calendar, mail, maps, notes, and others, but **there's no travel domain**. So a third-party travel app can't answer general trip questions through onscreen annotations alone.

`GetCurrentTripIntent` and `SkywayShortcuts` fix this with phrases that include the app name:

- "Where is my trip in Skyway"
- "Where am I travelling in Skyway"
- "Show my trip in Skyway"

## Phrases to try

With the Travel tab or boarding pass on screen:

- "Where is this trip going?"
- "What gate do I leave from?"
- "What's on my screen?"

With the search screen (gear tab) on screen:

- "What's the second one?"
- "Tell me about Track your bags"

From anywhere:

- "Where is my trip in Skyway?"

Requires a physical iPhone with Apple Intelligence turned on. The simulator doesn't support it.

## Files

| File | Role |
| --- | --- |
| `App/TripEntity.swift` | `TripEntity` (`IndexedEntity`, `Transferable`), `TripEntityQuery`, Spotlight indexing |
| `App/TravelActionEntity.swift` | `TravelActionEntity` (`AppEntity`, `Transferable`), `TravelActionEntityQuery` |
| `App/TripStore.swift` | Trip data shared by the UI and App Intents |
| `App/GetCurrentTripIntent.swift` | "Get Upcoming Trip" intent with a spoken answer |
| `App/SkywayShortcuts.swift` | Siri phrases for the intent |
| `App/TravelView.swift`, `App/BoardingPassView.swift` | Screen-level `.userActivity` annotation |
| `App/SearchView.swift` | Per-row `.appEntityIdentifier` annotation |

## Reference

- WWDC26 session 344 and Apple's *Integrating Your Calendar App with Apple Intelligence* (CometCal) sample
