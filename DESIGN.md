# specmoa.zip UI Design Blueprint

Source: Stitch project `projects/12175641117099358705` (`SpecMoa Certification App Design`)

This document is the implementation blueprint for translating the Stitch design into Flutter. It captures visual tokens, component rules, layout hierarchy, and product-level UI decisions. Do not treat this as Flutter code; use it as the canonical design reference before generating widgets or themes.

## Creative Direction

The app should feel like a curated certification archive: authoritative, organized, premium, and fast. The core mood is a blend of structured dossier, modern fintech smoothness, and lightweight achievement feedback.

Key principles:

- Use tonal layering instead of visible divider lines.
- Prefer calm surfaces, compact hierarchy, and refined spacing.
- Make progress and certifications feel rewarding without becoming playful enough to weaken trust.
- Keep the interface mobile-first. Stitch screen instances are primarily `390px` wide mobile designs.
- Use intentional asymmetry where it improves scanning, but keep repeated lists and data-heavy surfaces predictable.

## Colors

### Core Palette

| Token | Hex | Usage |
| --- | --- | --- |
| `primary` | `#0059B9` | Main actions, active progress, selected state |
| `primary_container` | `#1071E5` | CTA gradient end, emphasized blue surfaces |
| `override_primary` | `#3182F6` | Brand reference blue from Stitch theme |
| `secondary` | `#545F6E` | Secondary emphasis, supporting controls |
| `secondary_container` | `#D5E0F3` | Secondary button backgrounds |
| `tertiary` | `#944600` | Premium certification moments, milestones, special badges |
| `tertiary_container` | `#BA5900` | Strong warm achievement surfaces |
| `error` | `#BA1A1A` | Error states |
| `error_container` | `#FFDAD6` | Error backgrounds |

### Surface Palette

| Token | Hex | Usage |
| --- | --- | --- |
| `surface` / `background` | `#F8F9FB` | App base background |
| `surface_container_lowest` | `#FFFFFF` | Primary cards and list items |
| `surface_container_low` | `#F2F4F6` | Section backgrounds, parent list containers |
| `surface_container` | `#ECEEF0` | Mid-level grouped areas |
| `surface_container_high` | `#E6E8EA` | Nested interactive surfaces |
| `surface_container_highest` | `#E0E3E5` | Progress tracks, disabled/quiet surfaces |
| `surface_dim` | `#D8DADC` | De-emphasized surface states |
| `surface_variant` | `#E0E3E5` | Alternate surface fill |

### Text And Outline Palette

| Token | Hex | Usage |
| --- | --- | --- |
| `on_surface` / `on_background` | `#191C1E` | Primary text, never pure black |
| `on_surface_variant` | `#414754` | Secondary text, metadata |
| `on_primary` | `#FFFFFF` | Text/icons on primary buttons |
| `on_secondary_container` | `#586373` | Text/icons on secondary containers |
| `outline` | `#727785` | Rare accessibility outline only |
| `outline_variant` | `#C1C6D6` | Ghost border fallback at low opacity |

### Color Rules

- Do not use pure black (`#000000`) or hard white-on-dark contrast unless a component explicitly requires it.
- Do not use opaque 1px borders for layout separation.
- Separate surfaces by background tone: for example, a white card on `surface_container_low`.
- Use `primary -> primary_container` as a subtle vertical gradient for high-intent CTAs.
- Use `tertiary` sparingly for rare achievement value: certified status, gold-standard credentials, milestone completion.
- Keep the dominant palette cool and professional, but use warm tertiary accents to avoid a one-note blue UI.

## Typography

### Font Families

- Display, headline, and title: `Plus Jakarta Sans`
- Body and labels: `Inter`
- Numbers, scores, progress values, and certification counts: prefer `Plus Jakarta Sans`

### Type Scale

