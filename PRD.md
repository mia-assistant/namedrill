# NameDrill — Product Requirements Document

**Version:** 1.0 MVP  
**Last updated:** 2026-02-05  
**Author:** Mia  

---

## 1. Overview

### 1.1 Problem Statement

Teachers meet 100+ new students every semester. Forgetting names damages rapport, makes students feel invisible, and undermines classroom management. Existing solutions (paper lists, mental tricks) don't scale.

### 1.2 Solution

A flashcard app that uses spaced repetition to help teachers learn and retain student names through photo-based drills.

### 1.3 Target User

**Primary:** K-12 and university teachers (US, UK, Spain initially)

**Characteristics:**
- Meet 50-200+ new faces per semester
- Non-technical, need zero-friction setup
- Price-sensitive, subscription-averse
- Privacy-conscious about student photos

### 1.4 Success Metrics (MVP)

| Metric | Target |
|--------|--------|
| Day 7 retention | >30% |
| Groups created per user | >1.5 avg |
| Learn sessions per week | >3 avg |
| App Store rating | >4.5 |
| Premium conversion | >5% |

---

## 2. Features

### 2.1 Core Features (MVP)

#### 2.1.1 Groups Management

**Description:** Organize people into named groups (classes, periods, sections).

**Requirements:**
- Create group with name (required) and optional color/icon
- View all groups on home screen as cards
- Each card shows: name, photo grid preview (up to 6 faces), progress %
- Edit group name/color
- Delete group (with confirmation)
- Reorder groups via drag-and-drop

**Free tier limit:** 2 groups  
**Premium:** Unlimited groups

---

#### 2.1.2 People Management

**Description:** Add individuals with photo and name.

**Requirements:**
- Add person via camera (preferred) or photo library
- Fields:
  - Photo (required)
  - Name (required, up to 100 chars)
  - Notes (optional, up to 500 chars, freeform)
- Edit person details
- Delete person (with confirmation)
- Move person to different group
- Bulk photo import: select multiple photos, then name each sequentially

**Free tier limit:** 25 people per group  
**Premium:** Unlimited people

---

#### 2.1.3 Learn Mode

**Description:** Flashcard-style learning with spaced repetition.

**Requirements:**
- Two card types (randomly alternated):
  - **Face → Name:** Show photo, tap to reveal name
  - **Name → Face:** Show name, tap to reveal photo
- After reveal, user taps "Got it" or "Forgot"
- Spaced repetition algorithm adjusts frequency:
  - "Forgot" = show again soon (within same session + next session)
  - "Got it" = increase interval (1 day → 3 days → 7 days → 14 days)
- Session length: 10-20 cards (user configurable in settings)
- Progress bar showing cards remaining
- End screen: cards reviewed, accuracy %, "weakest" names to focus on

---

#### 2.1.4 Quiz Mode

**Description:** Timed challenge to test recall under pressure.

**Requirements:**
- Format: Show face → 4 name options (multiple choice)
- Timer: 60 seconds per round
- Scoring: +1 correct, 0 wrong, no penalty
- Track per-group: high score, current streak (consecutive days with quiz)
- End screen: score, high score, streak, missed names
- Require minimum 8 people in group to enable quiz (need enough options)

---

#### 2.1.5 Progress Tracking

**Description:** Visualize learning progress.

**Requirements:**
- Per-group stats:
  - % learned (names with interval ≥7 days)
  - Total people
  - Last practiced date
- Global stats:
  - Daily streak (consecutive days with any learn/quiz session)
  - Total people across all groups
  - Weekly activity chart (last 7 days)
- "Weakest names" list: bottom 5 by retention score, quick-access to practice

---

#### 2.1.6 Notifications

**Description:** Daily reminders to maintain learning habit.

**Requirements:**
- Toggle on/off
- Configurable time (default: 8:00 AM)
- Smart copy rotation:
  - "3rd period has 5 names to review"
  - "Keep your 7-day streak alive!"
  - "You're 80% there with Period 2"
