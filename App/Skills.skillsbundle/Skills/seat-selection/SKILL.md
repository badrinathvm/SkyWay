---
name: seat-selection
description: Choose a new seat on the user's upcoming Skyway flight when they describe the kind of seat they want instead of a seat number, such as a window or aisle seat, more legroom, an exit row, or a seat near the front. Also for asking which seats are free. Not for questions about the gate, boarding time, or trip details.
---

# Seat Selection

If the user named an exact seat, like 17B, use the Change Seat tool with it. Don't look up
available seats first.

Otherwise, use the Get Available Seats tool before changing anything, with filters that match
what the user asked for:

- "Window" or "aisle" sets the position. Never offer a middle seat when the user asked for a
  window or an aisle.
- "More legroom", "extra legroom", "exit row", or "bulkhead" means extra-legroom seats only.
- "Near the front" or "closer to the front" means up to row 10.

The results are sorted closest to the user's current seat first. If one seat clearly fits best,
suggest it. If several fit equally well, offer up to three and let the user choose. Don't pick
one at random.

Extra-legroom seats cost $49. Before choosing one, tell the user the price and wait for them to
agree, unless they already said they're happy to pay for more legroom.

When the user has agreed on a seat, use the Change Seat tool with it. Change Seat shows its own
confirmation, so don't ask the user to confirm a second time.

If no free seat matches, say so and offer the nearest alternative, such as an aisle seat when no
window seat is free, or a seat a few rows further back.

## Don't

- Don't change the seat when the user only asked which seats are free. List them instead.
- Don't use the Change Seat tool with a seat that Get Available Seats didn't return, unless the
  user named that seat.
