# Changelog

## 0.2.3 (unreleased) - 2026-10-02

- Added a runnable detection-box transfer example showing how a homography can
  produce target-image `xywh` bounds for MoonDetEval.
- Documented the independent October detector-evaluation bridge without adding
  a dependency from the August geometry library to the evaluator.
- Kept strict CI validation on the current compiler while temporarily excluding
  existing warning 25 and 79 migrations from the warning gate.
- Normalized source formatting with the current MoonBit formatter so the CI
  format gate remains reproducible across the existing packages.

## 0.2.2 - 2026-08-24

- Added reusable point-cloud, image-window, camera-ray, track-quality, model-
  selection, and diagnostic export APIs across the four public packages.
- Added boundary tests for empty inputs, singleton inputs, invalid resolutions,
  duplicate observations, deterministic sampling, and report serialization.
- Updated the CI workflow to require Moonc 0.10.9 or newer and verified all
  supported targets with the current stable toolchain.

## 0.2.1 - 2026-08-17

- Expanded the reusable geometry, camera, multi-view, matching, stereo,
  calibration, residual, and robust-estimation APIs for the August Hackathon.
- Added cross-target tests, reproducible benchmark notes, coverage checks,
  native smoke checks, and an explicit Moonc version floor in CI.

## 0.2.0 - 2026-08-09

- Added normalized multi-point homography estimation using a fixed-size DLT
  solve with point-set normalization and denormalization.
- Added a linear eight-point fundamental matrix estimator and connected the
  robust RANSAC path to deterministic eight-point samples.
- Added triangulation cheirality and ray-angle quality checks.
- Expanded algorithm, numerical-convention, README, and project documentation
  with the new scope and known rank-constraint limitation.

## 0.1.1 - 2026-07-27

- Replaced the shortened Apache-2.0 notice with the complete license text.
- Added explicit OSC2026 authorship and provenance documentation.
- Clarified that the current Mooncakes package namespace is
  `python123-ops/moon-cv-geometry`; the earlier `cxh04` publication is not part
  of this maintained package.

## 0.1.0 - 2026-07-22

- Initial OSC2026 release.
- Added fixed-size geometry primitives, camera projection/distortion helpers,
  homography and epipolar utilities, deterministic RANSAC, examples, and docs.
