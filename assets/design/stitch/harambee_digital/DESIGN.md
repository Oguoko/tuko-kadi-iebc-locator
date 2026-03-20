# Design System Strategy: Civic-Tech Precision for Gen Z

## 1. Overview & Creative North Star
**The Creative North Star: "The Modern Oracle"**

To design for Gen Z in Kenya is to balance two worlds: the unwavering credibility required for civic participation and the high-velocity, thumb-driven energy of modern social platforms. This design system departs from "government-drab" by adopting a philosophy of **Editorial Fluidity**. 

We move beyond the rigid, boxy layouts of traditional apps. Instead, we use intentional asymmetry, overlapping card structures, and dramatic typographic scales to create a sense of momentum. The interface shouldn't feel like a static form; it should feel like a guided conversation—premium, fast, and authoritative.

---

## 2. Color & Surface Philosophy
The palette is rooted in the "Deep Forest" of Kenyan institutional trust, punctuated by "Electric Lime" to signal technological forward-thought.

### The "No-Line" Rule
**Lines are a failure of layout.** In this system, 1px solid borders are strictly prohibited for sectioning. We define boundaries exclusively through:
- **Tonal Shifts:** Placing a `surface-container-low` element against a `surface` background.
- **Negative Space:** Using the spacing scale (specifically `8` to `12`) to let the eye define the grouping.
- **Glassmorphism:** Using `surface-container-highest` at 70% opacity with a `24px` backdrop blur for floating elements like bottom sheets.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of premium materials.
- **Base Layer:** `surface` (#fcf9f8)
- **Secondary Grouping:** `surface-container-low` (#f6f3f2)
- **High-Interaction Cards:** `surface-container-lowest` (#ffffff) to provide "pop" against the off-white base.
- **Active Elements:** Use `primary-container` (#004d40) for high-importance zones where `on-primary` text provides maximum contrast.

### Signature Textures
Main CTAs and Hero backgrounds must utilize a **Subtle Kinetic Gradient**. Transitioning from `primary` (#00342b) to `primary-container` (#004d40) at a 135-degree angle adds a "soul" to the UI that flat colors lack.

---

## 3. Typography: The Editorial Voice
We utilize a pairing of **Plus Jakarta Sans** (Display/Headline) for a modern, geometric personality and **Inter** (Body/UI) for technical legibility.

| Level | Token | Font | Size | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Plus Jakarta Sans | 3.5rem | High-impact numbers (e.g., Distance) |
| **Headline** | `headline-lg` | Plus Jakarta Sans | 2rem | Major section headers; Bold weight |
| **Title** | `title-md` | Inter | 1.125rem | Card titles; Medium weight |
| **Body** | `body-md` | Inter | 0.875rem | Information and descriptions |
| **Label** | `label-sm` | Inter | 0.6875rem | Micro-data and timestamps |

---

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering** rather than structural shadows.

- **The Layering Principle:** To lift a card, do not reach for a shadow first. Change its token from `surface-container` to `surface-container-lowest`. This creates a natural "clean" lift.
- **Ambient Shadows:** For floating action buttons or critical overlays, use a "Tinted Ambient" shadow. 
    - *Blur:* 32px | *Spread:* -4px | *Color:* `on-surface` at 6% opacity.
- **The "Ghost Border" Fallback:** If accessibility requires a border (e.g., in high-glare outdoor voting environments), use the `outline-variant` token at **15% opacity**. Never use 100% opacity for borders.
- **Glassmorphism:** Bottom sheets must use a semi-transparent `surface` color with a heavy backdrop blur. This allows the map or list below to "bleed" through, keeping the Gen Z user oriented within the app's spatial logic.

---

## 5. Components

### Cards & Landmarks (The Core Unit)
- **Style:** Use `md` (1.5rem/24px) corner radius. 
- **Structure:** No dividers. Use a `3` (1rem) spacing unit between header and body text.
- **Landmark Visuals:** Use `tertiary-fixed` (#bef500) for "You are here" markers or directional accents to draw the eye instantly.

### Action Buttons
- **Primary:** `primary` background with `on-primary` text. Radius: `full`.
- **Secondary:** `secondary-container` background. No border.
- **States:** On press, the background should shift to `primary-fixed-dim`. 

### Input Fields
- **Container:** `surface-container-high`.
- **Radius:** `sm` (0.5rem) for the input box, but `md` (1.5rem) for the overall card container.
- **Interaction:** On focus, the "Ghost Border" becomes `primary` at 40% opacity—a soft glow rather than a hard line.

### Interaction Chips
- Used for filtering polling stations or ward types.
- **Unselected:** `surface-container-highest`.
- **Selected:** `tertiary` (#253200) with `on-tertiary` (White) or `tertiary-fixed` (#bef500) for high energy.

---

## 6. Do’s and Don’ts

### Do
- **Do** use asymmetrical spacing. A `headline-lg` can have a larger bottom margin than top margin to create a sense of "downward flow."
- **Do** use large touch targets. With "one-hand friendly" as a goal, all interactive elements must be at least 48dp in height.
- **Do** lean into the "Electric Lime" (`tertiary_fixed`) for success states and confirmation highlights. It signals "Go" and "Youth."

### Don’t
- **Don’t** use 1px dividers to separate list items. Use a `surface-container` shift or an extra `1.5` (0.5rem) of vertical whitespace.
- **Don’t** use pure black (#000000). Use `on-surface` (#1b1c1c) to keep the "Editorial" feel soft and premium.
- **Don’t** use small corner radii. Anything under 12px feels "Legacy Tech." Stick to the `md` (24px) and `lg` (32px) tokens.