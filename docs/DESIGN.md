# ODBR Design System

## 1. Atmosphere & Identity

ODBR feels like a clean neighborhood utility: fast, friendly, and practical. The signature is a bright card-based scan flow where the user always sees the next concrete action: take a photo, read the result, correct it if needed, or move to a nearby Nephron option.

## 2. Color

### Palette

| Role | Token | Light | Dark | Usage |
| --- | --- | --- | --- | --- |
| Surface/base | `AppTheme.background` | `#F7FAF3` | `#111412` | App background |
| Surface/card | `AppTheme.card` | `#FFFFFF` | `#1A1F1B` | Cards and panels |
| Surface/mint | `AppTheme.mintSurface` | `#EAF6ED` | `#173323` | Scan and success surfaces |
| Surface/yellow | `AppTheme.yellowSurface` | `#FFF5D7` | `#3B2D0B` | Caution surfaces |
| Text/primary | `AppTheme.primaryText` | `#17211B` | `#F7FAF3` | Titles and body |
| Text/secondary | `AppTheme.secondaryText` | `#66736B` | `#B4BDB7` | Supporting copy |
| Border/default | `AppTheme.border` | `#E5EDE4` | `#2D352F` | Card outlines |
| Accent/primary | `AppTheme.accent` | `#16A765` | `#49D88E` | Primary actions |
| Accent/deep | `AppTheme.deepGreen` | `#087247` | `#96F0BF` | Strong labels |
| Status/warning | `AppTheme.warning` | `#C27A00` | `#FFCA4E` | Uncertain results |

### Rules

- Green is reserved for primary actions, successful categories, and Nephron routing.
- Warm yellow is used only for caution or uncertainty.
- Surfaces stay mostly white or mint-tinted; no large saturated panels.

## 3. Typography

### Scale

| Level | Size | Weight | Line Height | Tracking | Usage |
| --- | --- | --- | --- | --- | --- |
| H1 | 32pt | Semibold | 1.15 | 0 | Screen header |
| H2 | 24pt | Semibold | 1.2 | 0 | Major cards |
| H3 | 18pt | Semibold | 1.25 | 0 | Section headings |
| Body | 16pt | Regular | 1.45 | 0 | Default text |
| Body/sm | 14pt | Regular | 1.4 | 0 | Secondary text |
| Caption | 12pt | Medium | 1.3 | 0 | Badges and metadata |

### Font Stack

- Primary: iOS system font, rounded where it improves app friendliness.
- Mono: SF Mono only for short confidence or material labels if needed.

### Rules

- Korean text must avoid narrow containers that orphan one- or two-syllable endings.
- Buttons and chips use concise nouns or verbs, never paragraph text.

## 4. Spacing & Layout

### Base Unit

All spacing derives from 4pt.

| Token | Value | Usage |
| --- | --- | --- |
| `AppTheme.Spacing.xs` | 4pt | Icon gaps |
| `AppTheme.Spacing.sm` | 8pt | Compact rows |
| `AppTheme.Spacing.md` | 12pt | Chip groups |
| `AppTheme.Spacing.lg` | 16pt | Default card spacing |
| `AppTheme.Spacing.xl` | 24pt | Screen section spacing |
| `AppTheme.Spacing.xxl` | 32pt | Header spacing |

### Rules

- Primary content uses a single-column mobile layout.
- Cards use 16-24pt internal padding depending on density.
- Bottom tab navigation separates the three core jobs: scan, guide, and Nephron.

## 5. Components

### App Tab Shell
- **Structure**: Native `TabView` with three tabs.
- **Variants**: Scan, Guide, Nephron.
- **States**: selected, unselected.
- **Accessibility**: SF Symbols plus text labels.
- **Motion**: Native tab transition only.

### Utility Card
- **Structure**: Rounded rectangle background, optional icon tile, title, body, action row.
- **Variants**: plain, highlighted, caution.
- **States**: default, pressed for tappable rows.
- **Accessibility**: Text labels must stand alone without relying on color.
- **Motion**: Subtle button press only.

### Scan Surface
- **Structure**: Camera/photo preview, center frame, bottom primary action.
- **Variants**: empty preview, captured photo.
- **States**: ready, captured, result available.
- **Accessibility**: Camera action uses a descriptive label.
- **Motion**: No decorative loop.

### Result Card
- **Structure**: Category header, evidence chips, prep steps, correction chips, optional Nephron CTA.
- **Variants**: confident, caution, corrected.
- **States**: default, corrected.
- **Accessibility**: Confidence shown as text, not color only.
- **Motion**: Result appears with native insertion animation.

### Guide Row
- **Structure**: Category icon tile, title, material hint, and preparation steps.
- **Variants**: normal, caution.
- **States**: default.
- **Accessibility**: Each row reads as one disposal guide item.
- **Motion**: None.

## 6. Motion & Interaction

| Type | Duration | Easing | Usage |
| --- | --- | --- | --- |
| Micro | 100-150ms | ease-out | Button press |
| Standard | 200-250ms | ease-in-out | Result insertion |

Motion exists only for state changes: capture result, tab change, and button press. Decorative idle animation is avoided.

## 7. Depth & Surface

### Strategy

Mixed: tonal-shift for page depth, hairline borders for card boundaries, and very soft shadows only on the primary scan card.

| Level | Treatment | Use |
| --- | --- | --- |
| Base | Tonal background | App canvas |
| Card | 1pt border + white fill | Guide and result cards |
| Primary | Soft green shadow | Main scan surface |
