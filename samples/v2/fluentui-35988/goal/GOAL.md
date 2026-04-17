# PR #35988 — feat(react-headless-components-preview): add more components and their stories

## PR body

## Previous Behavior

The `@fluentui/react-headless-components-preview` package (introduced in #35931) only exposed headless implementations for `Button`, `Accordion`/`AccordionItem`, and `Divider`.

## New Behavior

Expands the headless components preview package with many more components and makes the package public (publishable via beachball).

### New headless components added

- **Avatar**
- **Badge**
- **Breadcrumb** (including `BreadcrumbButton`, `BreadcrumbDivider`, `BreadcrumbItem`)
- **Checkbox**
- **Field**
- **Input**
- **Label**
- **Link**
- **RadioGroup** / **Radio**
- **Rating** / **RatingItem**
- **Skeleton** / **SkeletonItem**
- **Slider**
- **SpinButton**
- **Spinner**
- **Switch**
- **TabList** / **Tab**
- **ToggleButton**

### Simple re-export wrappers added

`ProgressBar`, `SearchBox`, `Select`, `Textarea`

### Existing component updates

- **Accordion** / **AccordionItem** — improved types
- **Button** — improved types
- **Divider** — improved types

### Other changes

- Made `@fluentui/react-headless-components-preview` public (removed `private` flag, added `beachball` config)
- Added `@microsoft/focusgroup-polyfill` peer dependency (used by TabList keyboard navigation)
- Added change file for `@fluentui/react-headless-components-preview`

> **Note:** The `@fluentui/react-tabs` export additions (`TabBaseProps`, `TabBaseState`, etc.) are in a separate PR: #35989

## Related Issue(s)

- Fixes #