- Deep link to most relevant group (lowest progress or due for review)

---

#### 2.1.7 Data Management

**Description:** Local-first with user control.

**Requirements:**
- All data stored on device (SQLite + app sandbox for photos)
- Export: generate JSON + photos zip file, save to device/share
- Import: restore from backup file
- Reset progress (keep people, clear learning data)
- Delete all data (full wipe)

---

### 2.2 Non-Functional Requirements

| Requirement | Specification |
|-------------|---------------|
| Platform | Android (primary), iOS (secondary) |
| Min Android | API 24 (Android 7.0) |
| Min iOS | iOS 13 |
| Offline | 100% functional offline |
| Performance | App launch <2s, screen transitions <300ms |
| Storage | ~5MB base + ~200KB per person (photos compressed) |
| Accessibility | WCAG 2.1 AA compliance, screen reader support |
| Dark mode | System default + manual toggle |

---

### 2.3 Deliberately Excluded (v1)

| Feature | Reason |
|---------|--------|
| AI face recognition | Privacy concerns, complexity, cost |
| Cloud sync | Privacy headaches, backend cost |
| Social/sharing | Unnecessary for core value |
| Seat mapping | Complex UI, low priority |
| Multiple photo per person | Scope creep |
| B2B/admin features | Post-validation |

---

## 3. User Flows

### 3.1 Onboarding (First Launch)

```
[Splash] 
    ↓
[Screen 1: Value Prop]
"Never forget a student's name again"
Illustration of teacher + students
[Continue]
    ↓
[Screen 2: How It Works]
"Add photos → Practice daily → Remember forever"
3-step illustration or animation
[Continue]
    ↓
[Screen 3: Camera Permission]
"Take photos of your class roster"
[Enable Camera] → system prompt
[Maybe Later] → continue without
    ↓
[Home Screen - Empty State]
"Create your first group to get started"
[+ New Group]
```

### 3.2 Add First Group + People

```
[Home - Empty]
    ↓ tap [+ New Group]
[Create Group]
Enter name: "Period 3 - Biology"
Select color (optional)
[Create]
    ↓
[Group Detail - Empty]
"Add your first student"
[+ Add Person] | [+ Bulk Import]
    ↓ tap [+ Add Person]
[Camera / Gallery Choice]
    ↓ take/select photo
[Add Person Form]
Photo preview
Name: [___________]
Notes: [___________] (optional)
[Save]
    ↓
[Group Detail - 1 person]
Repeat until done
```

### 3.3 Learn Session

```
[Group Detail]
    ↓ tap [Learn]
[Learn Mode]
Card 1/15: [Photo]
    ↓ tap card
[Photo + Name revealed]
[Forgot] | [Got It]
    ↓ tap choice
Card 2/15: [Name: "Sarah Chen"]
    ↓ tap card
[Name + Photo revealed]
... repeat ...
    ↓ complete
[Session Summary]
15 cards reviewed
87% accuracy
Weakest: Marcus, Aisha, Jordan
[Practice Weak] | [Done]
```

### 3.4 Quiz Session

```
[Group Detail]
    ↓ tap [Quiz]
[Quiz Mode]
Timer: 60s
[Photo of student]
[Name A] [Name B]
[Name C] [Name D]
    ↓ tap answer
✓ Correct! / ✗ Wrong (show correct)
Next card (auto-advance 1s)
... repeat until timer ends ...
    ↓
[Quiz Results]
Score: 12
High Score: 15 ⭐
Streak: 5 days 🔥
Missed: Marcus, Aisha
[Try Again] | [Done]
```

---

## 4. Information Architecture

### 4.1 Screen Map

