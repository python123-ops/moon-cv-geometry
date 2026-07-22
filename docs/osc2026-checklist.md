# OSC2026 Self-check

- Public repository: planned as `https://github.com/python123-ops/moon-cv-geometry`
  and a same-name GitLink mirror.
- Default branch: `main` after release preparation.
- License: Apache-2.0.
- Contributor identity: single author, `python123-ops <python123-ops@users.noreply.github.com>`.
- Mooncakes module: `cxh04/moon-cv-geometry@0.1.0`.
- MoonBit source scale: about 1.1k `.mbt` lines in the first acceptance build.
- Tests: fixed-size math, camera projection/distortion, projective homography,
  epipolar residuals, and deterministic RANSAC.
- Documentation: README, algorithm notes, numerical conventions, RANSAC notes,
  proposal draft, changelog, contribution note, and source notice.
- Source statement: original MoonBit implementation; no copied third-party code.

The source scale is intentionally below the 4-10k reference range for the first
cut so the project remains reviewable and focused. The roadmap expands toward
normalized DLT, eight-point fundamental matrix estimation, triangulation, PnP,
and bundle-adjustment residual helpers.
