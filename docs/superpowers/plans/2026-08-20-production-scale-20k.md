# Production Source Scale 20k Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the MoonBit computer-vision geometry library from 8,900 non-test production lines to approximately 20,000 non-test production lines while adding practical APIs, boundary tests, benchmark evidence, and preserving all supported backends.

**Architecture:** Extend the existing `core`, `camera`, `multiview`, and `ransac` packages with focused files. New APIs will reuse existing `Point2`, `Point3`, `Mat3`, `CameraPose`, `CameraIntrinsics`, track, and consensus types instead of introducing parallel abstractions. Each feature batch follows RED → GREEN → REFACTOR and is validated across wasm, wasm-gc, js, and native.

**Tech Stack:** MoonBit stable toolchain, `moon check`, `moon test`, coverage, native examples, generated `.mbti` interfaces, and the repository CI workflow.

---

### Task 1: Core numerical and geometry production layer

**Files:**
- Create: `core/robust_statistics_2.mbt`
- Create: `core/linear_algebra_batches.mbt`
- Create: `core/geometry_quality.mbt`
- Test: `core/production_scale_test.mbt`

- [ ] **Step 1: Write failing tests** for weighted quantiles, robust scale, batch matrix-vector operations, degeneracy classification, and empty/mismatched inputs.
- [ ] **Step 2: Run `moon test core/production_scale_test.mbt --target wasm`** and verify failures are missing-symbol failures.
- [ ] **Step 3: Implement package-local APIs** with checked `GeometryError` handling and no allocation-heavy shortcuts where an array view is sufficient.
- [ ] **Step 4: Run the focused core tests**, then run `moon check --target all --deny-warn`.
- [ ] **Step 5: Refactor only after green** and keep generated public interfaces intentional.

### Task 2: Camera production layer

**Files:**
- Create: `camera/calibration_pipeline.mbt`
- Create: `camera/image_metrics.mbt`
- Create: `camera/pose_interpolation_2.mbt`
- Test: `camera/production_scale_test.mbt`

- [ ] **Step 1: Write failing tests** for calibration residual aggregation, valid-depth masks, pyramid consistency, pose interpolation endpoints, and invalid image sizes.
- [ ] **Step 2: Verify RED** with the focused camera test command.
- [ ] **Step 3: Implement production APIs** using existing camera intrinsics, distortion, pose, and ray types.
- [ ] **Step 4: Run camera tests on wasm and native**, then run all-target checking.
- [ ] **Step 5: Refactor duplicated projection and mask logic while preserving numerical tolerances.**

### Task 3: Multiview and robust-estimation production layer

**Files:**
- Create: `multiview/reconstruction_pipeline.mbt`
- Create: `multiview/track_quality_2.mbt`
- Create: `ransac/model_diagnostics_2.mbt`
- Create: `ransac/sampling_diagnostics.mbt`
- Test: `multiview/production_scale_test.mbt`
- Test: `ransac/production_scale_test.mbt`

- [ ] **Step 1: Write failing tests** for track filtering, view connectivity, residual blocks, deterministic sampling, adaptive thresholds, and consensus tie-breaking.
- [ ] **Step 2: Verify RED** and fix only test syntax failures before implementation.
- [ ] **Step 3: Implement production APIs** with deterministic behavior suitable for benchmark reproduction.
- [ ] **Step 4: Run all multiview and RANSAC tests** on every backend.
- [ ] **Step 5: Refactor shared scoring helpers and document complexity-sensitive paths.**

### Task 4: Verification, benchmark evidence, and release hygiene

**Files:**
- Modify: `docs/benchmark.md`
- Modify: `README.mbt.md`
- Modify: `CHANGELOG.md`
- Modify: `.github/workflows/ci.yml` only if a verified gap is found

- [ ] **Step 1: Run `moon fmt`, `moon check --target all --deny-warn`, and `moon test --target all --deny-warn --enable-coverage`.**
- [ ] **Step 2: Run native CLI examples and `moon package`.**
- [ ] **Step 3: Count `.mbt` production and test lines excluding `_build`, and record reproducible benchmark data.**
- [ ] **Step 4: Run `moon info` and inspect generated interface changes.**
- [ ] **Step 5: Run `git diff --check`, commit intentionally, and push only the requested remote.**