```
App
├── Onboarding (first launch only)
│   ├── Value Prop
│   ├── How It Works
│   └── Permissions
│
├── Home
│   ├── Groups List
│   ├── Global Stats Summary
│   ├── [+ Add Group]
│   └── [Settings]
│
├── Group Detail
│   ├── People Grid
│   ├── Group Stats
│   ├── [+ Add Person]
│   ├── [Bulk Import]
│   ├── [Learn]
│   ├── [Quiz]
│   └── [Edit Group]
│
├── Add/Edit Person
│   ├── Photo Capture/Select
│   ├── Name Input
│   ├── Notes Input
│   └── [Delete] (edit only)
│
├── Learn Mode
│   ├── Card View
│   ├── Progress Bar
│   └── Session Summary
│
├── Quiz Mode
│   ├── Question View
│   ├── Timer
│   └── Results Screen
│
├── Settings
│   ├── Notifications Toggle + Time
│   ├── Dark Mode Toggle
│   ├── Export Data
│   ├── Import Data
│   ├── Reset Progress
│   ├── Delete All Data
│   ├── Restore Purchases
│   ├── About
│   └── Feedback/Support
│
└── Premium Upgrade (modal/screen)
    ├── Feature Comparison
    └── Purchase Button
```

### 4.2 Data Model

```
Group
├── id: UUID
├── name: String (required)
├── color: String (hex, optional)
├── createdAt: DateTime
├── updatedAt: DateTime

Person
├── id: UUID
├── groupId: UUID (FK → Group)
├── name: String (required)
├── photoPath: String (local file path)
├── notes: String (optional)
├── createdAt: DateTime
├── updatedAt: DateTime

LearningRecord
├── id: UUID
├── personId: UUID (FK → Person)
├── interval: Int (days until next review)
├── easeFactor: Float (SM-2 algorithm)
├── nextReviewDate: Date
├── reviewCount: Int
├── lastReviewedAt: DateTime

QuizScore
├── id: UUID
├── groupId: UUID (FK → Group)
├── score: Int
├── date: Date

UserStats
├── currentStreak: Int
├── lastActiveDate: Date
├── longestStreak: Int

Settings
├── notificationsEnabled: Boolean
├── notificationTime: Time
├── darkMode: String (system/light/dark)
├── isPremium: Boolean
├── premiumPurchaseDate: DateTime (nullable)
```

---

## 5. Spaced Repetition Algorithm

Using simplified SM-2:

```
On review:
  if response == "Forgot":
    interval = 1
    easeFactor = max(1.3, easeFactor - 0.2)
  else if response == "Got It":
    if reviewCount == 0:
      interval = 1
    else if reviewCount == 1:
      interval = 3
    else:
      interval = round(interval * easeFactor)
    easeFactor = easeFactor + 0.1
  
  nextReviewDate = today + interval days
  reviewCount += 1

Card selection priority:
  1. Cards where nextReviewDate <= today (due)
  2. New cards (never reviewed)
  3. Cards closest to due date

Session ends when:
  - 15 cards reviewed (default), OR
  - No more due/new cards
```

---

## 6. Monetization

### 6.1 Pricing

| Tier | Price | Limits |
|------|-------|--------|
| Free | $0 | 2 groups, 25 people/group |
| Premium | $4.99 (one-time) | Unlimited groups, unlimited people |

### 6.2 Upgrade Triggers

Show upgrade prompt when user:
- Tries to create 3rd group
- Tries to add 26th person to a group
- Taps "Premium" in settings

### 6.3 Upgrade Screen Content

```
Unlock NameDrill Premium

FREE                    PREMIUM
2 groups                Unlimited groups
25 people/group         Unlimited people
All learning features   All learning features
                        Support indie dev ❤️

[Unlock for $4.99]
One-time purchase. No subscription.

[Restore Purchase]
```

---

## 7. Localization

### 7.1 MVP Languages

- English (en) — primary

### 7.2 Phase 2 Languages

- Spanish (es)
- German (de)
- French (fr)

### 7.3 Implementation

