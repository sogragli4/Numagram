# Store screenshots

**Not producible in this environment** — no Android/iOS device or emulator is attached (see
`CLAUDE.MD`'s Phase 2-4 "visual verification" notes), so real device screenshots can't be
captured here. This file records the required sizes and the recommended screens so the founder
(or a machine with a device/emulator attached) can capture them directly.

## Required sizes

**Google Play**
- Phone: at least 2 screenshots, 16:9 or 9:16, min dimension 320px, max 3840px.
- 7" and 10" tablet: optional but recommended if the layout is tested at those sizes.
- Feature graphic: 1024×500px, no device frame.

**Apple App Store**
- 6.9" display (iPhone 16 Pro Max class): 1320×2868px (portrait), required.
- 6.5" display: 1284×2778px or 1242×2688px, required if not covered by the 6.9" set alone in
  App Store Connect's fallback rules — check current Apple requirements at submission time,
  they change occasionally.
- iPad Pro 13" (if supporting iPad): 2064×2752px.

## Recommended screens to capture (5-8 total)

1. Daily screen — today's puzzle card, current streak, "Play Today's Puzzle" button.
2. Mid-solve board — a partially filled grid showing clues, hearts, and the Fill/Mark toggle.
3. Completion sheet — solved state with time, hearts remaining, and the share card visible.
4. Archive calendar — completed/missed/today legend, a month with a visible streak.
5. Free Play size picker.
6. Statistics screen with real (non-empty) data.
7. Settings — theme picker showing an unlocked and a locked theme side by side.
8. (Optional) Colourblind-safe palette applied to the board, to call out the accessibility
   option.

## How to capture once a device/emulator is available

```bash
flutter build apk --debug
flutter install
# or run on emulator/simulator directly:
flutter run
```

Reach each screen above via normal navigation, use each platform's screenshot mechanism
(Android: power+volume-down; iOS Simulator: Cmd+S), then crop/resize to the exact required
dimensions before uploading — both stores reject screenshots that don't match an exact listed
size.
