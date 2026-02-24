# Card UI recommendations

A single reference for building consistent cards across the app. **First applied to Aid Finder;** use the same patterns for Alerts, Donation Drives, and other list/detail cards.

---

## 1. Design tokens

Use one token set (e.g. `AppTokens` or project theme like `figmaOrange` / `figmaBlack`) so all cards share the same spacing, radius, and colours.

### Spacing (4pt grid)

| Token    | Value | Use for |
|----------|-------|---------|
| space8   | 8 dp  | Between meta rows, horizontal gaps in a row |
| space12  | 12 dp | Section gaps (e.g. title → meta, meta → badges) |
| space16  | 16 dp | **Card padding** (all sides); main content padding |
| space24  | 24 dp | Between stacked cards |

**Rule:** Card padding = 16 dp. Section gaps inside card = 12 dp. Sibling item gaps = 8 dp.

### Border radius

| Token    | Value | Use for |
|----------|-------|---------|
| radiusSm | 8 dp  | Icon buttons, small controls |
| radiusMd | 12 dp | Primary buttons |
| radiusLg | 16 dp | **Cards** |

### Colours

- **Primary**: CTAs, accent bar, key icons (e.g. `#E8600A` / `figmaOrange`).
- **Surface**: Card background (`#FFFFFF`).
- **Border**: Subtle border/dividers (`#EEEEEE`).
- **Text**: Primary (titles), secondary (body/meta), tertiary (hints/icons).
- **Semantic**: success (e.g. "Walk In"), info (e.g. category/type badges).

### Typography

- **Card title**: 16 sp, bold; max 2 lines, ellipsis.
- **Meta (address, hours)**: 13 sp, regular; max 2 lines where needed.
- **Badges / labels**: 11 sp, semi-bold.

### Shadow

- Resting card: light shadow (e.g. blur 8, offset 2).
- Avoid heavy shadows unless elevated (e.g. modal).

---

## 2. Card anatomy

Use this structure for Aid Finder and other service/resource cards:

```
┌─────────────────────────────────────────┐
│ ████ 4 dp accent bar (primary)          │
├─────────────────────────────────────────┤
│ [Title ......................] [Badge]   │  Title row: name + distance badge
│                                         │  12 dp padding
│ 📍 Address                              │  8 dp below title
│ 🕐 Operating hours                      │  4 dp between meta rows (from data)
│                                         │
│ [Type badge]  [Access badge]            │  Category + "Walk In" as pill badges
├────────────── Divider ──────────────────┤
│ [💬] [🗺]     [ Check Eligibility ]    │  Ghost icon buttons + CTA
└─────────────────────────────────────────┘
```

- **Accent bar**: 4 dp height, full width, primary colour.
- **No image block** when there is no image URL (no grey placeholder).
- **Footer**: Divider (1 px, subtle) then actions (ghost icon buttons + primary CTA).
- **Shrink-wrap**: Card root `Column` must use `mainAxisSize: MainAxisSize.min` so the card is only as tall as its content — no empty space at the bottom.

---

## 3. Component rules

### Container

- Background: surface.
- Corner radius: 16 dp.
- Border: 1 px, subtle colour.
- Shadow: light (e.g. blur 8, offset 2).
- `clipBehavior: Clip.antiAlias` when using rounded corners with overflow.

### Meta rows

- Layout: **Icon (14 dp, tertiary colour) + 8 dp + Text**.
- Text: body style, max 2 lines, ellipsis.
- 8 dp between consecutive meta rows.

### Badges

- Pill shape (e.g. radius 100 or 8 dp).
- Padding: 8 dp horizontal, 4 dp vertical.
- Semantic variants: primary (orange), info (blue), success (green).
- Use `Wrap` with 8 dp spacing so badges wrap; avoid more than 2 lines of badges.

### Divider

- Only between content body and footer.
- Height 1, thickness 1, subtle colour.

### Primary CTA (e.g. "Check Eligibility")

- Min height **44 dp** for full-size cards; **36 dp** is acceptable for compact list cards.
- Full-width in card footer when it is the main action.
- Corner radius 12 dp.
- Label: 11–14 sp, semi-bold; optional leading icon.

### Ghost icon buttons (chat, map)

- Size **36×36 dp** (compact but still touch-safe).
- Background: light surface tint; **visible border** (subtle) so targets are clear.
- Corner radius 8 dp.
- Always provide a **Tooltip** (or semantic label) for accessibility.

### Data consistency (operating hours, eligibility)

