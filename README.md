# Outfit Finder

An iOS app for cataloguing your clothes with photos, saving photos of outfits
you love, and getting recommendations for how to recreate those outfits from
your own closet. Built with SwiftUI and SwiftData; everything is stored on
the device.

## Tabs

| Tab         | What it does                                                              |
|-------------|---------------------------------------------------------------------------|
| Closet      | Take or pick a photo of each garment; tag its category and colour         |
| Inspiration | Folders of outfit photos; the closest matches from your closet for each  |
| Ideas       | Pairings from your closet based on colour rules                           |
| Outfits     | Build and edit outfits by hand                                            |
| Planner     | Assign an outfit to each of the next 7 days                               |

## How inspiration works

1. **Make folders for kinds of outfits** (Work, Date night, Summer…) and add
   photos of complete outfits to them. Photos can be moved between folders
   from their detail screen; photos not in any folder appear under
   *Unfiled*. Deleting a folder asks whether to keep its photos (they move
   to Unfiled) or delete them too.
2. **Add a photo of a complete outfit.** Claude lists each piece in it —
   category, colour family, colour name and a short description, such as
   *Bottoms · Green · "olive wide-leg chinos"* — via
   [`ClaudeStylist`](Outfit%20Finder/Outfit%20Finder/Support/ClaudeStylist.swift).
   You can correct any piece before saving, or add pieces by hand without an
   API key.
3. **The pieces are saved with the photo**, so the analysis runs once per photo.
4. **Recommendations are worked out on the phone** by
   [`InspirationMatcher`](Outfit%20Finder/Outfit%20Finder/Support/InspirationMatcher.swift),
   from those saved pieces and your closet tags. For each piece it picks the
   closest item of the same type:
   - **Same colour** — same colour family
   - **Similar colour** — a neighbouring shade, e.g. navy for black
   - **Colour differs** — a different neutral, or an item with no colour set

   A bright colour is never swapped for a neutral or vice versa, since that
   changes the look. Pieces with no match are listed as *Not in your closet
   yet*. Tap an alternative to swap it in, then save the result as an outfit.

Matching relies on your closet tags, so **set a colour on each closet item.**

**Cost and privacy:** only inspiration photos are sent to Anthropic, once
each, billed to your API key (roughly a cent or two per photo). Closet photos
never leave the phone, and recommendations are free.

## How Ideas work

[`OutfitRecommender`](Outfit%20Finder/Outfit%20Finder/Support/OutfitRecommender.swift)
tries every top + bottom (and every dress), adds the best-matching shoes and
outerwear, and scores each pair by colour: a neutral with a colour is the
strongest match, then two neutrals, then complementary colours (blue/orange,
red/green, …). Any outfit with a clashing pair is dropped.

## Setup

The Xcode project is `Outfit Finder/Outfit Finder.xcodeproj`. Xcode includes
every file in `Outfit Finder/Outfit Finder/` automatically.

1. **Install Xcode** from the Mac App Store, open it once and accept the licence.
2. **Install an iPhone simulator:** Xcode → Settings → **Components** →
   latest **iOS** simulator (~8 GB). Skip this to run only on your iPhone.
3. **Sign in:** Xcode → Settings → Accounts → **+** → Apple ID. A free
   account can run the app on your own iPhone, but the install expires after
   7 days (run it again from Xcode to renew).
4. **Allow camera access:** click the blue **Outfit Finder** project icon →
   target **Outfit Finder** → **Info** tab → hover a row, click **+**, choose
   **Privacy - Camera Usage Description**, and enter something like
   *"Take photos of your clothes."* Without it, iOS closes the app when the
   camera opens.
5. **Run:** choose a simulator or your plugged-in iPhone from the device menu
   at the top of Xcode and press ⌘R.
   - The simulator has no camera, so *Take Photo* is hidden there; drag
     images onto the simulator to add them to its photo library.
   - On an iPhone, first enable Settings → Privacy & Security →
     **Developer Mode**, and after the first install trust your developer
     profile under Settings → General → VPN & Device Management.
   - The project targets **iOS 26.5**, so your iPhone needs iOS 26.5 or later.
6. **Turn on piece detection (optional):** get an API key at
   [console.anthropic.com](https://console.anthropic.com), then in the app
   go to Inspiration → ⚙︎ and paste it. The key is kept in the iPhone's
   Keychain. Never put it in the source code: anything committed here, or
   built into a copy of the app you share, can be extracted.
