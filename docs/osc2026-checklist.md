# OSC2026 Self-check

- Public repositories:
  `https://github.com/python123-ops/moon-cv-geometry` and
  `https://gitlink.org.cn/python123/moon-cv-geometry`.
- Default branch: `main` after release preparation.
- License: Apache-2.0.
- Contributor identity:
  GitHub history uses `python123-ops <python123-ops@users.noreply.github.com>`;
  GitLink history uses `python123 <15564209090@163.com>`.
- Mooncakes module: `python123-ops/moon-cv-geometry@0.2.0` (after release).
- MoonBit source scale: about 2.0k `.mbt` lines in the refreshed acceptance build,
  plus checked interfaces and runnable examples.
- Tests: fixed-size math, camera projection/distortion, four-point and normalized
  multi-point homography, eight-point epipolar estimation, ray triangulation,
  cheirality, rectangle bounds, and deterministic RANSAC.
- Documentation: README, algorithm notes, numerical conventions, RANSAC notes,
  proposal draft, changelog, contribution note, and source notice.
- Source statement: original MoonBit implementation by Zhang Jingkai; no copied
  third-party code. The `cxh04/moon-cv-geometry@0.1.0` Mooncakes entry was an
  earlier mistaken namespace and is not the submitted package.

The source scale remains intentionally focused: the current increment is spent
on reusable estimators and evidence-driven tests rather than unrelated image
processing. The next roadmap step is rank-constrained epipolar estimation,
calibrated pose decomposition, PnP, and bundle-adjustment residual helpers.
