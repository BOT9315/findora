# FINDORA 🔍🪐

**Tagline:** *Never Lose What Matters.*  
**Developer:** Ankush  
**Credit:** Created & Developed by Ankush  
**Logo Concept:** FINDORA ORBIT

---

## 🌟 Brand Identity: FINDORA ORBIT

FINDORA is a futuristic, personal visual-memory application that helps you locate misplaced physical belongings by searching photos of your real-world surroundings.

### Unique Logo Concept – FINDORA ORBIT
- **Main Symbol:** A glowing futuristic location orb surrounded by an intelligent circular tracking ring.
- **AI Neural Circuitry:** Delicate cyan and electric violet synaptic connections illuminating inside the orb.
- **Center Silhouette:** A tiny glowing object silhouette (locator beacon & key core).
- **Color Palette:**
  - **Primary:** Electric Violet / Royal Purple (`#8B5CF6` / `#7C3AED`)
  - **Secondary:** Neon Blue (`#3B82F6`)
  - **Accent:** High-Voltage Cyan (`#00F0FF` / `#06B6D4`)
  - **Background:** Deep Midnight Obsidian Black (`#080811` / `#0B0B14`)
  - **Cards:** Dark Glassmorphism with glowing neon rim highlights
- **Typography:** Modern geometric sans-serif (Inter / Outfit style) with sleek letter-spacing.

---

## 🎬 8-Step Custom Splash Animation Sequence

The app features a custom procedural animation sequence:
1. **Dark Midnight-Purple Atmosphere:** Spawns a deep obsidian-to-midnight purple radial aura.
2. **Central Cyan Particle:** A glowing cyan particle emerges at the focal center, pulsing with bioluminescent light.
3. **Orbital Rings Formation:** Dual counter-rotating orbital tracking rings (Electric Violet and Neon Blue) expand with precision data tick marks.
4. **AI Neural Synapses:** Intricate neural network lines and nodes illuminate outward, connecting the core to the orbital ring.
5. **FINDORA ORBIT Emergence:** The 3D crystalline orb and locator beacon bloom smoothly into view.
6. **Bold Typography:** `F I N D O R A` in bold geometric typography with electric violet and cyan drop shadows.
7. **Official Tagline:** `Never Lose What Matters.` in high-voltage cyan.
8. **Developer Credit:** Elegant bottom pill badge displaying `Created & Developed by Ankush` with one-tap skip.

*(Users can replay this custom animation anytime from **Settings > About Findora**)*.

---

## 📱 Designed Application Screens

1. **Splash Screen:** Procedural 8-phase animation sequence with FINDORA ORBIT logo and developer credit.
2. **Onboarding Screen:** Dark glassmorphic cards introducing on-device visual memory, bilingual search, air-gapped privacy, and observational truth.
3. **Vault Access (Login & Signup):** Cyberpunk dark vault screen supporting biometric fingerprint/FaceID, passcode PIN unlock, and zero-friction guest pass.
4. **Home Dashboard:** Hero header with FINDORA ORBIT status emblem ("NEURAL ENGINE ACTIVE"), quick action orbs, room collections, and recent visual sightings.
5. **Add Room / Photo Screen:** Instant camera and gallery capture with room/container tagging.
6. **AI Scanning HUD Experience:** Animated laser scan sweep, rotating targeting reticle, corner brackets, and real-time neural vision status telemetry.
7. **Object Search & Results:** Natural language search in English and Hindi (*"Mera black charger kahan hai?"*, *"Keys on desk"*), multi-factor explainable score breakdowns, and interactive reticles.
8. **Personal Memory Graph:** Visual chronological trajectory (*First Observed* → *Later Observed* → *Most Recent Observation*) linked to photo evidence, with manual location corrections.
9. **Smart Departure Reminders:** Departure checklists categorized into **College Prep**, **Daily Commute (Office)**, **Gym Session**, and **Weekend Travel** with departure alarms.
   > **Observational Constraint:** Strictly displays *"Historical observation • NOT verified packed"* until explicitly confirmed by the user.
10. **AR Visual Finder Mode:** Live camera viewfinder HUD with scanning reticles, compass azimuth, and documented ARCore limitations.
11. **Settings & Diagnostics:** Biometric app lock, storage breakdown, feedback reset, air-gapped diagnostics, and complete data wipe.
12. **About Findora Screen:** Dedicated developer profile, system specs, and developer credit: **Created & Developed by Ankush**.

---

## 🧪 Testing & Verification

- **Static Analysis:** `flutter analyze` completed with **0 warnings and 0 errors**.
- **Unit & Widget Tests:** **50 out of 50 test suites passed**:
  - `test/widget_test.dart` (FindoraApp root rendering, title verification)
  - `test/features/search/query_parser_test.dart` (Bilingual English/Hindi NLP tokenization)
  - `test/features/items/items_repository_test.dart` (Item identities, memory graph, manual location correction)
  - `test/features/routines/routines_repository_test.dart` (Checklists, category filters, reminder scheduling)
  - `test/features/search/search_service_test.dart` & `search_feedback_test.dart`
  - `test/features/search/voice_search_service_test.dart` & `offline_capability_test.dart`
  - `test/features/ar/ar_visual_finder_test.dart` & `memory_repository_test.dart`
- **Gradle Compilation:** Built with Android SDK & Flutter 3.47+ (`assembleDebug` passed).

---

## 📦 Download & Installation

The branded package is compiled and ready for installation:

- **Download APK:** [`C:\Users\akrk0\Downloads\Findora.apk`](file:///C:/Users/akrk0/Downloads/Findora.apk) *(~196 MB, includes offline TFLite models)*
- **Project Build Output:** [`build\app\outputs\flutter-apk\app-debug.apk`](file:///C:/Users/akrk0/.gemini/antigravity/scratch/find_my_stuff_ai/build/app/outputs/flutter-apk/app-debug.apk)

### Install via ADB:
```bash
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "C:\Users\akrk0\Downloads\Findora.apk"
```
