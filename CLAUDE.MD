# Claude Code Kickoff Prompt — Daily Nonogram App

> Copy everything below the line into Claude Code as your first message.
> Work through it phase by phase; do not let the agent jump ahead.

---

## PROJECT BRIEF

Build a cross-platform (Android + iOS) daily puzzle game called **Nonogram Daily** (working title).
The core loop: every calendar day, every user in the world gets the same procedurally generated
nonogram (picross) puzzle. Solving it extends a streak. An archive of past puzzles and an endless
"free play" mode fill the rest of the session time.

Monetization is **ad-only** (rewarded + interstitial via mediation). There is **no backend, no login,
no server**. Everything runs on-device. This is a deliberate constraint — respect it.

## LOCKED TECHNICAL DECISIONS

Do not propose alternatives to these. If you believe one is wrong, flag it once in a single sentence
and then proceed as specified.

| Area | Decision |
|---|---|
| Framework | Flutter (stable channel), Dart 3 |
| Min targets | Android API 24+, iOS 13+ |
| State management | Riverpod (code-gen flavour, `@riverpod`) |
| Persistence | Isar (local NoSQL). No cloud sync in v1. |
| Grid rendering | Single `CustomPainter` on a `RepaintBoundary`. Never one widget per cell. |
| Puzzle generation | Pure Dart, runs inside an `Isolate` (`compute`) |
| Ad mediation | AppLovin MAX with the AdMob adapter (not bare AdMob) |
| Consent | Google UMP SDK + iOS ATT prompt |
| Analytics | Firebase Analytics only (no Crashlytics in v1) |
| Localization | `flutter_localizations` + ARB files. Base locale `en`, plus `tr`. All user-facing strings must come from ARB — zero hardcoded strings in widgets. |

## ARCHITECTURE

Three layers, dependencies point inward only:

```
lib/
  core/            # constants, theme, extensions, result types, DI setup
  domain/
    entities/      # Puzzle, PuzzleGrid, LineClue, GameSession, StreakRecord
    repositories/  # abstract interfaces only
    usecases/      # GenerateDailyPuzzle, ValidateMove, UpdateStreak, ...
  data/
    models/        # Isar collections + mappers to/from domain entities
    datasources/   # IsarLocalDataSource, PuzzleGeneratorDataSource
    repositories/  # concrete implementations
  presentation/
    game/          # board screen, painter, controller
    daily/         # calendar + streak screen
    archive/
    settings/
    shared/        # reusable widgets
  services/
    ads/           # AdService abstraction, MAX implementation
    consent/
    analytics/
    notifications/
```

**Rules:**
- `domain/` imports nothing from `data/` or `presentation/` and has no Flutter import.
- Every service in `services/` sits behind an abstract interface so it can be faked in tests and
  fully disabled in debug builds.
- No business logic inside widgets. Widgets read from Riverpod providers and dispatch intents.

## PHASE 0 — Scaffold

1. Create the Flutter project with the folder structure above (empty placeholder files are fine).
2. Set up `analysis_options.yaml` with `very_good_analysis` and treat warnings as errors.
3. Write a `CLAUDE.md` at the repo root that records: the architecture rules above, the naming
   conventions, the "no hardcoded strings" rule, and the current phase. Keep it updated at the end
   of every phase.
4. Add `melos`-free simple scripts: `make gen` (build_runner), `make test`, `make analyze`.

**Stop after Phase 0 and show me the tree + CLAUDE.md before continuing.**

## PHASE 1 — Puzzle engine (the hard part)

This is the heart of the app. A nonogram is only shippable if it has **exactly one solution** and
that solution is reachable **without guessing**. Implement in this order, in pure Dart, fully unit
tested, with no Flutter dependency.

