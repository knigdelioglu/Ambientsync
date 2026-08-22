# BetterDisplay IOAV Virtual EDID Trace

## Static binary result

- `IOAVServiceSetVirtualEDIDMode` is imported by `/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay`.
- `libbd.dylib` does not import `IOAVServiceSetVirtualEDIDMode`; its `otool -L` output only links Swift/libSystem/libobjc.
- BetterDisplay also imports related IOKit calls:
  - `IOAVServiceCopyEDID`
  - `IOAVServiceCreateWithService`
  - `IOAVServiceReadI2C`
  - `IOAVServiceWriteI2C`
- BetterDisplay links:
  - `IOMobileFramebuffer.framework`
  - `DisplayServices.framework`
  - `SkyLight.framework`
  - `CoreDisplay.framework`

## Static call sites

`otool -tvV` showed two direct arm64 call sites to the symbol stub:

- `0x10006d83c -> _IOAVServiceSetVirtualEDIDMode`
  - Nearby setup: `x0 = IOAV service object`, `x1 = 0`, `x2 = 0`.
  - This looks like a disable/reset/factory path.
- `0x10056da00 -> _IOAVServiceSetVirtualEDIDMode`
  - Nearby setup: `x0 = IOAV service object`, `x1 = stack pointer containing 1`, `x2 = NSData bridged from Swift Foundation.Data`.
  - This looks like the custom/virtual EDID apply path.

## Related strings

Relevant strings are present in the main BetterDisplay binary:

- `Apply Custom EDID`
- `Apply configured custom EDID for`
- `autoApplyEDIDOverride`
- `displayEDIDOverrideFormat`
- `Reinitialize display connection and reload custom configuration. Works with natively connected displays with EDID.`
- `Reinitialize Display`
- `customEDID`
- `applyCustomEDID`
- `applyFactoryEDID`
- `arm64IOAVService`
- `IODisplayEDIDOriginal`
- `I2C EDID write chunk`
- `EDIDOverrideData`

So the symbol is strongly related to BetterDisplay's custom EDID / virtual EDID machinery, not to `libbd.dylib`.

## LLDB breakpoint

- Attached to BetterDisplay PID `36184`.
- Breakpoint set only on `IOAVServiceSetVirtualEDIDMode`.
- Breakpoint resolved at `IOKit::IOAVServiceSetVirtualEDIDMode`.
- Auto-continue command included timestamp, thread info, backtrace, registers `x0...x7`, and memory dump at `x1`.

## Mode pool before

- User confirmed HiDPI was already off.
- Samsung displayID: `3`.
- Active mode: `2560x1440 logical / 2560x1440 backing / 100Hz / ioMode 56 / HiDPI false`.
- Default mode count: `58`.
- `duplicateLowResolutionModes=true` count: `106`.
- HiDPI count: `48`.
- Perfect QHD count: `0`.

## Mode pool after

- After user enabled HiDPI in BetterDisplay:
- Active mode: `2560x1440 logical / 5120x2880 backing / 100Hz / ioMode 74 / HiDPI true`.
- Default mode count: `58`.
- `duplicateLowResolutionModes=true` count: `107`.
- HiDPI count: `49`.
- Perfect QHD count: `1`.

## Breakpoint hit?

- `IOAVServiceSetVirtualEDIDMode` breakpoint hit count: `0`.
- The 106 -> 107 mode pool transition happened without an observed `IOAVServiceSetVirtualEDIDMode` call in BetterDisplay during this activation window.

## Hit timing vs mode pool change

- No hit occurred, so there is no timestamp/call stack/register dump to correlate with the 106 -> 107 transition.

## AmbientSync candidate?

- Static evidence: BetterDisplay contains a real custom/virtual EDID path using `IOAVServiceSetVirtualEDIDMode`.
- Live evidence: this BetterDisplay HiDPI activation flow did not call `IOAVServiceSetVirtualEDIDMode`.
- Conclusion: `IOAVServiceSetVirtualEDIDMode` is not a confirmed AmbientSync activation candidate from this trace.

## Final conclusion

Bu BetterDisplay activation akışında `IOAVServiceSetVirtualEDIDMode` gözlenmedi.

Net transferable call bulunmadı. The next useful evidence is not another live AmbientSync experiment, but deeper BetterDisplay reverse-analysis around the pre-`SLSConfigureDisplayMode` reinitialize/flexible-scaling path that creates the extra mode without hitting this exported IOAV symbol.
