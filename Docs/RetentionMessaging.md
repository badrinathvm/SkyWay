# Retention Messaging in Skyway

Apple's Retention Messaging (live November 4, 2026) lets you put your own message, and optionally an offer, on the App Store's **Confirm Cancellation** sheet. The sheet appears when a subscriber taps Cancel Subscription in Apple Account › Subscriptions, or in your app's `manageSubscriptionsSheet`.

The sheet is system UI. **No StoreKit API draws it or chooses its message.** The work splits like this:

| Who | What | Where in this project |
| --- | --- | --- |
| App Store Connect | Approved messages (header, body, bullets, optional image) and Retention Offers | Mirrored by `RetentionMessage.approved` |
| Your server (optional, by request) | Picks a message, plan switch, or promotional offer in real time, in under 700 ms | Mocked by `RetentionDecisionEngine` |
| Your app | Sells the subscription, opens the manage sheet, and handles what the subscriber chose | `SubscriptionStore`, `SubscriptionView` |

Skyway has no real subscription, so the demo mocks **Skyway Plus** (`skyway.plus.monthly`, `skyway.plus.annual`) in `StoreKit/SkywayPlus.storekit`. To try it, open the Settings tab, tap the crown, and choose **Preview Cancellation**.

## 1. Messages without a server (App Store Connect)

Go to Monetization › Subscriptions › Retention Messaging › Get Started. Then:

1. Add a reference name, header, and body, with localizations.
2. Optionally attach an image from the Asset Library and one or more **Retention Offers** (pay as you go, pay up front, or free), with eligibility rules: *Paid Subscription Duration* and *Wait Between Offers*.
3. Link the message to subscriptions (one message per subscription; up to 10 messages per app) and submit it for review.

Text and image edits don't need an app update. An edit creates a draft, and the approved version stays live until the draft passes review.

**Content rules:** don't mention prices, discounts, or "free" in the header or body. The App Store renders offer terms itself. You may describe the features the subscriber loses if they're accurate. Avoid pressure tactics.

## 2. Real-time messages (your server)

When a subscriber views cancellable subscription details, the App Store POSTs to your **Get Retention Message** endpoint:

```json
{ "signedPayload": "<JWS: header.payload.signature>" }
```

1. Verify the JWS with the `x5c` certificate chain against Apple's root CA. App Store Server Library does this for you.
2. Decode the payload (`DecodedRealtimeRequestBody`, mirrored by `RetentionRealtimeRequest`):

```json
{
  "appAppleId": 6740000000,
  "environment": "Sandbox",
  "originalTransactionId": "2000000912345678",
  "productId": "skyway.plus.monthly",
  "requestIdentifier": "4f1b…",
  "signedDate": 1793943700000,
  "userLocale": "en-US"
}
```

3. Return `200` with exactly one of these (`RealtimeResponseBody`, mirrored by `RetentionRealtimeResponse`):

```json
{ "message": { "messageIdentifier": "6a1f3b2e-…" } }

{ "alternateProduct": { "messageIdentifier": "ed7f25fc-…", "productId": "skyway.plus.annual" } }

{ "promotionalOffer": { "messageIdentifier": "c4d9e1a7-…", "promotionalOfferSignatureV2": "<JWS signed with your IAP key>" } }
```

`alternateProduct` (switch plan) is only available in real time.

### A server handler

`RetentionDecisionEngine` is written so you can move it to a Swift server unchanged:

```swift
// Vapor-style sketch
app.post("retention") { req async throws -> Response in
  let body = try req.content.decode(SignedPayload.self)
  let request: RetentionRealtimeRequest = try verifier.verifyAndDecode(body.signedPayload) // Apple's library
  let signals = try await subscriberCache.signals(for: request.originalTransactionId) // precomputed: stay fast
  let response = await RetentionDecisionEngine().respond(to: request, signals: signals)
  return try await (response ?? .message(messageIdentifier: RetentionMessage.default.messageIdentifier))
    .encodeResponse(status: .ok, for: req)
}
```

The engine's **Automatic** rules:

| Signal | Response |
| --- | --- |
| 3 or more drives logged in CarPlay | `message`: "Keep your mileage log", with an image and the features they'd lose |
| Monthly subscriber | `alternateProduct` → annual plan |
| Subscribed 6+ months, no previous retention offer | `promotionalOffer` → `skyway.plus.retention.3mfree` |
| Otherwise | the default text message |

### Deadlines and fallback

- Production responses must arrive within **700 ms**. Before Apple accepts your production URL, call **Initiate Performance Test** in Sandbox and pass it. Then call **Configure Realtime URL**.
- If the request fails, times out, or returns an invalid response, the App Store shows your App Store Connect message (with an eligible Retention Offer). If you don't have one, it shows the **default message** for the product and locale. Choose the *Server timeout* scenario to see this.

## 3. In the app

```swift
// Opens Apple's sheet; Cancel Subscription there shows your message.
.manageSubscriptionsSheet(isPresented: $isManaging, subscriptionGroupID: SubscriptionStore.groupID)
```

What the subscriber chooses comes back as ordinary transactions on `Transaction.updates`:

```swift
extension Transaction.OfferType {
  static let retention = Transaction.OfferType(rawValue: 5) // no named constant in StoreKit yet
}

if transaction.offer?.type == .retention { /* Retention Offer from App Store Connect */ }
else if transaction.offer?.type == .promotional { /* offer your real-time endpoint chose */ }
else if productChanged { /* accepted the switch-plan suggestion */ }
// renewalInfo.willAutoRenew == false → they cancelled; access continues to expirationDate
```

Keep entitlement logic based on verified transactions and subscription status. Server code with a fixed offer-type enum also needs the new value `5`.

## 4. Testing

| Where | What you can see |
| --- | --- |
| Simulator with `SkywayPlus.storekit` | Buying plans, switching to annual, and the in-app **Preview Cancellation** recreation for every response type |
| Device with Run on… and a Sandbox Apple Account | The real Confirm Cancellation sheet with draft or approved messages, and real `offerType` 5 transactions |
| App Store Connect › Sandbox | Message previews, including the fallback for ineligible subscribers |

In this demo, **Accept Offer** and **Cancel Subscription** in the preview record the outcome locally. Only the App Store can redeem a signed offer or cancel. **Switch Plan** makes a real StoreKit purchase of the annual plan.

## Metrics

App Store Connect's *App Store Retention Messaging* report shows page views, cancellations, saves, redeemed offers, and plan changes. Apple reports an average save-rate lift of 1.4 points, and 5.5 points with promotional offers. "Saves" include people who simply dismissed the sheet.