- All user-facing strings externalized from day 1
- Use Flutter intl/ARB files
- RTL layout support flagged but not implemented in MVP
- Date/time formatting via platform locale

---

## 8. Technical Specifications

### 8.1 Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.24+ |
| State Management | Riverpod or Provider |
| Local DB | SQLite via sqflite/drift |
| Image Storage | App documents directory |
| Image Processing | image_picker, image_cropper |
| Notifications | flutter_local_notifications |
| Purchases | in_app_purchase (or RevenueCat) |
| Analytics | Firebase Analytics (optional) |

### 8.2 Photo Handling

- Compress to max 800px width on save
- JPEG quality 80%
- Store in app sandbox (not accessible to other apps)
- Filename: `{personId}.jpg`

### 8.3 Permissions

| Permission | When Requested | Fallback |
|------------|----------------|----------|
| Camera | First "Add Person" or onboarding | Can use gallery only |
| Photo Library | First "Add Person" from gallery | Required for gallery import |
| Notifications | Settings toggle or post-first-session prompt | App works without |

---

## 9. App Store

### 9.1 Metadata

**App Name:** NameDrill — Learn Names Fast

**Subtitle:** Flashcards for teachers

**Keywords:** names, faces, teacher, students, flashcards, memory, classroom, spaced repetition, learn names, remember names

**Category:** Education

**Age Rating:** 4+

### 9.2 Screenshots (Priority Order)

1. Home screen with groups
2. Learn mode (face card)
3. Quiz mode in action
4. Progress stats
5. Add person flow

### 9.3 Description

```
Never forget a student's name again.

NameDrill helps teachers learn and remember every student's name using proven spaced repetition techniques. Add photos, practice daily, and build lasting connections with your class.

FEATURES
• Create groups for each class or period
• Add students with photos and notes
• Learn mode: flashcard-style practice
• Quiz mode: timed challenges to test yourself
• Track your progress and streaks
• Daily reminders to keep practicing

PRIVACY FIRST
All data stays on your device. No accounts, no cloud, no tracking. Your students' photos never leave your phone.

Built by teachers, for teachers.
```

---

## 10. Timeline

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Foundation | Project setup, data models, navigation, basic UI shell | 3 days |
| 2. Groups & People | CRUD for groups/people, photo capture, bulk import | 1.5 weeks |
| 3. Learn Mode | Card UI, reveal animation, spaced repetition logic | 1.5 weeks |
| 4. Quiz Mode | Multiple choice UI, timer, scoring, results | 1 week |
| 5. Progress & Stats | Stats calculations, visualizations, streaks | 4 days |
| 6. Premium & Polish | IAP integration, upgrade flow, notifications, dark mode | 1 week |
| 7. Testing & Launch | QA, beta testing, App Store prep, screenshots | 1 week |

**Total:** ~7 weeks

---

## 11. Success Criteria for Launch

- [ ] Core flows work offline without crashes
- [ ] Premium purchase completes successfully
- [ ] 10+ beta testers have used app for 1+ week
- [ ] App Store screenshots and metadata complete
- [ ] Privacy policy published
- [ ] <2s cold start on mid-range devices
- [ ] No critical accessibility issues

---

## 12. Post-MVP Roadmap

| Version | Features |
|---------|----------|
| 1.1 | Widget for home screen (today's reviews), Apple Watch complication |
| 1.2 | Profession templates (sales, healthcare), additional fields |
| 1.3 | iCloud/Google Drive backup (optional opt-in) |
| 2.0 | Team sync for departments, B2B tier |

---

## 13. Open Questions

1. **App icon:** Face silhouette? Brain? Flashcard? Need design direction.
2. **Onboarding photos:** Use illustrations or stock photos? (Rights issue if stock)
3. **Beta distribution:** TestFlight only, or also Firebase App Distribution for Android?
4. **Analytics:** Include Firebase Analytics in MVP or stay fully offline?

---

*End of document.*
