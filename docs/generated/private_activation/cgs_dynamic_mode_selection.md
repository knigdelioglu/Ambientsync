# CGS Dynamic Mode Selection

## Display fingerprint
- Samsung fingerprint check is required before any CGS mode switch.
- Built-in display is never touched.

## CGS mode count
- The scanner walks the CGS/SLS mode list at runtime.
- Public duplicate mode count is tracked separately for diagnostics.

## Dynamic normal candidate
- Selected from the scanned CGS list.
- Must match the target logical resolution and preferred refresh rate.
- For the Samsung profile, this is expected to resolve to the normal QHD mode when present.

## Dynamic HiDPI candidate
- Selected from the scanned CGS list.
- Must match the target logical resolution, backing resolution, HiDPI state, and refresh target.
- The scanner ranks candidates by logical match, pixel match, HiDPI state, refresh, scale, and aspect ratio.

## Samsung fallback candidate
- Known profile fallback is allowed only for the Samsung fingerprint:
  - Vendor `0x4C2D`
  - Product `0x76AB`
  - Serial `0x30413332`
- The fallback is only accepted after CGS description validation confirms it matches the target mode shape.

## Selected HiDPI mode
- Dynamic candidate is preferred.
- Verified Samsung fallback is used only when the dynamic scan cannot find a suitable HiDPI candidate.

## Selected normal mode
- Dynamic candidate is preferred.
- Verified Samsung fallback is used only when the dynamic scan cannot find a suitable normal candidate.

## Final decision
- No blind `74` application is allowed.
- Apply only a scanned candidate or a verified Samsung fallback.
- If neither exists, do not switch modes.
