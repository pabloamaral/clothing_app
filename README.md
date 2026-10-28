# Outfit Planner

An iOS app for cataloguing your clothes with photos, getting ideas for what to
wear together — from your own closet or from a Pinterest board — and planning
outfits for the week. Built with SwiftUI and SwiftData; your closet is stored
on the device.

## Tabs

| Tab     | What it does                                                                 |
|---------|------------------------------------------------------------------------------|
| Closet  | Take or pick a photo of each garment; tag its category and colour            |
| Ideas   | **Closet:** pairings from colour rules. **Pinterest:** recreate pinned looks |
| Outfits | Build and edit outfits by hand                                               |
| Planner | Assign an outfit to each of the next 7 days                                  |

## How ideas work

**Closet ideas** run on the phone, free and offline.
[`OutfitRecommender`](Sources/Support/OutfitRecommender.swift) tries every
top + bottom (and every dress), adds the best-matching shoes and outerwear,
and scores each pair of items by colour: a neutral with a colour is the
strongest match, then two neutrals, then complementary colours (blue/orange,
red/green, …). Any outfit with a clashing pair is dropped. Items with no
colour set count as neutral, so **tag colours to get useful suggestions.**

**Pinterest ideas** need a public board and an Anthropic API key.
[`PinterestBoard`](Sources/Support/PinterestBoard.swift) reads the board's
RSS feed (no Pinterest developer account needed; the feed only lists the 25
most recent pins). When you tap a pin and choose *Find in My Closet*,
[`ClaudeStylist`](Sources/Support/ClaudeStylist.swift) sends the pin image
and small (384px) copies of up to 60 closet photos to Claude, which picks the
items that recreate the look, suggests how to wear them, and lists any pieces
you'd need to buy.

Each comparison is billed to your API key — expect a few US cents per pin
with a typical closet, scaling with how many closet photos you have.

## First-time setup

### 1. Install Xcode
Install **Xcode** from the Mac App Store. Open it once, accept the licence,
and let it install its extra components.

### 2. Install an iPhone simulator
Xcode → Settings → **Components** → download the latest **iOS** simulator
(~8 GB). Skip this if you'll only run on your real iPhone.

### 3. Sign in with your Apple ID
Xcode → Settings → Accounts → **+** → Apple ID. A free account can run the
app on your own iPhone, but the install expires after 7 days (run it again
from Xcode to renew). A paid Apple Developer membership ($99/yr) removes that
limit and is required to publish to the App Store.

### 4. Create the Xcode project
File → New → Project → **iOS → App**, then:

| Field                   | Value                                   |
|-------------------------|-----------------------------------------|
| Product Name            | `OutfitPlanner`                         |
| Team                    | your Apple ID (Personal Team)           |
| Organization Identifier | reverse-domain, e.g. `com.yourname`     |
| Interface               | SwiftUI                                 |
| Language                | Swift                                   |
| Storage                 | **None** (the code sets up SwiftData)   |

Save it **inside this repo folder** and **untick "Create Git repository"**,
because this folder already is one.

### 5. Move the source in
The wizard creates `OutfitPlanner/OutfitPlanner/` with two placeholder files.
Replace them with the real source:

```sh
rm OutfitPlanner/OutfitPlanner/ContentView.swift OutfitPlanner/OutfitPlanner/OutfitPlannerApp.swift
mv Sources/* OutfitPlanner/OutfitPlanner/ && rmdir Sources
```

Xcode picks up files in that folder automatically.

### 6. Allow camera access
Click the blue **OutfitPlanner** project icon → target **OutfitPlanner** →
**Info** tab → hover any row, click **+**, choose
**Privacy - Camera Usage Description**, and set the value to something like
*"Take photos of your clothes."* Without this, iOS closes the app the moment
the camera opens.

### 7. Run it
- **Simulator:** choose an iPhone from the device menu at the top of Xcode
  and press ⌘R. The simulator has no camera, so "Take Photo" is hidden there;
  drag images onto the simulator to add them to its photo library.
- **Your iPhone:** plug it in and enable Settings → Privacy & Security →
  **Developer Mode** (the phone restarts). Choose it as the run destination
  and press ⌘R. The first time, trust your developer profile under
  Settings → General → VPN & Device Management.

### 8. Connect Pinterest (optional)
1. Get an API key at [console.anthropic.com](https://console.anthropic.com)
   (add a small amount of credit; billing is pay-as-you-go).
2. In Pinterest, open a **public** board of outfits → **Share** → **Copy link**.
3. In the app: Ideas → ⚙︎ → paste both → Done → switch to **Pinterest**.

The key is stored in the iPhone's Keychain, never in this code. Don't add it
to the source: anything committed here, or built into a shared copy of the
app, can be extracted.
