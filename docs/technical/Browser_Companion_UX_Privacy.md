# Browser Companion UX and Privacy

## State machine

The responsive prototype in `web/companion` follows `idle → joining → pending approval → privacy gate → private revealed → submitting`, with explicit disconnected/reconnecting and leave/clear paths. A join does not infer a stable seat. Approval and resume always come from the host/coordinator claim flow.

The public room summary may be visible at any time. Seat-private role, faction, objectives, prompts, cards/inventory references, and legal actions are retained in memory but omitted from the rendered model and DOM until the player activates the privacy gate. `Obscure now`, disconnect, expiry, revocation, and leave replace private DOM nodes rather than only hiding them with CSS. The resume capability is never rendered.

Browser storage contains only room code, room ID, transient client ID, stable seat number, and opaque resume capability under one versioned local-storage key. It contains no role, objective, card, action, account, name, email, analytics ID, or long-term profile. `Leave and clear room data` removes the entire key.

## Accessibility

- Controls are native forms/buttons and keyboard operable with visible focus.
- Touch targets are at least 48 CSS pixels high.
- Status changes use visible text and a polite live region.
- Seat identity combines stable numeral, named symbol, segment pattern, and color name/hex; color is never the sole cue.
- Layout wraps down to 280 CSS pixels and shifts to one-column summaries at 430 pixels.
- Reduced-motion preferences disable animation/transition behavior; there is no flashing.
- Long values wrap intentionally; no private data is placed in page title, URL, browser history, or public screenshot flow.

There is no install prompt, service worker, background sync, push notification, camera, microphone, geolocation, advertising, analytics, or fingerprinting. The page declares a restrictive Permissions Policy for camera, microphone, and geolocation.

## Honest privacy limitations

A browser on a shared display is not private. The gate tells the player to check their surroundings, and the private panel always offers a prominent obscure action. HTTPS/WSS protects traffic from ordinary network observers but not the configured room-service operator. Production penetration testing, formal privacy/legal review, and long-session social observation are not claimed by this prototype.
