# linoriarage — local mirror (C:\Users\PC\Documents\internalroblox)

Distribution source is the repo shxxtzz/linoriarage (single loadstring).
This folder mirrors committed files for local editing + staging.

## Files
- main.lua — menu scaffold (5 tabs, zero cheat logic). COMMITTED as repo main.lua.
- utils.lua — shared target-selection core. Commit as modules/utils.lua NEXT
  (after the empty menu renders clean in-game).
- SPEC.md — source of truth lives at C:\Users\PC\.opencode\plan\linoriarage-spec.md;
  push a copy as repo SPEC.md.

## Order (per build task list)
1. SPEC.md + main.lua → screenshot empty menu (DONE when verified).
2. modules/utils.lua → console-test acquire().
3. modules/esp.lua → lobby + match tracking.
4. modules/aimbot.lua → mouse-move closed loop, sticky+grace, visible-only.
5. modules/silentaim.lua → __namecall hook (runtime-verified method).
6. modules/triggerbot.lua → raycast + clientItem:Input(nil).
7. staffdetector + spoofer (isolated, last).
8. Release bundle (single file), final loadstring.
