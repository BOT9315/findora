# FINDORA 🔍🪐

**Never Lose What Matters.**

FINDORA is a personal visual-memory app for Android. It helps you find misplaced everyday items by searching photos you've taken of where you keep things. Ask in English or Hindi, and it shows where your item was last seen, with the photo as evidence.

**Created & developed by Ankush Kumar.**

> **Download:** [⬇️ Findora APK (latest release)](https://github.com/BOT9315/findora/releases/latest/download/Findora.apk) · about 196 MB, because it includes offline TFLite models.

---

## ✨ Features

- **Visual memory:** Capture photos of rooms, desks, and containers, and tag them by location.
- **Natural-language search:** Ask in English or Hindi, e.g. *"Keys on desk"* or *"Mera black charger kahan hai?"*
- **Explainable results:** Each match shows a score breakdown so you can see why it ranked where it did.
- **Memory graph:** A timeline from *First Observed* to *Most Recent Observation*, linked to photo evidence. You can correct locations manually.
- **Departure checklists:** Reminders for College Prep, Daily Commute, Gym Session, and Weekend Travel, with departure alarms.
- **AR Visual Finder:** A live camera viewfinder with scanning reticles and compass heading. Limited by ARCore device support.
- **Privacy and security:** Works offline on-device. Biometric app lock (fingerprint/Face ID) and PIN unlock. Full data wipe in Settings.

> **Honest status:** Checklist items show *"Historical observation • NOT verified packed"* until you confirm them yourself. FINDORA records what it saw, not what is currently in your bag.

---

## 📱 Screens

| Screen | Purpose |
|---|---|
| Splash | 8-phase animated intro with the FINDORA ORBIT logo and credit (tap to skip) |
| Onboarding | Introduces on-device memory, bilingual search, privacy, and observational results |
| Vault (Login / Signup) | Biometric, PIN, or guest access |
| Home | Status header ("Neural Engine Active"), quick actions, rooms, recent sightings |
| Add Photo | Camera or gallery capture with room/container tags |
| Scanning HUD | Laser sweep and neural-vision status while a photo is analyzed |
| Search & Results | Bilingual search with explainable score breakdowns |
| Memory Graph | Chronological sightings with photo evidence and location corrections |
| Departure Reminders | Category checklists and alarms |
| AR Visual Finder | Live viewfinder with reticles and compass |
| Settings & Diagnostics | App lock, storage usage, feedback reset, diagnostics, data wipe |
| About | Developer profile, system specs, and credit |

Replay the splash anytime from **Settings > About Findora**.

---

## 🎨 Brand

- **Logo:** FINDORA ORBIT, a glowing location orb inside a tracking ring, with cyan neural connections and a small beacon at the center.
- **Palette:**
  - Primary: Electric Violet `#8B5CF6` / `#7C3AED`
  - Secondary: Neon Blue `#3B82F6`
  - Accent: Cyan `#00F0FF` / `#06B6D4`
  - Background: Midnight Obsidian `#080811` / `#0B0B14`
  - Cards: Dark glassmorphism with neon rim highlights
- **Typography:** Geometric sans-serif (Inter or Outfit style) with open letter-spacing.

---

## 🧪 Testing

- `flutter analyze`: 0 warnings, 0 errors.
- Unit and widget tests: 50/50 passing, covering:
  - Bilingual query parsing (English/Hindi)
  - Item identity, memory graph, and location correction
  - Routine checklists, filters, and reminders
  - Search service and feedback
  - Voice search and offline capability
  - AR finder and memory repository
- Build: `assembleDebug` succeeds with Flutter 3.47+ and the Android SDK.

---

## 📥 Installation

### Android (recommended)

1. Tap the download link above, or get `Findora.apk` from the [latest release](https://github.com/BOT9315/findora/releases/latest).
2. If Android asks, allow installs from your browser or file manager (**Settings > Apps > Special access > Install unknown apps**).
3. Open the APK and tap **Install**.

### Via ADB

```bash
adb install -r Findora.apk
```

### Build from source

Requires Flutter 3.47+.

```bash
git clone https://github.com/BOT9315/findora.git
cd findora
flutter pub get
flutter build apk --debug   # output: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📄 License & Credits

- **License:** MIT. See [LICENSE](LICENSE).
- **Author:** Ankush Kumar
- **Package:** `com.findmystuff.ai.find_my_stuff_ai`
