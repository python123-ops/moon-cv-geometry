# Changelog

## 0.2.1 - 2026-08-17

- Expanded the reusable geometry, camera, multi-view, matching, stereo,
  calibration, residual, and robust-estimation APIs for the August Hackathon
  acceptance build.
- Added 49 cross-target tests, reproducible benchmark notes, coverage checks,
  native smoke checks, and a stable-toolchain CI gate.

## 0.2.0 - 2026-08-09

- Added normalized multi-point homography estimation using a fixed-size DLT
  solve with point-set normalization and denormalization.
- Added a linear eight-point fundamental matrix estimator and connected the
  robust RANSAC path to deterministic eight-point samples.
- Added triangulation cheirality and ray-angle quality checks.
- Expanded algorithm, numerical-convention, README, and OSC2026 self-check
  documentation with the new scope and known rank-constraint limitation.

## 0.1.1 - 2026-07-27

- Replaced the shortened Apache-2.0 notice with the complete license text.
- Added explicit OSC2026 authorship and provenance documentation.
- Clarified that the current Mooncakes submission namespace is
  `python123-ops/moon-cv-geometry` and that the earlier `cxh04` namespace was a
  release-preparation mistake, not the submitted package identity.

## 0.1.0 - 2026-07-22

- Initial OSC2026 release.
- Added fixed-size geometry primitives, camera projection/distortion helpers,
  homography and epipolar utilities, deterministic RANSAC, examples, and docs.
