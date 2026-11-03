# Homepage UI audit — 3 November 2026

Source-based assessment of the current homepage. No device screenshot, contrast measurement or screen-reader pass is claimed. Rail layout/order is outside this change; concurrent workspace edits are preserved.

## Implemented in this pass

- Bottom-navigation labels increased from 10.5 to 12. Labels can wrap and the bar grows with text scaling.
- The Shots rail arrow target increased from 36×36 to 48×48.
- The Dr. Paw AI badge increased from 8 to 12.

## Findings recorded before follow-up fixes

| Priority | Evidence | Recommendation |
|---|---|---|
| P2 | `home_product_rails.dart` still uses 9–10 text for video chips and secondary information; `home_hero_carousel.dart` uses a 9.5 eyebrow. | Reduce secondary badge density and use 12–14 for information needed to choose a product/video. Validate fixed card heights before increasing all type sizes. |
| P2 | `home_screen.dart` has an AI floating button; `main_shell.dart` overlays a cart bar when the cart is nonempty. | Verify the two overlays together on a 320px screen, at large text, and at the page bottom. Ensure both remain reachable without covering the final rail action. Overlap is a verification risk, not a confirmed rendered defect. |
| P2 | Raised central Consult navigation has stronger emphasis than other tabs. Its accessible label says Care team chat. | Align the visible label and destination with the care service. Keep booked consultations and AI distinct. Test whether users understand the destination before changing the navigation structure. |
| P3 | Search placeholder is a long, single-line phrase; several rail subtitles also truncate. | Shorten the search prompt and put supporting explanations outside fixed single-line spaces. Prioritize rail title, product name, price and action over decorative microcopy. |
| P3 | Numerous trust/marketing sections compete with product discovery over a long page. | Keep the requested rails; simplify repeated claims and decoration inside sections. Use consistent heading, caption and action treatment. |

## False positives excluded

The 28px search icon and 32px arrow in `home_top_bar.dart` are decorative parts of the larger search control, not independently tappable undersized buttons. The 36px trust icons are likewise not separate touch targets. Do not enlarge these purely to satisfy a target-size rule.

## Required device checks

- Small and large phone, default and 200% text scale: navigation labels, pinned search, rail headers, two-line product names, prices and card actions.
- Empty/full cart: AI/cart overlay clearance while scrolling, at the page bottom and after returning from product details.
- VoiceOver/TalkBack: selected tab, search control, rail actions, product names/prices, AI identity and cart total.
- Contrast measurements on image overlays, muted captions and disabled controls.
- Slow/offline data: rail loading, retry and empty-state distinction.

## Follow-up fixes and validation

Implemented: readable video-card text, removed redundant views/discount badges, shorter search prompt, Care tab naming, 48px header-cart and rail actions, reserved space for the floating cart, and adaptive animal/category/video layouts. The delivery row no longer competes with a static dispatch badge. Rail order is preserved.

Physical-device inspection on A015 / Android 16 caught 200% text overflows in delivery location, animal labels and category tiles. These were corrected and the homepage was inspected again. Populated-cart and checkout views were also checked at 200%; checkout address actions now wrap. Device font scale was restored to 1.0 afterward.

243 Flutter tests passed, including navigation labeled-target/Android touch-target checks at 320px and 200%. Five targeted checkout tests passed after the final checkout adjustment. Analyzer reported no issues. No payment was submitted. Spoken TalkBack/VoiceOver behavior, exhaustive contrast testing, and all lower-page/state combinations have not been certified.

User-requested adjustment: restored the original floating View cart overlay by removing the reserved bottom strip. Removed the COD availability claim from the checkout delivery summary; payment availability remains controlled by checkout/admin settings.