| Style | Size | Weight | Line Height | Usage |
| --- | ---: | ---: | ---: | --- |
| `display` | 36 | 700 | 44 | Rare top-level hero/stat moments |
| `headlineLg` | 30 | 700 | 38 | Main screen headers |
| `headlineMd` | 26 | 700 | 34 | Major sections |
| `headlineSm` | 22 | 700 | 30 | Card group headings |
| `titleLg` | 20 | 700 | 28 | Primary card titles |
| `titleMd` | 18 | 700 | 26 | Section titles, bottom sheets |
| `titleSm` | 16 | 700 | 24 | List item titles |
| `bodyLg` | 16 | 400 | 26 | Primary readable copy |
| `bodyMd` | 14 | 400 | 22 | Default body and descriptions |
| `bodySm` | 13 | 400 | 20 | Metadata and secondary copy |
| `labelLg` | 14 | 700 | 20 | Buttons, tabs |
| `labelMd` | 12 | 700 | 18 | Tags, compact controls |
| `labelSm` | 11 | 700 | 16 | Overlines, tiny metadata |

### Typography Rules

- Use high scale contrast to avoid a generic template feel.
- Pair `headlineSm` or `titleLg` with compact `labelSm` category tags.
- Letter spacing should generally be `0`. Use slight negative letter spacing only for large display/headline typography if needed.
- Labels may use all caps for small category tags, but avoid long all-caps phrases.
- Korean text must have comfortable line height. Avoid squeezing multi-line Korean labels into fixed-height chips.

## Spacing System

Use a 4px base grid. Stitch theme spacing scale is `2`, so prefer generous but consistent spacing.

| Token | Value | Usage |
| --- | ---: | --- |
| `space0` | 0 | No gap |
| `space1` | 4 | Tiny icon/text gaps |
| `space2` | 8 | List item gaps, compact inner spacing |
| `space3` | 12 | Form field spacing, chip groups |
| `space4` | 16 | Standard component padding |
| `space5` | 20 | Mobile side margin minimum |
| `space6` | 24 | Preferred screen side margin, card vertical padding |
| `space8` | 32 | Section separation |
| `space10` | 40 | Large content breaks |
| `space12` | 48 | Major screen blocks |

Spacing rules:

- Mobile page horizontal padding should be `20px` to `24px`.
- Separate repeated list items with gaps, not divider lines.
- Increase whitespace before adding visual separators.
- Primary cards should generally use `20px` to `24px` internal padding.
- Dense operational rows may use `16px`, but touch targets must remain at least `44px` high.

## Border Radius

Stitch theme roundness is `ROUND_FULL`, but component use is more nuanced.

| Token | Value | Usage |
| --- | ---: | --- |
| `radiusXs` | 6 | Small indicators, compact tags |
| `radiusSm` | 8 | Inputs, small cards, contained list rows |
| `radiusMd` | 16 | Default cards, secondary buttons |
| `radiusLg` | 24 | Feature cards, bottom sheets |
| `radiusFull` | 999 | Primary CTAs, pills, avatars, progress chips |

Radius rules:

- Use pill shapes for high-energy primary actions and progress/status pills.
- Use `radiusMd` for the core card shape.
- Use `radiusSm` for structured data input areas.
- Avoid excessive roundness on dense dashboard/list containers where it harms scanability.

## Shadows And Elevation

Depth should come from layered surfaces first, shadows second.

### Ambient Shadow Tokens

| Token | Value | Usage |
| --- | --- | --- |
| `shadowNone` | none | Most cards and sections |
| `shadowSoft` | `0 8 24 rgba(25, 28, 30, 0.06)` | Raised cards, selected cards |
| `shadowFloating` | `0 16 40 rgba(25, 28, 30, 0.08)` | FABs, menus, bottom sheets |
| `shadowBlueTint` | `0 16 40 rgba(0, 89, 185, 0.06)` | Primary floating emphasis |

Shadow rules:

- Do not use heavy Material-style shadows.
- Use large blur, no spread, low opacity.
- Floating navigation or top bars should use glass treatment: `surface` at roughly 70% opacity with strong blur.
- If an outline is necessary, use `outline_variant` at 15% opacity or primary at 20% opacity for focus.

## Component Rules

### Cards

- Background: `surface_container_lowest`.
- Parent region: usually `surface_container_low`.
- Radius: `radiusMd` or `radiusLg`.
- Padding: `20px` to `24px`.
- No internal divider lines.
- Separate card content through typography, spacing, and surface tone.
- Interactive cards should scale to `0.98` on press and lift subtly.