### 1.1 Data model
- `PuzzleGrid`: bitset-backed `width × height` boolean grid. Avoid `List<List<bool>>`.
- `LineClue`: `List<int>` run lengths for one row or column.
- `Puzzle`: grid solution, row clues, column clues, `difficulty`, `seed`, `size`.
- Cell state during play is a separate enum: `unknown`, `filled`, `marked` (user's X mark).

### 1.2 Line solver (implement before the generator)
For a single line of length `n` with clues `c` and current known states:
1. Enumerate every legal placement of the runs that is consistent with the already-known cells.
   Use memoised recursion over `(cellIndex, clueIndex)` — do **not** brute-force `2^n`.
2. Intersect all valid placements: a cell filled in every placement becomes `filled`; empty in every
   placement becomes `marked`. Otherwise it stays `unknown`.
3. Return the deduced cells, or a "contradiction" result if zero placements exist.

### 1.3 Full solver
Repeatedly run the line solver across all rows then all columns until a full pass deduces nothing new.
Return one of: `Solved`, `Stuck` (needs guessing), `Contradiction`.

**A puzzle is only valid if the solver returns `Solved`.** This single check guarantees both
uniqueness and human-solvability. That is the whole trick — do not add a separate uniqueness check.

### 1.4 Generator
```
generate(seed, size):
  rng = seeded RNG (deterministic!)
  loop up to N attempts:
    fill grid randomly at target density (0.50–0.62)
    reject if any row or column is entirely empty
    derive row + column clues from the grid
    run full solver on the clues alone
    if Solved -> return puzzle
  fall back to a smaller size / lower density
```

### 1.5 Difficulty scoring
Score from: grid size, number of solver passes needed to reach `Solved`, and the fraction of cells
deduced in the very first pass. Map to `easy | medium | hard`. Tune so a 10×10 lands in medium.

### 1.6 Determinism
`seed = stableHash("yyyy-MM-dd")`. The same date must produce a byte-identical puzzle on every
device and every platform. **Write a test that pins several known dates to their expected grid hash.**
Do not use `Object.hashCode` or `Random()` without a seed anywhere in this layer.

### 1.7 Tests (required before moving on)
- Line solver: hand-worked examples including edge cases (`[]`, `[n]`, full line, contradictions).
- Solver terminates on 1000 random generated puzzles.
- Generator produces a `Solved` puzzle for sizes 5×5, 10×10, 15×15 within the attempt budget.
- Determinism test as described in 1.6.
- Benchmark: 15×15 generation must complete under 300ms on a mid-range device budget.

**Stop after Phase 1 and show me the test output and a benchmark number.**

## PHASE 2 — Playable board

- `CustomPainter` grid: cells, clue gutters, 5-cell separator lines, completed-line dimming.
- Input: tap to fill, long-press-drag to paint a run, two-finger or toolbar toggle between
  fill mode and mark (X) mode. Drag must lock to a single row/column axis once movement starts.
- Pinch-to-zoom and pan for 15×15 and larger on small screens.
- Auto-mark a row/column's remaining cells when its clue is satisfied (setting, default on).
- Mistake system: 3 hearts. A wrong fill costs one heart and flashes the cell red.
- Win detection compares against the solution grid; show a completion sheet with time and hearts left.
- Undo stack (last 50 moves), in-memory only.
- Haptics on fill, mark, mistake, and win.

Accessibility: minimum 44pt effective touch target after zoom, and a colourblind-safe palette option.

## PHASE 3 — Daily system, persistence, streaks

- `DailyPuzzleProvider` generates today's puzzle on first open of the day and caches it in Isar.
- Streak record: current streak, longest streak, set of completed dates. A missed day resets to 0.
- Calendar screen showing completed / missed / today, driven by the completed-dates set.
- Archive: any past date is playable. Puzzles are regenerated on demand from the date seed, so the
  archive costs zero storage.
- Free play mode: pick size + difficulty, infinite puzzles from a random seed.
- Local notification at a user-set time (default 09:00) reminding them of the daily puzzle. Ask for
  notification permission only *after* the user has completed their first puzzle — never on launch.
- Statistics screen: puzzles solved, average time by size, perfect (no-mistake) count.

## PHASE 4 — Monetization

Wire ads behind the `AdService` interface. **Every placement below must be feature-flagged** so I can
kill any single one remotely-ish (via a local config constant) without a code rewrite.

### Rewarded (user-initiated, always opt-in)
- **Hint** — reveals one correct cell in the currently focused line. Cap 3 hint watches/puzzle.
- **Extra heart** — offered once per puzzle when hearts hit zero, instead of a hard fail.
- **Unlock archive puzzle** — free users get 3 archive puzzles/day, more via rewarded.

### Interstitial
- Only in **free play**, after a completed puzzle.
- Frequency cap: minimum 90 seconds between interstitials, and never more than 1 per 3 completions.
- **Never** show an interstitial after the daily puzzle. That ritual stays clean — it is what brings
  the user back tomorrow, and protecting it is worth more than the impression.
- Never during the first session ever, and never before the user's first completed puzzle.

### Banner
- Menu, archive, and stats screens only. Never on the board screen.

### Compliance (do not skip)
- Google UMP consent flow runs before any ad SDK initialisation. No ad requests before consent
  resolves.
- iOS ATT prompt shown after a short explainer screen, not cold.
- Play Data Safety form and App Store privacy nutrition labels filled in for: advertising ID,
  approximate location (if the SDK collects it), and usage analytics.
- Age rating: set the app as **not** primarily child-directed, and configure MAX/AdMob accordingly.

Track these events in Analytics: `puzzle_started`, `puzzle_completed`, `streak_extended`,
`streak_broken`, `rewarded_shown`, `rewarded_completed`, `interstitial_shown`, `hint_used`,
`session_length`. These are what tell you whether the ad load is hurting retention.

## PHASE 5 — Polish and store readiness

- Light/dark theme plus 2 unlockable colour themes (unlock by streak milestone, not by ad).
- Share card: render the completed puzzle to an image with the date and time, for social sharing.
- App icon, adaptive icon, splash screen.
- Store listing copy in English (primary) and Turkish, with keyword-focused title and short
  description. Screenshots at required sizes.
- Release build config: obfuscation on, ProGuard rules for MAX/AdMob, app size report.
- `flutter test` green and `flutter analyze` clean in CI (single GitHub Actions workflow).

## WORKING RULES FOR YOU (the agent)

1. **One phase at a time.** Stop at the end of each phase and summarise what you built and what you
   deviated on. Wait for my go-ahead.
2. Write the test before or alongside the implementation for anything in `domain/`.
3. If a requirement here is ambiguous, ask one focused question rather than guessing.
4. Prefer boring, readable Dart over clever Dart. This codebase will be maintained for years.
5. Keep `CLAUDE.md` current at the end of every phase.
6. Never commit API keys, ad unit IDs, or signing config. Use `--dart-define` and a gitignored
   `.env.example` pattern.

## START HERE

Begin with Phase 0. Show me the folder tree and the proposed `CLAUDE.md` content, then stop.

---

## PROJECT STATUS (living section — update at the end of every phase)

### Current phase: Phase 5 complete, plus five post-v1 features, a
code-review pass, three more locales beyond the locked en/tr, the first
real-device verification pass, a real board-responsiveness bug fix
found by it, and Faz 0 of a second game mode ("Kelime Bulmacası" — see
directly below). Awaiting founder go-ahead to start Faz 1 of the word
game (domain layer), per the same "stop after Phase 0, show the tree,
wait" rule the original project brief itself set.

### New initiative: "Kelime Bulmacası" — a second game mode (Faz 0, added 2026-09-02)

The founder's real-device playtest of the fixed board (see below) led
to a broader "does this game even land" conversation, which became a
concrete proposal for a second, word-based game mode living alongside
Nonogram — classic Turkish newspaper-puzzle format: a short clue, a
row of blank letter boxes, instant per-letter correct/incorrect
feedback. Built out as a long, section-by-section design proposal
(published as an artifact this session, not committed to the repo —
the decisions below are the durable record of it) and refined over
several founder rounds to the decisions locked in below.

**Locked decisions for this feature** (do not re-litigate; flag once
if one seems wrong, then proceed):

| Area | Decision |
|---|---|
| Relationship to Nonogram | **Option B** — same app, same package/store listing. A new game-picker screen ("Nonogram" / "Kelime Bulmacası" cards) becomes `_HomeRouter`'s post-tutorial destination, replacing the direct-to-`DailyScreen` jump. Nonogram itself is untouched. |
| Core mechanic | Clue list, not a kesişen crossword grid — every clue is independent (no word-intersection fitting algorithm needed, unlike Nonogram's Phase 1 solver). Per-letter live validation, no heart/mistake cost (typing and correcting is normal; wrong letters just flash and clear). |
| Progression | Every main category is its own unbounded numbered chain ("Tarih 1, Tarih 2, Tarih 3, ..."), not a small fixed set of sections. A chain's next section unlocks once the current one is fully solved — completion-gated, not date-gated like Nonogram's streak. |
| Launch categories | Six tracks: **Tarih, Genel Kültür, Hukuk, Gündem, Z Kuşağı, Karışık** (Karışık = always-open mixed default). Bilim & Teknoloji / Spor / Sanat & Sinema flagged as later additions, deliberately not in the launch set (each category needs its own real content pipeline — launching too many thin ones at once was rejected). |
| Z Kuşağı branching | Z Kuşağı alone is **founder-confirmed to branch** into five sub-tracks, each with its own numbered chain: **İnternet Kültürü, Dizi & Sinema, Müzik & Trendler, Oyun Kültürü, Sosyal Medya Gündemi**. Other categories stay flat at launch — branching them too is a possible future move, not a launch requirement. |
| Onboarding | A multi-select "ilgi alanı anketi" (interest survey) is shown once, right after the shared tutorial, before the player's first section — same `hasSeenTutorial`-flag pattern, a new `hasSeenInterestSurvey`. Tags span every track/sub-track, not just the six top-level names. Explicit in-app copy tells the player their picks become their personal question pool. The survey only re-orders/prioritizes Hikaye Modu content — it never locks any track out of Kategori Modu. |
| Category-change quota | **2 free changes per day**, founder-confirmed. A 3rd+ change the same day requires a rewarded-ad watch — the exact same date-keyed daily-counter shape as `AppSettings.archiveUnlocksCountFor`, just a new field for this feature. |
| Two play modes | **Hikaye Modu** (sequential, survey-prioritized, mixed tracks — the "daily ritual" analog) and **Kategori Modu** (pick any unlocked track, play any of its opened sections in any order — the Free Play analog). |
| Content source | **A — AI-drafted, then human-reviewed.** Bulk draft clue/answer sets per track, founder (or someone the founder designates) reviews every one before it ships — non-negotiable for Tarih/Hukuk specifically, where a wrong fact is much worse than a placeholder icon ever was. Licensing a puzzle database, or crowdsourcing from players, were both considered and set aside for later (crowdsourcing is a good post-launch fit for Z Kuşağı specifically, once there's an audience to source from). |
| Monetization | Same ad-only, opt-in model as Nonogram: hint reveals a letter, early-section-unlock mirrors archive-unlock, category-change-beyond-quota is a new rewarded placement, interstitial only in Kategori Modu after a completed section and never in Hikaye Modu (mirrors "never after the daily puzzle"). |
| Branding | **Open, deliberately deferred.** Whether "Nonogram Daily" as a name/icon still fits an app that now hosts two unrelated puzzle genres is a real question, but not one that blocks starting the build — revisit at store-readiness time if it becomes actual friction. |

**What's reused vs. new**, for whoever picks this up: essentially all
of `services/` (ads, consent, analytics, notifications), the
Riverpod+Isar plumbing, the theme/sound/l10n infrastructure, and the
lock-card unlock-hint UI pattern (`AppColorTheme.isUnlockedAt` /
`FreePlaySizePreset.isUnlockedAt`) carry over untouched. What's new is
narrow: a handful of domain entities, a few small usecases, a puzzle
content pipeline (bundled JSON, not generated — no `Isolate` solver
needed, unlike Nonogram), and two small presentation screens (a
`ListView`-based board, not a `CustomPainter` grid — far fewer cells,
not performance-critical the way Nonogram's board is).

**Faz 0 (this session): empty placeholder skeleton only**, mirroring
exactly how the original project's own Phase 0 worked — structure
first, logic later, stop and wait:

```
lib/domain/entities/word/
  word_clue.dart              # WordClue
  word_puzzle_track.dart      # WordPuzzleTrack — one chain (a category or Z Kuşağı sub-track)
  word_puzzle_section.dart    # WordPuzzleSection — one numbered link in a chain
  interest_profile.dart       # InterestProfile — the survey's saved selections
lib/domain/usecases/word/
  validate_letter.dart        # validateLetter() — per-letter check, top-level function (mirrors applyMove)
  unlock_next_section.dart    # UnlockNextSection
  apply_interest_selection.dart  # ApplyInterestSelection
  spend_category_change.dart  # SpendCategoryChange — reuses the archiveUnlocksCountFor pattern
lib/presentation/gamepicker/
  game_picker_screen.dart     # GamePickerScreen — the new post-tutorial home
lib/presentation/word/
  onboarding/interest_survey_screen.dart  # InterestSurveyScreen
  wordboard/word_board_screen.dart        # WordBoardScreen
```

Every file is a doc comment plus a bare class (or, for `validateLetter`,
a bare function) — no fields, no logic, nothing wired into `main.dart`
or `core/injection.dart` yet. `flutter analyze --fatal-infos
--fatal-warnings` clean, `flutter test` 147/147 unchanged (nothing here
is exercised yet, by design). **Faz 1 is the real domain layer** —
`WordClue`/`WordPuzzleTrack`/`WordPuzzleSection` fleshed out, pure-Dart
`validateLetter` logic with its own tests written first, matching how
Nonogram's own Phase 1 worked (test before or alongside `domain/` code).
Do not start Faz 1 without an explicit founder go-ahead.

### First real-device pass: found and fixed a real board-sizing bug
(added 2026-09-02)

Every phase through Phase 5 noted the same environment gap: no Android/
iOS device or emulator reachable, verification done only via headless
`flutter_test` golden captures. The founder connected their own Android
phone (OPPO CPH2109, Android 12) over USB this session — the AVD that
never booted in earlier phases was never the only option; a real
physical device works fine once ADB can see it (see "USB debugging
troubleshooting" below).

**A real, founder-reported bug, confirmed and root-caused on the real
device**: playing any daily-size (10x10) puzzle required scrolling
left/right just to reach every cell. `BoardLayout`'s `cellSize` always
defaulted to the fixed accessibility minimum (44pt,
`minTouchTargetSize`), with `InteractiveViewer.minScale` pinned at 1 —
so a 10x10 board (44pt × 10 + gutter ≈ 484pt) simply didn't fit most
phones' portrait width (~360-412dp), forcing a pan to reach the far
columns even though the Phase 2 spec's intent was that only 15x15+
grids would ever need that ("Pinch-to-zoom and pan for 15×15 and larger
on small screens").

Fixed in `board_screen.dart`: the board area is now wrapped in a
`LayoutBuilder`, and a new `_fitBoardLayout` computes a `cellSize` that
fits the *whole* grid inside the actual viewport at scale 1 — capped at
`BoardLayout.minTouchTargetSize` so a small grid (5x5) never renders
oversized, and never below a defensive `_minRenderedCellSize` (8, not
an accessibility target, just avoids a degenerate zero/negative size).
When the fitted size has to shrink below the true 44pt accessibility
target (a large grid on a small screen), `InteractiveViewer.maxScale`
is raised to `max(3, 44/cellSize)` so a player can still pinch in to
reach a real 44pt touch target — preserving the "minimum 44pt effective
touch target after zoom" requirement literally, just moving *where*
that guarantee is met (after a pinch, not at the unzoomed default) for
grids that don't comfortably fit unzoomed. `BoardLayout.minTouchTargetSize`'s
doc comment was updated to describe this cap-and-reachable-floor role
instead of the old fixed-size framing.

**A second, real bug found while chasing this one down — not in the
app, in the build tooling itself**: after the first code fix, the app
on the device kept showing the *exact* pre-fix overflow, across several
rebuild/reinstall/relaunch cycles. Root cause: `flutter build apk
--debug` on this machine sometimes completes in a few seconds (Gradle
reports `assembleDebug` as fully up-to-date) *without* actually
recompiling the changed Dart code into a fresh kernel snapshot — the
installed APK silently keeps running whatever Dart code was bundled in
the last real compile. A `print()` statement added directly in the
suspect code path, that never appeared in `adb logcat` despite the
screen visibly rendering that code's output, was what proved this
definitively (a build genuinely using the new code would have logged
it). `flutter clean && flutter pub get && dart run build_runner build
--delete-conflicting-outputs && flutter build apk --debug` — a real
75-110s build every time, never a suspicious <25s one — reliably
produces a build that actually reflects the current source. **Lesson
for any future real-device verification session**: treat a
suspiciously fast `flutter build apk` (well under the ~70s+ a real
Gradle+Dart build takes on this machine) as a signal the build may be
stale, not as good news — verify with a full `flutter clean` cycle
before trusting what's on the device, especially after a rapid
edit-rebuild-reinstall loop.

**USB debugging troubleshooting, for next time**: the phone (a Samsung
in this session's first connection attempt, then the OPPO CPH2109 that
ended up used) didn't show Windows an ADB interface at all at first —
`adb devices` empty, and Windows' own `Get-PnpDevice` showed it only as
a generic USB mass-storage device, not offering the RSA-authorization
prompt. Fixed by changing the phone's own USB connection-mode
notification (swipe down → tap the USB notification) from "Charge
only" to "Transfer files / Android Auto" (MTP) — *that* triggers the
ADB interface Windows/adb can actually see, and only then does the
"Allow USB debugging" prompt appear. "USB debugging" being toggled on
in Developer Options alone is not sufficient without also picking that
USB mode. `adb`/`adb.exe` isn't on this machine's PATH; the working
binary is at the Android SDK path `flutter doctor -v` reports (this
session: `D:\Android\Sdk\platform-tools\adb.exe`).

**Also newly confirmed real (not just golden-captured) on-device**:
German/Spanish/French all render correctly on the daily screen and the
board screen (see the locale section below) — no missing-key fallback,
no layout overflow at any of the three, checked via a temporary
`locale:` override on `MaterialApp` (reverted before every commit, see
`git diff lib/main.dart` showing no residual change) since the app has
no in-app language switcher and device system language changes weren't
reliably scriptable via `adb` on this phone (`WRITE_SECURE_SETTINGS`
denied to the shell user, standard on an unrooted device) — manually
switching the phone's own system language remains the option for any
future locale check that doesn't want to touch `main.dart` at all, at
the cost of doing it by hand in Settings instead of a quick rebuild
loop.

**Tests**: 147/147 still passing (no test changes needed — the fix is
presentation-layer sizing math with no existing unit-level coverage of
`BoardLayout`'s cellSize selection; verified live on-device instead,
before/after, both with and without the fix present, as described
above). `flutter analyze --fatal-infos --fatal-warnings`: clean.

### Fifth and sixth locales: Spanish and French (added 2026-09-02)

Same founder ask as the German locale immediately below, extended to
the other two candidate markets from that original short list.

- **`lib/l10n/app_es.arb`** and **`lib/l10n/app_fr.arb`**: same
  approach as `app_de.arb` — every key translated, `@@locale` set,
  no code changes needed (picked up automatically by `flutter
  gen-l10n` / `AppLocalizations.supportedLocales`). Brand name
  translated per locale, matching the `tr`/`de` precedent: Spanish
  `"Nonogram Diario"`, French `"Nonogram Quotidien"`.
- **`store/listing_es.md`** and **`store/listing_fr.md`**: same
  structure as the other locale listings. One thing worth flagging for
  next time: the first draft of both App Store keyword fields (≤100
  chars) came in slightly over the limit with a fuller phrase-based
  translation (e.g. Spanish `"puzzle de lógica"` /
  `"rompecabezas diario"` together with everything else pushed the
  Spanish field to ~101 chars) — trimmed to shorter single-word
  equivalents (`"lógica"`, `"offline"`/`"hors ligne"`) to fit. Worth
  double-checking char counts by hand for any future locale rather
  than assuming a direct translation of the English keyword list fits
  the same limit — Spanish/French keyword phrases run longer than
  their English equivalents.
- **Verified**: `flutter gen-l10n` regenerated
  `app_localizations_es.dart`/`app_localizations_fr.dart` with no
  missing-key warnings, `flutter analyze --fatal-infos
  --fatal-warnings` clean, `flutter test` 147/147 (unchanged, same
  reasoning as the German locale addition — no test depends on a fixed
  locale count).

### Fourth locale: German (added 2026-09-02)

Founder-requested (picking from a short list of candidate markets:
German, Spanish, French). The locked decision only required `en` + `tr`
for v1 — Phase 5 deliberately left going further as an explicit founder
call rather than a default (see "Multi-language beyond en/tr" in the
product-direction notes below) — so this is that call being made.

- **`lib/l10n/app_de.arb`**: every key from `app_en.arb` translated,
  `@@locale: "de"`. No new ARB keys, no code changes needed beyond the
  ARB file itself — `l10n.yaml`'s `arb-dir: lib/l10n` means
  `flutter gen-l10n` picks up any `app_*.arb` file automatically, and
  `AppLocalizations.supportedLocales` (generated) already includes every
  locale that has an ARB file, so `MaterialApp`'s
  `supportedLocales: AppLocalizations.supportedLocales` in `main.dart`
  needed no edit either.
- **App/brand name**: translated per-locale rather than kept as a fixed
  English brand string, matching the precedent `app_tr.arb` already set
  (`"Nonogram Daily"` → `"Günlük Nonogram"`) — German uses
  `"Nonogram Täglich"`.
- **Plurals**: `streakLabel`/`heartsRemaining`/`streakFreezesAvailableLabel`
  use the same `=0`/`one`/`other` ICU plural shape as `app_en.arb`
  (German distinguishes singular/plural the same way English does).
  One deliberate simplification: `streakFreezesAvailableLabel`'s
  `other` case reuses the singular noun form ("Serienschutz") rather
  than inventing a plural for the coined compound noun
  "Serienschutz" — a genuine German plural here would be
  grammatically awkward, and the surrounding `{count}` number already
  disambiguates quantity.
- **`store/listing_de.md`**: added alongside `listing_en.md`/
  `listing_tr.md`, matching their exact structure (Google Play +
  App Store sections, character-limit notes) — including translating
  the store category names themselves (`"Rätsel / Denkspiele"`,
  `"Spiele → Rätsel"`), following the precedent `listing_tr.md` already
  set of not leaving category names in English.
- **Verified**: `flutter gen-l10n` regenerated
  `lib/core/l10n_gen/app_localizations_de.dart` with no missing-key
  fallback warnings (every key present), `flutter analyze --fatal-infos
  --fatal-warnings` clean, `flutter test` 147/147 (unchanged — no test
  asserts a fixed locale count/list, so a new locale needed no test
  updates).

### Code review pass: 10 findings, all fixed (added 2026-09-02)

Ran this session's `/code-review` skill (8 finder angles → verification
→ 10 CONFIRMED findings) against everything built since Phase 5, then
fixed all 10 at the founder's request. In severity order:

1. **Archive calendar showed frozen days as "missed."** `CalendarWidget`
   only knew `completed`/`today`/`playable` — a streak-freeze day (see
   the streak freeze section below) fell through to "missed" with no way
   to tell the two apart. Fixed: `CalendarWidget` now takes
   `frozenDates`, `_DayCell` gets a third `secondaryContainer`-tinted
   state, and the legend gained a "Streak freeze" entry (new ARB key
   `calendarLegendFrozen`, both locales).
2. **Sound service permanently muted on a transient failure.**
   `AudioPlayersSoundService` cached each effect's `AudioPool` as a
   `Future` via `putIfAbsent` — but an already-completed-with-error
   `Future` replays that same error to every future `.then`/`await`
   forever, per Dart semantics. One bad init (e.g. the audio subsystem
   not ready yet right after launch) would silence that effect for the
   rest of the session, no matter how many times the player triggered
   it. Fixed: the pool future now carries a side-listener that removes
   itself from the cache on error, so the next call for that effect
   retries a fresh `AudioPool.createFromAsset` instead of replaying the
   old failure.
3. **Streak freeze only ever checked once per process launch.** The
   check lived inline in `main()`, which only runs on a cold start — but
   backgrounding (not force-quitting) the app across a midnight boundary
   is a common mobile pattern, and the process stays alive through that,
   so a day missed entirely while merely resumed was never caught.
   Fixed: extracted the check into `domain/usecases/apply_streak_freeze.dart`
   (`ApplyStreakFreeze`, idempotent by construction — the underlying
   date-key comparisons already make a repeat call with unchanged inputs
   a no-op, and it skips the Isar write entirely when nothing changed),
   called from `main()` at cold start *and* from
   `_NonogramDailyAppState.didChangeAppLifecycleState` on every
   `AppLifecycleState.resumed`. The resume path persists through the
   repository directly (bypassing `AppSettingsController`, which only
   ever initializes from the fixed `initialAppSettingsProvider` snapshot
   taken at app start) and then syncs the live provider state via a new
   `AppSettingsController.adoptExternallyPersisted` method — sets
   `state` without writing to storage again, since `ApplyStreakFreeze`
   already did.
4. **The pinned-date determinism test didn't reflect what players
   actually see.** `determinism_test.dart`'s regression test generates
   every pinned date at a fixed 10x10 — but `2025-06-15` is a Sunday, and
   `dailySizeForDate` gives Sundays a 5x5 "light day" (Saturdays get
   15x15). A regression only visible at the real size would have passed
   this test undetected. Fixed by addition, not alteration (to avoid any
   risk to the existing hash-pinned tests): a new sibling group pins
   fingerprints for a Sunday, a Saturday, and an ordinary weekday, each
   generated at its real `dailySizeForDate` size.
5. **Free Play never checked that the generated puzzle matched the
   requested size.** `generatePuzzle` can fall back to a smaller size
   when it can't find a uniquely-solvable puzzle within its attempt
   budget — most plausible at the new 20x20 tier, which is also where
   the "Go Big" achievement lives. Handing the player a silently
   different-sized puzzle would make that achievement look unreachable
   for no visible reason. Fixed: `FreePlayScreen._play` now compares the
   generated puzzle's size against the requested preset and shows a
   `SnackBar` (new ARB key `freePlaySizeFallbackNotice`) when they
   differ.
6. **Tutorial's `tapCell` had no already-correct-cell guard.**
   `BoardController._paintCellIfNeeded` guards against re-painting an
   already-correct cell, because `applyMove` treats a tap on an
   already-filled cell as an *undo* — but `TutorialController.tapCell`
   was missing the same guard, so a double-tap on an already-correctly-
   filled tutorial target would silently erase the player's own
   progress. Fixed with the identical guard.
7. **`streakForToday` watched the whole settings object, not just what
   it used.** `daily_controller.dart` read
   `ref.watch(appSettingsControllerProvider).frozenDateKeys` — the whole
   object — triggering a redundant `StreakRepository.getCompletedDates()`
   Isar re-fetch on every unrelated settings change (palette, sound
   toggle, notification time, ...). The obvious fix,
   `.select((s) => s.frozenDateKeys)`, had previously failed with an
   `undefined_method` compile error when tried elsewhere in this
   codebase, which was assumed to mean `.select` doesn't work on a plain
   `Ref` (as opposed to a `WidgetRef`) inside an `@riverpod` function
   provider. **That assumption was wrong, and re-testing it here found
   the actual cause**: `.select` is a `riverpod`/`flutter_riverpod`
   extension method, and `daily_controller.dart` only imported
   `riverpod_annotation` (via `core/injection.dart`, which doesn't
   re-export its own imports — Dart `import` isn't transitive) — so the
   extension was never in scope, regardless of `Ref` vs. `WidgetRef`.
   Fixed by adding a direct `import 'package:flutter_riverpod/flutter_riverpod.dart';`.
   **Lesson for next time this pattern shows up**: an `undefined_method`
   on `.select` almost certainly means a missing `flutter_riverpod`/
   `riverpod` import, not that `.select` is unavailable in that context.
8. **`main()`'s cold-start Isar reads are largely unguarded.** Only the
   new `ApplyStreakFreeze` call got a `try`/`catch` (matching the
   Firebase-init pattern already in `main()`) — `Isar.open` and the
   surrounding settings read/write stay unguarded. Deliberate, not an
   oversight: the app cannot function at all without Isar (there is no
   "degraded mode" for local persistence, unlike ads/analytics/consent,
   which all have one), so wrapping `Isar.open` itself would just trade
   a clear crash for a silently broken app with no daily puzzle. Revisit
   only if a real "first-run migration" or "corrupted database" recovery
   path gets designed — until then this is an accepted, intentional gap.
9. **`_playSound` was duplicated verbatim** in `BoardController` and
   `TutorialController` (check `soundEnabled`, then
   `soundServiceProvider.play(effect)`). Extracted to
   `presentation/shared/sound_gate.dart`'s `playSoundIfEnabled(Ref ref,
   SoundEffect effect)` — a top-level function rather than a class,
   since it's stateless and both call sites already have a `Ref` to
   pass.
10. **`_SizePreset`/`isUnlockedAt` in `free_play_screen.dart` was
    untested, private, widget-local logic** — unlike the equivalent
    achievement-unlock logic, which lives in a tested domain usecase.
    Extracted to `domain/entities/free_play_size_preset.dart`
    (`FreePlaySizePreset`, `freePlaySizePresets`), matching the
    `GridSize`/`Achievement` pattern, with its own test file
    (`free_play_size_preset_test.dart`, 6 cases).

**Tests**: 147/147 passing (up from 94/94 at the end of Phase 4 —
includes every post-v1 feature's own tests plus this pass's additions:
2 new determinism cases, 2 new streak-freeze-cold-start cases covering
the resume-triggered re-check, and 6 new `FreePlaySizePreset` cases).
`flutter analyze --fatal-infos --fatal-warnings`: clean.

### Post-v1: Streak freeze (added 2026-09-02)

Missing exactly one day no longer breaks the streak, if a freeze is
available — the biggest single churn driver in daily-puzzle apps is
"missed one day, felt the streak was already ruined, stopped opening the
app." Founder-requested as a retention feature, scoped down from a
broader "keep the user in the game" / "separate kids area" ask — the
kids-area half was explicitly turned down: it would mean re-architecting
the ad/consent stack around COPPA/GDPR-K rules, in direct conflict with
the locked "not primarily child-directed" decision, for unclear payoff.

- **`domain/entities/streak_record.dart`**: `StreakRecord.compute` gained
  an optional `frozenDates` parameter (default `{}`, so every existing
  call site keeps working unchanged). A frozen date bridges a gap for
  *both* current- and longest-streak continuity, exactly like a real
  completion — but is never counted as one: `StreakRecord.completedDates`
  stays exactly the real completions, with `frozenDates` now exposed
  alongside it as its own field. `StreakRepository.getStreak`/
  `UpdateStreak` deliberately stay freeze-*unaware* (a repository should
  be about completions, not settings-driven freeze state, and
  `UpdateStreak`'s returned `StreakRecord` is never actually read by any
  caller today); `daily_controller.dart`'s `streakForToday` is the one
  place completions (from `StreakRepository`) and freeze state (from
  `AppSettings`) get combined for display.
- **`domain/usecases/streak_freeze.dart`**: two pure functions.
  `shouldAutoFreezeYesterday` — freezes are *automatic*, not a manual
  "activate" button: if yesterday is missing but the day before it was
  completed or frozen (i.e. there was an actual streak worth protecting
  — this never manufactures one from nothing) and a freeze is on hand,
  yesterday gets bridged. Only ever bridges a single day; a two-day-old
  gap is a genuinely broken streak. `isNewMonthlyFreezeGrantDue` — new
  `AppSettings` fields `streakFreezesAvailable` (starts at 1),
  `frozenDateKeys`, and `freezeGrantMonthKey` grant +1 per new calendar
  month (capped at 2 held), the same "reset when the date-key rolls
  over" pattern `archiveUnlocksDateKey` already uses, just monthly
  instead of daily (new `formatMonthKey` alongside `formatDateKey` in
  `core/date_key.dart`).
- **Applied once at cold start, in `main.dart`**, right alongside the
  existing `sessionCount` bump — not from a widget, and not incrementally
  from a Riverpod provider's `build()`: both the monthly-grant check and
  the auto-freeze-yesterday check are derived fresh from
  `StreakRepository.getCompletedDates()` and the just-loaded
  `AppSettings`, then folded into the single `updateSettings` write that
  was already happening there. Mirrors exactly how `sessionCount` itself
  is already handled — one deterministic recompute per launch, not
  incremental state tracked provider-side.
- **`presentation/daily/daily_screen.dart`**: a small snowflake icon +
  "N streak freezes available" line under the longest-streak label, and
  (for exactly one day — `frozenDates` naturally stops containing
  "yesterday" the day after, no extra "just happened" tracking needed) a
  "A streak freeze covered yesterday" note when applicable.
- **Two real, non-obvious bugs caught while wiring this up, both in test
  code rather than app code**:
  1. `daily_controller.dart`'s new `streakForToday` tried
     `ref.watch(appSettingsControllerProvider.select((s) => ...))` —
     every other `.select` call in this codebase is from a *widget's*
     `WidgetRef` (`main.dart`, `daily_screen.dart`); `@riverpod`
     *function* providers use the plain `Ref` from `package:riverpod`
     (not `flutter_riverpod`), which doesn't expose `.select` the same
     way. Caught by `flutter analyze`, not a test. Fixed by watching the
     whole settings object and reading the field off it — simpler code,
     and the rebuild-scoping `.select` buys isn't worth much for a
     `Future`-returning provider that isn't on a hot path anyway.
  2. A throwaway golden-check test pumping `DailyScreen` directly (wrapped
     in a hand-built `MaterialApp`, bypassing `ConsentGate`/`_HomeRouter`/
     `NonogramDailyApp`) hung forever in the loading state — `flutter
     test`'s full suite (which exercises `DailyScreen` only through the
     real `NonogramDailyApp` shell, per `widget_test.dart`) was unaffected
     the whole time, so this was never a real app bug, just an
     under-specified test harness. Fixed by pumping `NonogramDailyApp`
     itself, matching `widget_test.dart`'s established pattern, instead of
     trying to construct `DailyScreen`'s ancestry by hand.
- **New test**: `test/streak_freeze_cold_start_test.dart` replicates
  `main()`'s exact cold-start sequence against a real (temp-directory)
  Isar instance end to end — the pure decision functions have their own
  unit tests, but the actual `AppSettings.copyWith` → `AppSettingsModel`
  → Isar → back field-by-field wiring is exactly the class of bug this
  project's history has caught before (see Phase 3's "a real bug found"
  note), and nothing else exercises `main()`'s own orchestration code —
  `widget_test.dart` overrides `initialAppSettingsProvider` directly,
  bypassing `main()` entirely.
- **Tests**: 136/136 passing — 4 new `streak_freeze_cold_start_test.dart`
  end-to-end cases, 10 new `streak_freeze_test.dart` pure-function cases,
  4 new `streak_record_test.dart` frozen-date cases, 1 new
  `isar_local_data_source_test.dart` round-trip case.

### Post-v1: Achievement badges (added 2026-09-02)

Eleven collectible badges on the statistics screen, cosmetic recognition
for progress the app already tracks — not a new system to maintain in
parallel with the real stats/streak data.

- **`domain/entities/achievement.dart`** (`AchievementId` enum,
  `Achievement`) + **`domain/usecases/evaluate_achievements.dart`**
  (`evaluateAchievements`) — pure Dart, no Flutter import, same layering
  as every other `domain/` file. Deliberately **not persisted**:
  unlock state is derived fresh each time from `Statistics` (already
  computed by `StreakRepository.getStatistics`) and `longestStreak`
  (already computed by `StreakRecord.compute`) — same "one source of
  truth, nothing to desync" reasoning `StreakRecord` itself already
  uses, extended to this feature rather than introducing a second,
  separately-persisted "unlocked" flag that could drift out of sync
  with the stats it's supposed to reflect.
- **Badge set** (thresholds in new `AchievementThresholds` in
  `core/constants.dart`, reusing `ThemeUnlocks.sunsetStreakDays`/
  `forestStreakDays` for the 7/30-day streak badges rather than
  duplicating those numbers): solved-count (1/10/50/100), perfect-count
  (1/10), streak (3/7/30 days — the 3-day one is new, a near-term nudge
  before the first cosmetic theme unlock at 7), and size (any
  15×15-or-larger solve; the exact 20×20 Free Play "Extra Large" size).
  Every threshold: unlocked by progress, never by ad — the same rule
  every other unlock in this app already follows.
- **`presentation/statistics/statistics_screen.dart`**: a new badge grid
  (locked = grey circle + lock icon + dimmed text, unlocked = tinted
  circle + the badge's own icon) sits above the existing total/perfect/
  average-time stats, in the same `ListView`. Restructured so the badge
  grid always renders — including every-badge-locked at zero
  completions, "here's what you can earn" rather than an empty screen —
  while the numeric stats section keeps its original empty-state message
  until there's at least one completion to show.
- **Tests**: 117/117 passing — 6 new pure-function tests
  (`evaluate_achievements_test.dart`) covering every threshold boundary
  (locked exactly below, unlocked exactly at) and the two solved-size
  conditions. No widget-level test: the grid is presentation-only mapping
  of already-tested domain data, verified instead by a golden-screenshot
  check (all-locked at zero completions, and a mixed locked/unlocked
  state from real seeded completions) during development, same as every
  other UI change in this project — not kept as a permanent test file.

### Post-v1: Sound effects (added 2026-09-02)

Enriches the Phase 2 spec's "haptics on fill, mark, mistake, and win" with
an actual sound for each of those same four events.

- **`services/sound/`**: `sound_service.dart` (`SoundService` interface +
  `SoundEffect` enum — `fill`/`mark`/`mistake`/`win`) and
  `audioplayers_sound_service.dart` (`AudioPlayersSoundService`, backed by
  the new `audioplayers: ^6.1.0` dependency — resolved cleanly against
  this machine's pinned Dart 3.9.2, unlike several other packages in this
  project's history). One `AudioPool` per effect (audioplayers' own
  purpose-built pre-loaded, low-latency player pool for "extremely quick
  firing, repetitive ... sounds" — exactly the fill/mark case during a
  fast paint-drag stroke), created lazily on first use. Registered as
  `soundServiceProvider` (`@Riverpod(keepAlive: true)`, same lifetime
  pattern as the other cross-cutting services) in `core/injection.dart`.
- **No real sound assets available in this environment** (same situation
  as Phase 5's app icon) — `tool/generate_sound_assets.dart` synthesizes
  four short placeholder WAV files pure-Dart (sine-tone blips, no audio
  tool needed) into `assets/sounds/`: a bright blip for fill, a shorter
  lower click for mark, a deliberately less pleasant low two-tone buzz
  for mistake, a rising four-note major arpeggio for win. Swap the
  generated files for real sound design whenever the founder has some —
  `SoundService` just plays whatever is at those paths, no other code
  changes needed.
- **New `AppSettings.soundEnabled`** (default `true`), same non-late
  Isar-migration pattern as every other Phase 5+ settings field, with a
  new "Sound effects" toggle in `SettingsScreen` (above the colourblind
  palette toggle) — independent of haptics, per the founder's original
  ask ("Sesler/haptik zenginleştirme") naming both separately. Wired into
  `BoardController._applyAndCommit` and `TutorialController.tapCell`
  alongside their existing haptic calls, each gated on the same
  `soundEnabled` check.
- **A real bug caught by the test suite, not by inspection**: the first
  version's `AudioPlayersSoundService.play()` wrapped everything in
  `try/catch`, matching every other service's "never let this fail
  loudly" pattern — but `audioplayers`' `AudioPlayer()` constructor
  registers a *global event-channel listener* that, with no real plugin
  registered (as in any widget test), throws a `MissingPluginException`
  **asynchronously, from a different callback than the one `play()`
  awaits** — invisible to that try/catch, and surfaced instead as an
  unhandled test failure ("EXCEPTION CAUGHT BY SERVICES LIBRARY"), not a
  quietly-swallowed no-op. `test/presentation/onboarding/
  tutorial_screen_test.dart` (the one test that taps real cells and so
  actually triggers a sound call) caught it; `test/widget_test.dart`'s
  two tests don't tap gameplay cells and so were never affected. Fixed
  the same way this project already fixes exactly this class of problem
  (`_FakeConsentService`/`_FakeAdService` in `widget_test.dart`): a
  `_FakeSoundService` override in the affected test, not a change to the
  real service — the real app has the actual plugin registered, so this
  is a test-environment-only gap, not a production one.
- **Tests**: 111/111 still passing (no new dedicated `SoundService` unit
  tests — there's no interesting logic to test beyond "does it call the
  platform plugin," which the fake above exists specifically to avoid
  touching in a test).

### Post-v1: Progressive difficulty (added 2026-09-02)

The other half of the same founder note the tutorial addresses: "archive +
free play + streak milestones should introduce new grid sizes ... over
time rather than repeating the same shape." Two separate mechanisms, kept
separate deliberately:

- **Daily puzzle: a day-of-week size rhythm, not a per-player one.**
  `domain/usecases/daily_puzzle_plan.dart`'s `dailySizeForDate` — pure
  Dart, a function of `DateTime.weekday` only — replaces the old fixed
  10x10-always daily size. Saturday is now a "weekend challenge" (15x15),
  Sunday a "light day" (5x5), Monday–Friday stay the standard 10x10 (the
  size the Phase 1 difficulty scorer was calibrated against — unchanged
  for most of the week). `PuzzleRepositoryImpl.getDailyPuzzle` calls it
  instead of the old fixed constants. **Deliberately not streak-based**:
  the brief's core loop is "every user in the world gets the same
  puzzle" for a given date — a size keyed to an individual player's
  streak would break that the moment two players with different streaks
  open the app on the same day. A calendar-keyed rhythm keeps the shared
  ritual intact while still varying week to week. The archive is
  unaffected code-wise: since it's zero-storage and regenerates every
  past date from `getDailyPuzzle` on demand, past Saturdays/Sundays
  correctly regenerate at their own size automatically.
- **Free Play: a streak-gated size tier, same pattern as `AppColorTheme`.**
  New `FreePlaySizeUnlocks.extraLargeStreakDays = 14` in
  `core/constants.dart` (deliberately between the 7-day Sunset theme and
  30-day Forest theme milestones, so unlocks keep unfolding gradually
  rather than clustering). `free_play_screen.dart`'s size picker gained a
  4th, 20x20 "Extra Large" preset, gated on **longest-ever** streak (same
  reasoning as the theme unlocks: a broken active streak shouldn't
  re-lock an already-earned size) via `ButtonSegment.enabled` plus a lock
  icon and the same `themeLockedHint` string the theme picker uses
  (reused as-is — it was already generic enough, no new ARB key needed).
- **20x20 had never been exercised before** — Free Play's presets
  topped out at 15x15, and nothing capped a player from requesting other
  sizes structurally, but nothing tested that the generator actually
  handles 20x20 well. Added it to `puzzle_generator_test.dart`'s existing
  size sweep (now `[5, 10, 15, 20]`) and a new, looser-budget sibling to
  `benchmark_test.dart`'s 15x15/300ms benchmark (20x20/1000ms — a bigger
  grid has more to search, and this is a one-off unlock moment, not every
  day's puzzle) rather than assuming it would "just work" the same way.
  Both pass comfortably on this dev machine.
- **New pinned-style regression test**, matching `determinism_test.dart`'s
  existing spirit: `daily_puzzle_plan_test.dart` pins a few known dates to
  their expected size, specifically so an accidental future change here
  can't silently resize a real player's daily puzzle the way the
  existing pinned fingerprint tests guard against silently *reshaping*
  one.

### Post-v1: Interactive tutorial (added 2026-09-02)

Not part of the original phased spec — the founder's 2026-09-01 product-direction
note asked for concrete proposals on "teach the player something" rather than
deciding unilaterally, and this is that proposal, built once agreed: a
"How to Play" tutorial shown automatically before a player's first-ever
puzzle, replayable from Settings.

- **`domain/entities/tutorial_step.dart`** (`TutorialStep`, `TutorialMessage`
  enum) and **`domain/usecases/tutorial_script.dart`**
  (`buildTutorialPuzzle`, `buildTutorialScript`) — pure Dart, no Flutter
  import, matching every other `domain/` file. `buildTutorialPuzzle` is a
  fixed, hand-authored 5x5 "plus" shape (not randomly generated — the
  script below references exact cell coordinates, which only makes sense
  against a puzzle that never changes), verified solvable-without-guessing
  via `solveFull` in `tutorial_script_test.dart`, the same correctness
  invariant the real generator relies on.
- **`presentation/onboarding/`**: `tutorial_controller.dart`
  (`TutorialController`, a non-family `@riverpod` class) and
  `tutorial_screen.dart`. Reuses the real gameplay engine — `applyMove`,
  `GameSession`, and `BoardPainter`/`BoardLayout` from
  `presentation/game/` — rather than a parallel teaching-only
  implementation, so what's taught matches how the real board actually
  behaves.
- Wired in via `main.dart`'s new `_HomeRouter` (replaces the old
  `home: ConsentGate(child: DailyScreen())` with
  `home: ConsentGate(child: _HomeRouter())`): shows `TutorialScreen` until
  `AppSettings.hasSeenTutorial` (new field, same non-late-with-default
  Isar migration pattern as `selectedThemeId` in Phase 5) is set, then
  `DailyScreen` — reactively, not via a one-time `Navigator` push, so
  finishing/skipping the tutorial swaps the screen on its own. Also
  reachable any time from `SettingsScreen`'s new "How to Play" entry.

**A real, non-obvious engine interaction found and designed around, not
worked around**: the tutorial's first draft scripted a third step asking
the player to manually mark four known-empty cells. It never worked,
because `applyMove`'s real auto-mark feature (Phase 2 spec: "auto-mark a
row/column's remaining cells when its clue is satisfied") had already
marked them — `isRowComplete`/`isColumnComplete` treat an `unknown` cell
as "matching" a should-be-empty solution cell, so completing this
puzzle's row/column-of-5 fill step cascades into auto-marking most of the
grid as a side effect, before the scripted marking step ever ran. An
end-to-end widget test driving real taps through `TutorialController`
(not just the domain-level script/puzzle tests, which don't exercise
`applyMove` and so couldn't have caught this) caught it: the puzzle was
already fully solved two steps early, so the third step's first tap
immediately "finished" the tutorial without the player doing anything.
**Fixed by redesigning the script around the real behavior** rather than
fighting it: two guided fills (row, then column) plus a no-target
"notice what just got marked automatically" explainer step in between —
auto-mark itself becomes the second thing taught, not an obstacle. Net
result is simpler code too: no free-solve step, no fill/mark tool toggle
(every guided target is a fill), and no wrong-flash handling (every
target cell is fill-only and pre-verified solution-correct, so
`applyMove`'s wrong-fill path is structurally unreachable here) — all
removed once they turned out to be unnecessary rather than left in as
unused generality.

**A second, separate testing gotcha found while building the coverage
above**: `AppSettingsController` is `@riverpod` (autoDispose). The real
app always has `_HomeRouter` watching it, keeping it alive; a widget test
that pumps `TutorialScreen` directly (bypassing that router, as isolated
widget tests naturally do) has nothing watching the provider, so it
disposes and resets to `initialAppSettingsProvider`'s default the moment
nothing references it — silently losing `markTutorialSeen()`'s effect
before the test's own assertion could observe it. Not an app bug (the
real app's `_HomeRouter` always keeps it alive); fixed in the test with a
`container.listen(appSettingsControllerProvider, (_, _) {})` to keep it
alive for the test's duration, the standard Riverpod testing pattern for
this. Worth remembering for any future test that pumps a screen in
isolation from its normal router/parent context and then asserts on an
autoDispose provider's mutated state.

**Tests**: 104/104 passing — 5 new (2 `tutorial_script_test.dart` domain
tests, 1 end-to-end `tutorial_screen_test.dart` widget test driving real
taps through the whole script, 2 `widget_test.dart` — one fixed to
explicitly set `hasSeenTutorial: true` since it was silently passing for
the wrong reason after this feature shipped [see below], one new,
confirming a first-ever launch actually shows the tutorial).

**A third real bug, in the pre-existing test suite itself**: adding the
`_HomeRouter` above meant `test/widget_test.dart`'s existing "app boots
into the daily screen" test — which used `AppSettings.defaults`
(`hasSeenTutorial: false`) — started booting into `TutorialScreen`
instead. It still passed, for the wrong reason: the tutorial's intro step
also renders exactly one `FilledButton` ("Continue"), coincidentally
matching that test's only assertion (`find.byType(FilledButton),
findsOneWidget`). Caught by inspection while wiring up the router, not by
the test itself. Fixed by having that test explicitly override
`hasSeenTutorial: true`. Lesson, worth keeping in mind for any future
UI-shape assertion: a same-shape coincidence between two unrelated
screens can keep a test green through a real behavior change — prefer
asserting on something that's actually unique to what you mean to test
(here, the tutorial's "Skip tutorial" text, added in the sibling test)
over a widget-type count that another screen could also satisfy.

### Phase 5 summary (polish and store readiness)

- **Unlockable colour themes** (`lib/core/theme.dart`'s `AppColorTheme` enum
  — classic/always-unlocked, sunset/7-day streak, forest/30-day streak, via
  new `ThemeUnlocks` constants in `core/constants.dart`). Unlocked by
  **longest-ever** streak, never by ad — a broken active streak doesn't
  retroactively re-lock an already-earned theme, and nothing in this path
  touches `AdService`, matching the founder's 2026-09-01 monetization
  note. Persisted as a plain `String` id on `AppSettings.selectedThemeId`
  (domain entities can't depend on Flutter's `Color`); mapped to the real
  enum only in `main.dart` (`AppTheme.light`/`dark` now take a seed
  `Color` instead of being static getters) and in the new theme-picker
  section of `settings_screen.dart`, which reads `streakForTodayProvider`
  for the unlock check and renders each theme as a tappable swatch (locked
  ones dimmed with a lock icon and an ARB-driven "unlocks at N-day streak"
  hint).
- **Share card** (`lib/presentation/game/share_card.dart`): the completion
  sheet now renders a real, laid-out `ShareCard` widget (app name, a
  `CustomPainter` render of the solved grid, date, elapsed time) inside a
  `RepaintBoundary`, and a Share button captures that boundary via
  `toImage()`/`toByteData(PNG)`, writes it to a temp file, and hands it to
  `SharePlus.instance.share(ShareParams(...))` to open the OS share sheet.
  Capturing a boundary that was never actually laid out on screen isn't
  possible, which is why the card is a visible (if compact) part of the
  sheet rather than rendered off-stage.
- **App icon + splash screen**: no design asset existed, so
  `tool/generate_icon_assets.dart` (pure-Dart, using the `image` package —
  dev-dependency only, not shipped) programmatically draws a 3x3
  filled-corners-and-center block pattern evoking a nonogram grid, at
  1024x1024, in three variants (opaque icon, transparent-background
  adaptive-icon foreground, transparent splash mark). `flutter_launcher_icons`
  and `flutter_native_splash` configs in `pubspec.yaml` consume those PNGs.
  **This is a functional placeholder, not real branding** — flagging
  clearly for the founder to replace with real artwork before store
  submission.
- **Store listing copy**: `store/listing_en.md` and `store/listing_tr.md` —
  Play Store (title/short/full description, category) and App Store
  (name/subtitle/promotional text/keywords, category) sections for both
  locales, keyword-focused around nonogram/picross/griddler/hanjie terms.
  `store/screenshots.md` documents required sizes and recommended screens
  to capture — **not actually captured**, see below.
- **Release build config**: `android/app/build.gradle.kts`'s release
  `buildType` now turns on `isMinifyEnabled`/`isShrinkResources` with
  `proguard-rules.pro` (new — keep rules for AppLovin MAX, the OMID
  library it bundles, Google Mobile Ads, and Firebase; see "real bugs"
  below for why two of these rules exist), and `minSdk` is now explicitly
  `24` (matching the locked "Android API 24+" decision — Flutter's own
  default was lower). `make build-android-release` / `./make.ps1
  build-android-release` runs `flutter build apk --release --obfuscate
  --split-debug-info=build/symbols`; `make size-report` runs
  `--analyze-size` pinned to `--target-platform android-arm64` (see
  below for why the pin is required).
- **CI**: `.github/workflows/ci.yml` — `flutter pub get` → `flutter
  gen-l10n` → `dart run build_runner build` → the Isar native-library
  test-setup step → `dart format --set-exit-if-changed` → `flutter
  analyze --fatal-infos --fatal-warnings` → `flutter test`, on push/PR to
  `master` (see "real bugs" below — the workflow originally said `main`
  and silently never ran). The generation steps are necessary because
  `.g.dart` files and `lib/core/l10n_gen/` are gitignored (see
  `.gitignore`'s "Generated code" section) — CI has nothing to analyze or
  test without producing them itself first.

### Phase 5 deviations / additions

- **Multi-language beyond `en`/`tr` was deliberately not done.** The
  founder's 2026-09-01 note flagged this as an explicit Phase 5 call for
  the founder to make, not a default to assume — the locked decision only
  requires `en` + `tr` for v1. Store listing copy was still written in
  both languages per the spec's explicit ask.
- **New `store/` directory** at the repo root (`listing_en.md`,
  `listing_tr.md`, `screenshots.md`) — not in the Phase 0 skeleton, same
  pattern as every other phase's organically-added folder; noted per the
  working rules rather than asked about separately.
- **`android/app/proguard-rules.pro`** and the `dependencies { coreLibraryDesugaring(...) }`
  block in `build.gradle.kts` are new — Phase 0 never anticipated needing
  either since no release build had been attempted until this phase.
- **Two real, previously-latent release-build bugs caught here** — both
  invisible in `flutter run`/debug builds and in every `flutter
  analyze`/`flutter test` run so far, because neither R8 minification nor
  a real Gradle release build had ever actually been exercised before
  Phase 5:
  1. `flutter_local_notifications` (added back in Phase 3) requires core
     library desugaring, which was never enabled. Release build failed
     outright at `:app:checkReleaseAarMetadata` with an explicit error
     naming the missing setting. Fixed by adding
     `isCoreLibraryDesugaringEnabled = true` to `compileOptions` and a
     `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
     dependency.
  2. Once minification actually ran, R8 failed on missing classes
     (`com.amazon.privacypass.*`) referenced by the IAB Open Measurement
     SDK that AppLovin MAX bundles — an optional attestation API that
     isn't on the classpath and is never actually invoked without it.
     Fixed with `-dontwarn com.amazon.privacypass.**` /
     `-dontwarn com.iab.omid.**` in `proguard-rules.pro`. Worth
     remembering if AppLovin MAX is ever upgraded: re-check
     `build/app/outputs/mapping/release/missing_rules.txt` after any bump,
     since a version change could introduce a different missing-class set.
  Both were verified fixed by actually completing a real release build
  end to end (see below) — this machine has a working Android SDK, unlike
  the "no device/emulator" gap noted in every earlier phase, so this was
  possible to check for real rather than just asserted.
- **A third real bug, caught only after the first push**: `ci.yml`
  originally triggered on `branches: [main]`, but `git init`'s default
  branch on this machine is `master` (and that's what the GitHub repo
  actually uses) — so the very first push produced zero workflow runs,
  silently. Caught by checking `GET
  /repos/sogragli4/Numagram/actions/runs` after the push and finding
  `total_count: 0` against a confirmed-public repo, rather than trusting
  that "the workflow file exists" meant "the workflow runs." Fixed by
  changing both triggers to `branches: [master]`. Lesson: always verify a
  new CI workflow actually fires on the branch it's really pushed to,
  not just the conventional `main` — `git init`'s default and a
  repo's actual default branch aren't guaranteed to match the workflow's
  assumption.
- **`flutter build apk --release --analyze-size` errors out on a
  multi-ABI APK** ("Cannot perform code size analysis when building for
  multiple ABIs") — fixed by pinning `--target-platform android-arm64` in
  both `Makefile` and `make.ps1`'s `size-report` target. arm64 covers
  virtually all real Android devices sold since ~2019.
- **Verified real release build + real size report** (both actually run
  on this machine, not simulated): `flutter build apk --release
  --obfuscate --split-debug-info=build/symbols` succeeds, producing a
  56.4MB multi-ABI APK. The arm64-only `--analyze-size` build produces a
  27.1MB APK, breaking down as ~19MB native libraries (`arm64-v8a`,
  dominated by Isar's bundled `libisar.so` plus AppLovin/Firebase native
  code), ~4MB `classes.dex` (obfuscated/minified Kotlin+Dart-AOT-bridge
  code), ~6MB of Dart AOT symbol data (`package:flutter` alone accounts
  for ~3MB of that), and ~509KB `resources.arsc`. No app-specific
  optimization opportunity stood out in this breakdown — the size is
  dominated by SDK-bundled native code (Isar, AppLovin, Firebase), not by
  anything in `package:nonogram_daily` (170KB).
- **Signing**: still using the debug keystore for the release `buildType`
  (`signingConfig = signingConfigs.getByName("debug")`) — a real release
  keystore and signing config is explicitly a founder task, flagged with
  a `TODO` comment at the exact line in `build.gradle.kts`, same as the
  Flutter template's own original placeholder.
- **Visual verification**: same environment constraint as every prior
  phase for the app as a whole (no Android/iOS device/emulator to run the
  *app* itself, distinct from the Android SDK's ability to *build* it —
  see the real release build above). Verified the theme picker and share
  card the same way as every prior phase: a throwaway `flutter_test`
  golden capture (`test/_visual_check/`, deleted after inspection) — for
  the share card, confirmed the app name, a `CustomPainter` render of a
  5x5 test grid matching the input pattern exactly, and the date/time
  lines all lay out correctly inside the card. **Not verified this way**:
  actually tapping the theme swatches or Share button and watching the OS
  share sheet open, real app icon/splash rendering on a device/simulator
  home screen, and anything screenshot-related (see `store/screenshots.md`
  for what's blocked and why).
- Added **`share_plus: 12.0.2`** (pinned below 13.x — needs Dart ≥3.10,
  same story as every other Phase 0-era pin) as a new direct dependency,
  plus `flutter_launcher_icons: ^0.14.4`, `flutter_native_splash: ^2.4.7`
  (downgraded from `^2.4.8` — that version's `meta` requirement conflicted
  with `flutter_test`'s pinned `meta`), and `image: ^4.9.2` (dev-only) as
  new dev-dependencies.

### Phase 4 summary (monetization)

- **Feature flags**: `core/constants.dart`'s `FeatureFlags` — one `const
  bool` per placement (hint/extra-heart/archive-unlock rewarded,
  interstitial, banner). That's the "local config constant" kill switch
  the spec asked for; flip one and rebuild, no call-site changes.
- **`services/ads/`**: `AdService` interface + `MaxAdService` (real
  AppLovin MAX integration — `applovin_max` package). Ad unit IDs come
  from `--dart-define` (`MaxAdConfig.fromDartDefines`, see
  `.env.example`); with no keys configured (this environment's actual
  state), `initialize()` no-ops, every `showRewarded`/`showInterstitial`
  resolves `false` immediately, and `buildBanner()` renders
  `SizedBox.shrink()` — "fully disabled in debug builds," exactly as the
  Phase 0 architecture rule for `services/` asks for.
- **`services/consent/`**: `ConsentService` + `UmpConsentService` (Google
  UMP, via `google_mobile_ads` — used *only* for its bundled consent
  APIs; AppLovin MAX stays the locked ad network). `ConsentGate`
  (`presentation/consent/`) runs consent → ad SDK init → (iOS only) the
  ATT explainer screen → system ATT prompt, once, after the first frame,
  wrapping `DailyScreen` without blocking it (gameplay doesn't need ads
  ready). The whole sequence is wrapped in `try/catch` — a missing
  plugin, no network, or a misconfigured project degrades to "ads/consent
  stay off this session," never a crash.
- **`services/analytics/`**: `AnalyticsService` + `FirebaseAnalyticsService`
  — the exact nine events from the spec
  (`puzzle_started`/`_completed`, `streak_extended`/`_broken`,
  `rewarded_shown`/`_completed`, `interstitial_shown`, `hint_used`,
  `session_length`), wired at their natural call sites
  (`BoardController`, `DailyScreen`'s streak comparison, `main.dart`'s
  `AppLifecycleState.paused`). `null` `FirebaseAnalytics` (no
  `google-services.json`/`GoogleService-Info.plist` — this environment's
  actual state) makes every call a no-op.
- **Hint** (`domain/usecases/use_hint.dart`): reveals one correct cell in
  `BoardState.focusedRow` (the row last tapped/painted — "currently
  focused line"), capped at `GameLimits.maxHintsPerPuzzle` (3). Gated by
  a real rewarded-ad watch in `BoardController.requestHint`.
- **Extra heart**: `BoardController.requestExtraHeart`, offered in the
  out-of-hearts dialog once per puzzle (`GameSession.extraHeartUsed`),
  only when `outOfHearts`.
- **Archive unlock**: `AppSettings.archiveUnlocksCountFor(dateKey)` tracks
  opens-per-day (resets automatically on a date-key mismatch, no cron/
  midnight job needed). `ArchiveScreen` gates only *past* dates — today's
  own daily puzzle, reached via the same calendar, is always free.
- **Interstitial gating**: `domain/usecases/interstitial_gate.dart`
  (`InterstitialGate`) — pure, clock-injectable, fully unit tested (6
  cases: free-play-only, first-session exclusion, first-completion
  exclusion, 3-completion minimum, 90s cooldown, counter reset on show).
  Wired only into free-play completions in `BoardController._onWin` —
  never called at all for daily/archive, which is what actually
  guarantees "never after the daily puzzle," not a flag inside the gate.
- **Banners**: `DailyScreen`, `ArchiveScreen`, `StatisticsScreen` only —
  never `SettingsScreen`, never `BoardScreen`.

**Tests**: 94/94 passing — 19 new (6 `useHint`, 6 `InterstitialGate`, plus
carryover). Rewarded/interstitial/banner *rendering* itself isn't
unit-testable without a real ad SDK response; what's tested is the logic
around it (caps, gating, eligibility) and, via the golden-screenshot
technique, that a granted reward actually flows through to the board
(see below).

### Phase 4 deviations / additions

- **`applovin_max` declares `sdk: ">=2.17.1 <3.0.0"`** in its pubspec —
  every published version through 4.6.4 (as of this writing) still does,
  which reads as "doesn't support Dart 3" but is almost certainly just a
  stale constraint the maintainers never widened (the package is thin
  method-channel boilerplate, nothing Dart-3-incompatible). Verified
  empirically: `flutter pub get` and `dart analyze` both resolve it fine
  against this project's Dart 3.9.2 without an override. Flagging this
  because it'll look alarming in a `flutter pub outdated` run — it's not
  a live issue, just a package that needs the founder's own judgement
  call if it ever *does* start failing after a `pub upgrade`.
- **`google_mobile_ads` pinned to `7.0.0`** (not latest 9.x): same
  Dart-3.9.2-vs-newer-SDK-requirement story as every other Phase 0/1/3
  pin. Only its UMP APIs are used.
- **AdMob App ID placeholders**: the Google Mobile Ads SDK requires a
  real AdMob App ID natively to initialize at all — even though AdMob
  itself isn't the ad network here. Added Google's public **TEST** app ID
  to `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
  and `Info.plist` (`GADApplicationIdentifier`). **Must be swapped for a
  real one** (`ADMOB_APP_ID_ANDROID`/`ADMOB_APP_ID_IOS` in
  `.env.example`) before release, or ad consent handling silently runs in
  test mode.
- **A real bug caught here**: `ConsentGate._run()` originally had no
  `try/catch` around the UMP call. In an environment without the native
  plugin registered (any widget test, and potentially a misconfigured
  build), that's an unhandled `MissingPluginException` — caught it via
  the widget test, which is exactly what surfaced it. Fixed by wrapping
  the whole consent/ad-init/ATT sequence in one `try/catch`: worst case
  now is "ads/consent stay off this session," matching the "disabled
  without config" pattern used everywhere else in this phase, not a
  crash.
- **Visual verification**: same constraint as Phases 2–3 (no device/
  emulator, Chrome can't compile this codebase). This phase's golden-
  screenshot check went further than "does it render" — it drove a real
  interaction (tap the hint button → fake `AdService` grants the reward →
  `useHint` fires → a cell is actually revealed on screen), confirming
  the whole rewarded-ad-to-gameplay pipeline end to end, just with a fake
  ad response standing in for AppLovin MAX. **Not verified this way**:
  an actual AppLovin MAX/UMP/ATT dialog rendering, real ad fill/latency
  behavior, and the interstitial/banner *visually* appearing (their
  gating logic is unit tested; their rendering needs a real ad response).

### Store compliance — cannot be done by an agent, needs the founder

The Phase 4 spec's compliance section is mostly console/portal work with
no code representation, so it isn't "done," just laid out here as a
checklist against what the code already assumes:

- **Google Play Data Safety form** and **App Store privacy nutrition
  labels**: declare collection of *advertising ID*, *approximate
  location* (AppLovin MAX mediation adapters may collect this — check
  whichever mediated networks end up enabled in the MAX dashboard), and
  *usage/analytics data* (Firebase Analytics). Neither portal is
  reachable from here.
- **Age rating**: set the app as **not primarily child-directed** in both
  the Play Console and AppLovin MAX / AdMob dashboards — three separate
  places, all need to agree.
- **Real credentials**: every value in `.env.example` is still blank in
  this environment (AppLovin SDK key + 5 ad unit IDs, AdMob App IDs,
  Firebase project). The code is written to degrade safely without them,
  but nothing ad-related actually serves an ad until they're supplied via
  `--dart-define`.
- **Firebase project**: needs `google-services.json`
  (`android/app/`) and `GoogleService-Info.plist` (`ios/Runner/`) added —
  neither exists in this repo yet; `main.dart`'s `Firebase.initializeApp()`
  call is already guarded to no-op without them.

### Phase 3 summary (daily system, persistence, streaks)

- **Persistence**: two Isar collections, `PuzzleCompletionModel` (one row
  per solved puzzle — date key or `null` for free play, size, difficulty,
  time, mistakes) and `AppSettingsModel` (single fixed-id row: palette,
  notification time/enabled, `hasCompletedFirstPuzzle`). **No puzzle grid
  is ever stored** — the archive stays zero-storage exactly as specced;
  every past date's puzzle is regenerated from `seedForDate(date)` on
  demand, now via `PuzzleGeneratorDataSource` which wraps `generatePuzzle`
  in `compute()` (an Isolate), satisfying the Phase 0 lock that was
  deferred until there was a real call site for it.
- **Streaks are computed, never stored**: `StreakRecord.compute(dates,
  today)` is a pure function over the completed-dates set (8 unit tests).
  One source of truth; nothing to desync.
- **`domain/repositories/`**: `PuzzleRepository`, `StreakRepository`, and
  a new `SettingsRepository` (not in the Phase 0 skeleton — added because
  the settings screen needs somewhere durable to live).
- **`presentation/`**: `daily/` (home screen + streak provider + the
  completed/missed/today calendar, which doubles as the "archive" —
  they're the same feature), `archive/archive_screen.dart` (hosts the
  calendar, opens any past date via `GenerateDailyPuzzle`), new
  `freeplay/free_play_screen.dart` (size picker; difficulty is shown
  after generation, not dialed in — it's an emergent property of the
  puzzle, not a generator input), `settings/` (palette + notification
  controls, gated correctly per spec), `statistics/` (total solved,
  perfect count, average time by size).
- **`BoardController` is now a family provider** keyed on `BoardArgs`
  (`.daily(puzzle, date)` / `.freePlay(puzzle)`), and records a
  `PuzzleCompletion` through `UpdateStreak` on every win — daily/archive
  *and* free play both count toward the statistics totals; only a
  non-null date counts toward the streak. The colourblind palette moved
  out of `BoardState` into a new app-wide `AppSettingsController`
  (persisted) — it was only ever in per-session board state in Phase 2
  because there was no persistence layer yet.
- **Notifications**: `services/notifications/notification_service.dart`
  (interface) + `local_notification_service.dart`
  (`flutter_local_notifications`-backed impl). Permission is requested,
  and the reminder only gets scheduled, after `DailyScreen` detects the
  player's *first-ever* puzzle completion — never on launch, per spec.
  Uses `AndroidScheduleMode.inexactAllowWhileIdle` deliberately, so it
  never needs Android 12+'s special exact-alarm permission for something
  this low-stakes.

**Tests**: 82/82 passing — new coverage for `StreakRecord.compute`,
`GameSession`'s completion checks (Phase 2 carryover), and a real
(temp-directory) Isar integration test for `IsarLocalDataSource`.

### Phase 3 deviations / additions

- **New `SettingsRepository`**, new `presentation/{archive,freeplay,
  statistics}/` folders, and `presentation/daily/daily_controller.dart` —
  none were in the Phase 0 skeleton; same pattern as Phase 1's
  `domain/engine/` and Phase 2's `board_layout.dart` — flagging per the
  working rules, not asking again each time since the pattern is now
  established.
- **Deleted `data/models/puzzle_model.dart`** (Phase 0 placeholder): the
  zero-storage archive design means a Puzzle is never persisted, so
  there's nothing for it to hold. Renamed the other Phase 0 placeholder,
  `streak_model.dart`, to `puzzle_completion_model.dart` — a streak is
  computed, not stored, but completions are.
- **`flutter_local_notifications` pinned to `20.1.0`** (not latest 22.x):
  same story as Phase 0's dependency pins — 21.0.0+ requires Dart
  ^3.10.0, newer than this machine's Dart 3.9.2. Bump alongside the
  Riverpod/Isar group when the toolchain moves up.
- **Isar needs its native library on the test-running host**, not just
  the shipped app: `flutter test`/`dart test` load `libisar.*` from the
  project root directly rather than through Flutter's normal plugin
  asset pipeline. Added `tool/test_setup.dart` (+ `make test-setup` /
  `./make.ps1 test-setup`) to copy the right one from the pub cache for
  whatever host platform is running tests; `.gitignore`d since it's a
  fetched binary, not source. **Needs to be re-run once after cloning /
  after `flutter pub upgrade` touches Isar**, or Isar-backed tests fail
  with a "Failed to load dynamic library" error, not a helpful one.
- **A real bug caught while wiring board completion recording**: free
  play wins were never being persisted at all (only daily/archive were),
  which would have made "Puzzles Solved" on the statistics screen silently
  undercount for anyone who mostly plays free play. Fixed — see
  `board_controller.dart`'s `_recordCompletion`.
- **Widget-test + Isar + Riverpod async gotcha worth remembering**:
  inside `testWidgets`, real I/O (Isar, file system) doesn't complete on
  `tester.pump()`'s fake clock, and `pumpAndSettle()` hangs forever on
  any indeterminate animation (e.g. a loading spinner) regardless. The
  fix is `tester.runAsync()` — but the *trigger* (e.g. `pumpWidget`, or a
  `tap` that starts a provider's first fetch) and the *wait* for that
  same async chain must be in the **same** `runAsync` call, or it
  deadlocks across the fake/real zone boundary. `matchesGoldenFile` also
  calls `runAsync` internally, so it can never be called from inside your
  own `runAsync` block ("Reentrant call to runAsync() denied") — exit
  first, then call it. See `test/widget_test.dart` for the working
  pattern.
- **Visual verification**: same environment constraint as Phase 2 (no
  Android/iOS device or emulator, Chrome can't compile this codebase).
  Verified the same way — headless `flutter_test` golden captures,
  inspected as PNGs — for `DailyScreen`, `ArchiveScreen`'s calendar,
  `FreePlayScreen`, `SettingsScreen` (including the correctly-disabled
  notification toggle pre-first-completion), and `StatisticsScreen`'s
  empty state. **Not verified this way**: actually completing a puzzle
  end-to-end and watching the streak/statistics update, the
  first-completion notification-permission prompt, and real OS
  notification delivery — these need a real device/emulator.

### Phase 2 summary (playable board)

- **`domain/entities/game_session.dart`**: `GameSession` (puzzle + row-major
  `List<CellState>` + hearts/mistakes/elapsed/won), plus `isRowComplete` /
  `isColumnComplete` (shared by auto-mark and the painter's line-dimming —
  one source of truth, not duplicated logic).
- **`domain/usecases/validate_move.dart`**: `applyMove` — the one place
  fill/mark rules, mistake/heart accounting, auto-mark, and win detection
  live. Pure, synchronous, no Flutter import, fully unit tested (24 cases:
  fill/mark toggling, wrong-fill heart cost, auto-mark on/off, win
  detection, no-moves-after-game-over).
- **`presentation/game/`**: `board_layout.dart` (NEW — shared pixel
  geometry so the painter and the tap-to-cell hit-testing can never drift
  apart), `board_painter.dart` (single `CustomPainter`: cells, clue
  gutters, 5-cell thick separators, completed-line tint, wrong-fill flash
  overlay), `board_controller.dart` (`@riverpod` class: undo stack capped
  at 50, paint-stroke axis locking, haptics, 1s elapsed-time ticker),
  `board_screen.dart` (gestures — see below), `completion_sheet.dart`
  (NEW — win bottom sheet with time + hearts left).
- **Gestures**: `InteractiveViewer` (minScale 1.0 — cells are laid out at
  a fixed 44pt so this *guarantees* the accessibility touch-target
  minimum by construction, never allowing zoom-out below it) wraps a
  `GestureDetector` (tap = single cell, long-press-drag = axis-locked
  paint stroke) inside a `Listener` that separately watches raw pointer
  counts/timing to detect a quick two-finger tap (mode toggle) without
  fighting the GestureDetector/InteractiveViewer gesture arena.
- **Accessibility**: 44pt minimum cell size (see above) and a toggleable
  Okabe–Ito colorblind-safe palette (`BoardPalette.colorblindSafe` in
  `core/theme.dart`), switchable from the app bar.
- **`main.dart`** now boots straight into `BoardScreen` with a
  **fixed-seed demo puzzle generated inline in `BoardController.build()`**
  — explicitly temporary Phase 2 scaffolding. Phase 3 replaces this with
  the real daily/archive/free-play puzzle sourced from a repository.

**Tests**: 69/69 passing, including new coverage for `GameSession`'s
completion checks and all of `applyMove`'s rules.

### Phase 2 deviations / additions
- **`presentation/game/board_layout.dart` and `completion_sheet.dart`**
  weren't in the Phase 0 file list — added as natural extensions of
  `presentation/game/`, same as `domain/engine/` in Phase 1.
- A real bug caught while wiring this up: `board_controller.dart` used
  `@riverpod` without importing `package:riverpod_annotation/riverpod_annotation.dart`
  (only `flutter_riverpod`, which doesn't re-export it). The failure mode
  was confusing — `riverpod_generator` silently no-op'd and
  `isar_community_generator` threw an unrelated-looking "could not
  resolve annotation" error while scanning the same file — worth
  remembering if that error resurfaces on a different file later.
- **Visual verification**: no Android/iOS device or emulator is attached
  in this environment, and `flutter run -d chrome` cannot compile this
  codebase at all — not a bug, but a direct consequence of
  `deterministic_random.dart`/`stable_hash.dart`'s 64-bit integer
  constants (Phase 1), which dart2js cannot represent exactly. Verified
  the UI instead by rendering `BoardScreen` headlessly in a
  `flutter_test` golden-image capture and inspecting the resulting PNGs
  directly: confirmed the grid, clue gutters, 5-cell separators, tap-to-fill,
  tap-to-mark (X), the Fill/Mark toggle, and the colorblind palette swap
  (hearts and fills visibly changed color) all render and respond
  correctly. **Not verified this way**: long-press-drag axis-locked
  painting, pinch-zoom/pan, the two-finger mode-toggle tap, the win/
  completion-sheet flow, and the out-of-hearts dialog — these need a real
  touch device or emulator to exercise properly. Flag this again before
  Phase 2-touching work ships, and get it on a real device/emulator once
  one is available.

### Phase 1 summary (puzzle engine)

All pure Dart, no Flutter import, in `lib/domain/`:

- **`domain/entities/`**: `CellState` (unknown/filled/marked), `PuzzleGrid`
  (bit-packed via `Uint32List`, not `List<List<bool>>`), `LineClue`,
  `GridSize`, `Difficulty`, `Puzzle`.
- **`domain/engine/`** (new — see "Architecture addition" below):
  `stable_hash.dart` (hand-rolled FNV-1a 64-bit, `seedForDate`),
  `deterministic_random.dart` (hand-rolled SplitMix64 PRNG),
  `line_solver.dart` (`solveLine` — O(n·k) memoised feasibility DP over
  `(cellIndex, clueIndex)`, plus a single state-graph traversal that
  intersects every legal run placement to find forced-filled/forced-empty
  cells), `full_solver.dart` (`solveFull` — repeats row+column sweeps to
  `Solved` / `Stuck` / `Contradiction`), `puzzle_generator.dart`
  (`generatePuzzle` — seeded random fill at density 0.50–0.62, derive
  clues, require `solveFull` on the clues alone to reach `Solved`, retry
  up to 500 attempts, fall back to a smaller size), `difficulty_scorer.dart`
  (`scoreDifficulty`, thresholds tuned so 10x10 is the modal difficulty —
  see `tool/calibration/difficulty_calibration.dart` to re-tune).

**Test results**: 51/51 passing (`test/domain/entities/`,
`test/domain/engine/`), including hand-worked line-solver edge cases
(empty clue, full-line run, exact-fit, overlap deduction, contradictions),
a hand-verified 5x5 full-solver integration case, Stuck/Contradiction
cases, a 1000-random-puzzle termination guard, generator success for
5x5/10x10/15x15, the pinned-date determinism test, and the difficulty
calibration test. **Benchmark**: 15x15 generation, median ~0.6ms / worst
observed ~27ms on dev hardware (budget: 300ms).

### Architecture addition: `domain/engine/`

Phase 0 only specified `domain/{entities,repositories,usecases}`. The
solver/generator algorithms didn't fit any of those (not an entity, not a
repository interface, and not yet wired to a use case — that wiring is
Phase 3's `GenerateDailyPuzzle`, once there's a repository to cache
results in). Added `domain/engine/` as a fourth `domain/` subfolder:
pure-Dart, no-Flutter-import, same as the rest of `domain/`. Flagging this
once per the working rules — proceeding without further sign-off.

### A real bug found and fixed during Phase 1

`line_solver.dart`'s placement-intersection traversal originally jumped
straight from a placed run to the *next* run's decision point
(`after + 1, j + 1`) without ever recording that the mandatory single-cell
gap right after the run (`after`) is empty in that placement. This made
`canBeEmpty[after]` silently stay false when that was the *only* placement
proving the cell empty, which surfaced as wrong deductions (a cell forced
filled that shouldn't have been) and, once wrong deductions fed back into
the full solver, outright false contradictions on already-solvable
grids — measured near-100% false-contradiction rates at 10x10+ before the
fix, 0% after (`tool/calibration/`, not checked in as tests but the fix
itself is covered by `line_solver_test.dart`'s overlap and contradiction
cases plus a 20k-case stress check run manually during development).
Lesson: the generator's own "derive clues from a random grid, then solve"
loop is a strong correctness check by construction — a contradiction
there is *always* a solver bug, never a legitimately unsolvable input, so
it's worth treating as a hard invariant during future changes to the
solver.

### Difficulty thresholds are re-tunable

`difficulty_scorer.dart`'s two boundary constants were fit empirically
against the real generator (`tool/calibration/difficulty_calibration.dart`
prints the resulting difficulty distribution per size). If the generator's
density range, attempt budget, or solving strategy changes later, re-run
that script and adjust the constants so 10x10 stays the modal difficulty —
don't just trust the existing numbers to still be right.

### `tool/calibration/`

Two small standalone Dart scripts (`dart run tool/calibration/<name>.dart`),
excluded from `flutter analyze` (see `analysis_options.yaml`) since they're
developer diagnostics, not shipped code:
- `compute_pinned_fingerprints.dart` — regenerates the expected values in
  `determinism_test.dart` if the generator intentionally changes.
- `difficulty_calibration.dart` — prints the easy/medium/hard distribution
  per grid size for the current thresholds.

### Architecture rules (recap — enforce on every change)
- Three layers in `lib/`: `core/`, `domain/`, `data/`, `presentation/`, `services/`. Dependencies
  point inward only. `domain/` never imports `data/`, `presentation/`, or `package:flutter`.
- Every `services/*` capability sits behind an abstract interface so it can be faked in tests and
  disabled in debug builds.
- No business logic in widgets — widgets read Riverpod providers and dispatch intents.
- Grid rendering is a single `CustomPainter` on a `RepaintBoundary`. Never one widget per cell.
- Puzzle generation runs in an `Isolate` via `compute`, pure Dart, no Flutter import.

### Naming conventions
- Files: `snake_case.dart`. Classes/enums: `PascalCase`. Members/vars: `camelCase`.
- Riverpod providers: code-gen flavour only (`@riverpod`), file name matches the provider's
  subject, e.g. `daily_puzzle_provider.dart` → `dailyPuzzleProvider`.
- Isar collections live in `data/models/`, suffixed `Model` (e.g. `PuzzleModel`), with an explicit
  `toEntity()` / `fromEntity()` mapper to the `domain/entities/` type. Domain entities never carry
  Isar annotations.
- Use cases are verbs: `GenerateDailyPuzzle`, `ValidateMove`, `UpdateStreak`.

### No hardcoded strings
Every user-facing string must come from ARB (`lib/l10n/app_en.arb`, `app_tr.arb`) via the generated
`AppLocalizations`. Zero string literals in widget `Text`/labels/semantics. Base locale `en`, second
locale `tr`. Add new keys to **both** ARB files in the same change — a missing key is a build error,
not a runtime fallback.

### Phase 0 deviations from the brief
- **Isar → `isar_community`.** Upstream `isar`/`isar_generator` (last published 2023-04) pins
  `analyzer <6.0.0`, which cannot resolve alongside a working `riverpod_generator`. Switched to
  `isar_community` / `isar_community_flutter_libs` / `isar_community_generator` — an actively
  maintained, API-compatible fork. No API or behavior difference for our usage; only the package
  name changes at the import site.
- **Dependency versions are exact-pinned, not caret ranges**, for the Riverpod/Isar code-gen chain
  (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `isar_community*`,
  `build_runner`). This machine's Flutter stable ships Dart 3.9.2; the newest `riverpod_generator`
  requires Dart ^3.12. The pinned set (`flutter_riverpod`/`riverpod_annotation`/`riverpod_generator`
  @ 3.0.0, `isar_community*` @ 3.3.0, `build_runner` @ 2.7.1) is the newest mutually-compatible
  combination found. **Revisit and bump this whole group together** after `flutter upgrade` moves
  the toolchain to Dart >=3.12 — do not bump one package in isolation, it will break the resolver
  again for the same reason.
- `riverpod_lint` / `custom_lint` were left out of `dev_dependencies` (not in the locked decisions
  table) because they pull in an `analyzer` range incompatible with `isar_community_generator` at
  the pinned versions above.
- `make` is not installed on the primary dev machine (Windows, no WSL/choco make detected). Added
  `make.ps1` as a drop-in equivalent (`./make.ps1 gen`, `./make.ps1 test`, `./make.ps1 analyze`,
  etc.) alongside the spec's `Makefile`, which still works wherever `make` is available.
- `flutter analyze` is treated as fatal on warnings *and* infos via `--fatal-infos --fatal-warnings`
  in `Makefile`/`make.ps1`, rather than hand-listing every lint as `error` in
  `analysis_options.yaml` — simpler to maintain and equivalent in effect for CI purposes.

### Product direction notes (from the founder, 2026-09-01 — apply from Phase 2 onward)
- **Monetization stays opt-in, not manipulative.** The founder asked for "emotion/mood analysis so
  the player is in a state where they'll watch ads." That will **not** be built as literally
  stated — timing ad prompts off inferred emotional vulnerability is a dark pattern and conflicts
  with the brief's own rule that the daily ritual "stays clean." Instead, rewarded placements
  (hint / extra heart / archive unlock) stay strictly player-initiated at natural decision points,
  exactly as scoped in Phase 4. This is the revenue-maximizing approach anyway: opt-in rewarded ads
  have far better fill/LTV economics than forced or manipulated interstitials, and protecting the
  daily-ritual screen is what drives D30 retention, which is what actually compounds ad revenue.
- **Puzzles should support long sessions without repetition-fatigue and teach the player something**
  as they progress. Concretely, weave this into: Phase 1's difficulty scoring (a real curve across
  sizes/densities, not just bigger grids), and Phase 3/5's progression layer (archive + free play +
  streak milestones should introduce new grid sizes, techniques, and colour-theme unlocks over
  time rather than repeating the same shape). Flag this again in the Phase 1 and Phase 3/5
  check-ins with concrete proposals rather than deciding unilaterally now.
- **Multi-language beyond `en`/`tr`** is a Phase 5 store-readiness question (more ARB locales +
  store listings). The locked decision only requires `en` + `tr` for v1; expanding further is a
  scope call for the founder to make explicitly when Phase 5 starts, since it affects the
  `flutter_localizations` locale list, ARB translation cost, and store listing work.
- **Visual polish** ("üst düzey modern arayüz") is explicitly Phase 2 (board) and Phase 5 (theming,
  icons, splash) work, not a Phase 0 concern. Phase 0 only ships a Material 3 seed theme
  (`lib/core/theme.dart`) as a placeholder so `main.dart` compiles.

### Toolchain on the primary dev machine
- Flutter 3.35.5 (stable), Dart 3.9.2, Windows 10, no `make` installed.
- `flutter analyze --fatal-infos --fatal-warnings`: clean.
- `flutter test`: 147/147 passing (as of the real-device pass / board-
  sizing fix). Requires `make test-setup` / `./make.ps1 test-setup` once
  first (copies Isar's native library into the project root — see
  Phase 3 deviations).
- **A real Android device now works** (see "First real-device pass"
  above) — a physical phone connected over USB (with the right USB
  connection mode picked on the phone itself, and force-stopped between
  installs to guarantee a cold start of the latest build) is more
  reliable than the AVD ever was in this environment. The AVD
  (`magma_claw_dev`, still listed by `flutter emulators`) is *not*
  ruled out as a future option, but every earlier boot attempt (default,
  `-no-snapshot`, fully headless `-gpu swiftshader_indirect -no-window`)
  got stuck in adb's `offline` state past a normal cold-boot window —
  likely a GPU/display constraint of this specific environment, not a
  project configuration problem — so a physical device is the proven
  path going forward. `flutter devices` also still shows Windows desktop
  (no `windows/` platform folder — out of scope, locked targets are
  Android/iOS) and Chrome/Edge web (doesn't compile — see Phase 2
  deviations above), neither of which run this app.
- **A real Android SDK is installed** (`flutter doctor` shows a working
  Android toolchain) — discovered in Phase 5, confirmed working for real
  `flutter build apk --release`/`--debug` builds and (this session) real
  device installs via `adb`. **Watch for stale incremental builds** —
  see the "First real-device pass" section above; when verifying an
  actual behavior change on-device, prefer a full `flutter clean` cycle
  over trusting a suspiciously fast `flutter build apk`.
- Added `meta: ^1.15.0` as a direct dependency in Phase 1, for `@immutable`
  on the domain entities (`PuzzleGrid`, `LineClue`, `GridSize`).