- **Single source of truth**: Operating hours and eligibility must come from the same fields (e.g. `operatingHours`, `eligibility` on the model) in both the list card and the detail view. Never hard-code "Mon-Fri 9AM-5PM" or "Open to all" in one place while showing different text elsewhere — this causes user-visible bugs.
- In list card: show one line (e.g. meta row) using the same display getter (e.g. `operatingHoursDisplay`).
- In detail sheet: use the same getter for the "Operating Hours" and "Eligibility" sections. Omit duplicate sections that repeat or contradict the same info.

---

## 4. Layout rules

### List of cards (two-column layout)

- **Do not use `GridView` with a fixed `childAspectRatio`** for variable-height cards. GridView forces every cell to the same height (column width ÷ aspect ratio), which creates a **huge empty space at the bottom** when card content is shorter than that height.
- **Use a two-column list instead**: `ListView.builder` where each item is a `Row` with `crossAxisAlignment: CrossAxisAlignment.start`. Each row has two `Expanded` children (left card, right card). Cards then use their **natural height** (`mainAxisSize: MainAxisSize.min` on the card’s root Column). No dead space.
- Padding around list: 16 dp. Vertical gap between rows: 12 dp. Horizontal gap between the two cards in a row: 12 dp.

### Text truncation

- Title: `maxLines: 2`, `overflow: TextOverflow.ellipsis`.
- Address / long meta: `maxLines: 2`, ellipsis.

---

## 5. Do / don't

| Do | Don't |
|----|--------|
| Use tokens for spacing, radius, colours | Hard-code values in the widget |
| Keep card padding at 16 dp | Mix different paddings per card type |
| Use semantic badge colours | One-off custom colours |
| Min 44 dp for tappable buttons | Small icon buttons without size/tooltip |
| Use `Wrap` for badges | Force badges into a single fixed row |
| Use 16 dp radius for cards | Use radius &lt; 12 for cards |
| Omit image area when no URL | Show large grey image placeholder |

---

## 6. Applying to Aid Finder

- **Remove** the image/placeholder block from list and detail.
- **Add** the 4 dp primary accent bar at the top of each card.
- **Structure**: Accent bar → title row (name + **distance as badge**) → address + **operating hours from data** (meta rows) → **category + "Walk In" as coloured pill badges** → divider → **ghost icon buttons (36 dp, visible border)** + "Check Eligibility".
- **Spacing**: 12 dp card content padding, 4/8 dp between elements; footer 12 dp vertical.
- **Layout**: Use a **two-column list** (ListView of rows, each row = two cards with `CrossAxisAlignment.start`), not GridView with fixed aspect ratio. Card uses `mainAxisSize: MainAxisSize.min` so it shrink-wraps and eliminates empty space at the bottom.
- **Data**: Use `operatingHoursDisplay` and `eligibilityDisplay` (or equivalent) from the resource in both list card and detail sheet so operating hours and eligibility are consistent everywhere.

---

## 7. Extending to other screens

- **Alerts**: Same anatomy; accent bar can reflect severity (e.g. colour); add region/type badges; CTA e.g. "View" or "Details".
- **Donation drives / opportunities**: Same tokens and structure; swap meta rows for drive-specific fields (date, goal, category, etc.); keep accent bar, divider, footer pattern.

---

## 8. Removed patterns (and why)

| Removed | Reason |
|---------|--------|
| Large image placeholder (grey box) | Wastes vertical space when no image is available; creates visual noise |
| **GridView with fixed childAspectRatio** | Forces fixed cell height; short content leaves a huge empty space at the bottom of each card |
| Inline colour values | Makes theming / dark mode harder |
| Plain text distance only | Prefer distance as a **badge in the title row** for scannability |
| Category / "Walk In" as plain grey text | Use **coloured pill badges** (info + success) for quick scanning |
| Invisible or borderless icon buttons | **Ghost buttons with visible border** (36 dp) improve affordance |
| Different operating hours in list vs detail | **Single source**: same field (e.g. `operatingHoursDisplay`) in list and detail to avoid bugs |
| Flat CTA without icon | Icon adds affordance and balance |

---

## Reference

These recommendations align with the design system described in:

- **Card design guidelines** (spacing, tokens, anatomy).
- **ServiceCard** (AppTokens, AppBadge, meta rows, divider, AppPrimaryButton, AppIconButton).

When adding new card types, copy the ServiceCard structure (or equivalent), replace domain-specific meta rows, and keep the accent bar, divider, and footer pattern the same.
