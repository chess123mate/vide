## Changes compared to other forks

- meant for use primarily in Roblox-TS (timeout removed) without using jsx
- `defaults` removed
- apply and create use `(instance, props, children)` (props and children are effectively the same thing but separated for Typescript convenience - you can still just use `props` and ignore `children` if desired)
  - children are deparented when an apply call is cleaned up
  - before you could include a source that returned a list of children; you can now also include other properties for the target instance (see below about styling)
- `spring` cleans itself up when owning scope removed
- Remove requiring things to run in "stable scopes" (though, for performance, you should still be careful of creating new instances in effects that change rapidly)
- Added `warn_on_repeated_root_destroy`

Example with custom styles:

```lua
root(function()
	local style = source()
	local label = create("TextLabel", {style})
	style({Text = "Styled"})
	print(label.Text) -- "Styled"
	-- Note: properties are not reverted if the source is changed:
	style(nil)
	print(label.Text) -- "Styled"
	-- Of course you can keep changing the style:
	style({Text = "New"})
	print(label.Text) -- "New"

	-- You can also point a source to another source:
	local alternate = source({Text = "Alternate")})
	style(alternate)
	print(label.Text) -- "Alternate"
	-- In this example, further modifications to `alternate` will still update `label.Text`. If `style` changes to a different source, this will get cleaned up.
	-- Although this example talks of "styles", these mechanics work for any purpose. If `alternate` had instances inside, these would become children of `label`; if they had event connections, these would be properly handled as well.
end)
```

<div align="center">
    <img src="docs/public/full_logo.svg" width="600" />
</div>

Vide is a reactive Luau UI library inspired by [Solid](https://www.solidjs.com/).

- Fully Luau typecheckable
- Declarative and concise syntax.
- Reactively driven.

## Getting started

Read the
[crash course](https://centau.github.io/vide/tut/crash-course/1-introduction)
for a quick introduction to the library.

## Code sample

```luau
local create = vide.create
local source = vide.source

local function Counter()
    local count = source(0)

    return create("TextButton", {
        Text = function()
            return "count: " .. count()
        end,

        Activated = function()
            count(count() + 1)
        end
    })
end
```

or

```ts
import { create, source } from "@rbxts/vide"
function Counter() {
	const count = source(0)
	return create("TextButton", {
		Text: () => "count: " + count(),
		Activated: () => count(count() + 1),
	})
}
```