### Buttons

- Primary: `primary` to `primary_container` subtle gradient, `on_primary` content, pill radius.
- Secondary: `secondary_container` fill, `on_secondary_container` content, `radiusMd`.
- Tertiary/ghost: transparent or tonal background, no border unless needed for accessibility.
- Minimum height: `48px` for main actions, `40px` for compact controls.
- Icons should accompany tool-like actions when available.

### Inputs

- Background: `surface_container_low`.
- Focus background: `surface_container_lowest`.
- Focus outline: 2px primary ghost border at 20% opacity.
- Radius: `radiusSm`.
- Avoid hard borders in resting state.
- Error state: use `error_container` background or small inline `error` text, depending on density.

### Lists

- Parent list surface: `surface_container_low`.
- Items: `surface_container_lowest`.
- Item gap: `8px`.
- No divider lines.
- Preserve clear scan columns: leading icon/status, main title block, trailing action/state.

### Progress And Certification States

- Active progress: `primary`.
- Track: `surface_container_highest`.
- Completed/certified: use `tertiary` icon or small warm accent.
- Scores and counts should use `Plus Jakarta Sans`.
- Progress should feel celebratory but restrained.

### Navigation

- Prefer a glass-like top app bar when content scrolls underneath.
- Bottom navigation should be low-contrast, compact, and highly legible.
- Active nav state uses `primary`; inactive uses `on_surface_variant`.
- Avoid heavy nav containers that visually compete with content cards.

### Chips And Tags

- Use compact rounded pills for category, exam type, difficulty, and status.
- Use `labelSm` or `labelMd`.
- Use tonal backgrounds instead of outlines.
- Limit warm tertiary chips to premium or completion states.

### Modals And Bottom Sheets

- Use `surface_container_lowest`.
- Radius: `radiusLg` at top corners for bottom sheets.
- Shadow: `shadowFloating`.
- Keep actions anchored and obvious.

## Layout Hierarchy

### Mobile Screen Structure

Typical screen order:

1. Glass or tonal top app bar
2. Screen header with title, status, or summary metric
3. Primary content module
4. Secondary grouped sections
5. Repeated card/list content
6. Persistent navigation or primary action, if needed

### Surface Layering

Use this nesting model:

1. App background: `surface`
2. Section band/container: `surface_container_low`
3. Main content card: `surface_container_lowest`
4. Nested controls: `surface_container_high`
5. Active/selected state: primary tonal or gradient treatment

### Density And Scanning

- Certification discovery screens should emphasize quick comparison.
- Detail screens may use larger editorial spacing and stronger hierarchy.
- Timer/exam screens should reduce decoration and prioritize state clarity.
- Dashboard/home screens should surface current progress, pending exams, and recent achievements in the first viewport.

## Motion And Interaction

- Pressed card: scale to `0.98`, duration around `120ms`.
- Card release/open: spring-like return, total around `200ms`.
- State changes should be quick and tactile.
- Avoid slow decorative transitions.
- Progress updates may use short ease-out animation.
- Respect reduced motion settings when available.

## Accessibility

- Maintain strong text contrast against all tonal surfaces.
- Touch targets should be at least `44px`.
- Do not rely on color alone for certification, error, or active states.
- Long Korean labels must wrap cleanly.
- Support dynamic text where feasible; avoid fixed-height text containers for body content.
- Ghost borders may be used when surface contrast alone is insufficient.

## Content And Tone

- Voice: clear, compact, trustworthy.
- Avoid marketing-style hero copy inside the app.
- Labels should be action-oriented and concrete.
- Empty states should guide the next step without sounding promotional.
- Certification names, exam dates, scores, and progress values are primary data and should be visually easy to compare.

## Implementation Notes For Later Flutter Work

- Create design tokens before screen widgets.
- Theme should expose semantic colors rather than raw hex values in widgets.
- Prefer reusable primitives for cards, chips, progress bars, app bars, and buttons.
- Keep Nest/API connection states separate from visual components.
- Flutter code should preserve the no-divider, tonal-layering rule unless a screen has a clear accessibility need.
