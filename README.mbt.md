# moon-cv-geometry

moonbit视觉几何基石 is a MoonBit library for camera and multi-view geometry.
It focuses on the reusable geometry layer beneath calibration, AR, SLAM demos,
panorama stitching, and robot-localization experiments.

The project deliberately does not implement image loading, filters, feature
detectors, neural vision, GIS geometry, game rendering, or a general-purpose
linear algebra framework.

## Install

```bash
moon add python123-ops/moon-cv-geometry
```

## Minimal Example

```mbt check
///|
test "project a 3D camera point" {
  let k = @camera.CameraIntrinsics::new(fx=500.0, fy=500.0, cx=320.0, cy=240.0)
  let p = @core.Point3::new(x=1.0, y=2.0, z=4.0)
  let pixel = @camera.project_point(p, k)
  assert_true(@core.almost_equal(pixel.x, 445.0))
  assert_true(@core.almost_equal(pixel.y, 490.0))
}
```

## Packages

- `core`: fixed-size 2D/3D geometry, Mat3/Mat4, quaternions, rigid transforms, planes/triangles/AABB, interpolation, robust statistics, and numerical solvers.
- `camera`: pinhole intrinsics, Brown-Conrady distortion, pose tools, projection Jacobians, image pyramids, frustums, calibration reports, rolling shutter and stereo depth helpers.
- `multiview`: normalized DLT, affine estimation, epipolar/Sampson diagnostics, triangulation, cheirality, point matching, track residuals, reconstruction reports, and pose-quality constraints.
- `ransac`: deterministic RANSAC configuration and estimators for homography and eight-point fundamental matrices, with a small-data compatibility path for the stereo translation baseline.

## Examples

```bash
moon run examples/project_point
moon run examples/undistort
moon run examples/homography
moon run examples/fundamental_ransac
moon run examples/detection_bounds
```

See `examples/README.md` for the short purpose of each example.

## Detection evaluation interop

The August geometry library can map a detector's source-image rectangle into a
target image using a homography. `moon run examples/detection_bounds` prints the
axis-aligned envelope as continuous `xywh` coordinates. The October
[MoonDetEval](https://github.com/python123-ops/moondeteval) library can consume
that rectangle as a scored detection and calculate COCO-style bbox metrics.
Its [independent consumer example](https://github.com/python123-ops/moondeteval/tree/main/examples/consumer)
imports `python123-ops/moon-cv-geometry@0.2.2` and exercises the complete path:
source rectangle → homography → target box → AP50. A projective horizon crossing
the rectangle is rejected by that adapter; bounding four corners is only valid
for a bounded mapped region. This geometry module has no MoonDetEval runtime
dependency, so the two packages remain separately reusable.

## Ecosystem Position

Before implementation, related mooncakes.io packages were checked. The closest
neighbors are general linear algebra (`Luna-Flow/linear-algebra`, `xunyoyo/linalg`,
`AdUhTkJm/nummoon`), computational/GIS geometry (`CMoonBack/computational-geometry`,
`cn-xjr/moongeokit`), rendering or game geometry (`mizchi/geom`, `Luna-Flow/geometry3d`),
and image processing (`PingGuoMiaoMiao/MoonVision`). This library stays in the
camera and multi-view geometry layer to avoid duplicating those packages.

## Source And Authorship

The implementation is original MoonBit code for OSC2026 by Zhang Jingkai. The
API and algorithms use standard projective-geometry formulas commonly described
in computer-vision texts and documentation. No third-party source code is copied
into this repository.

GitHub and GitLink use different platform accounts, but each public repository
keeps a single real account as its contributor identity. GitHub history is under
`python123-ops`; GitLink history is under `python123`.

The package is maintained under the `python123-ops` namespace. The repository
metadata targets the next compatible release, `python123-ops/moon-cv-geometry@0.2.3`,
and keeps source, examples, and release metadata together.

## Roadmap

- `0.2.x`: normalized DLT over larger correspondence sets, eight-point fundamental matrix estimation, cheirality checks, triangulation angle quality, and stronger numerical conditioning.
- Next: rank-2 fundamental matrix enforcement, calibrated pose decomposition, PnP, and bundle-adjustment-friendly residual helpers.

## Validation and project scope

```bash
moon fmt --check
moon check --target all --deny-warn --warn-list '-25-79'
moon test --target all --deny-warn --warn-list '-25-79'
moon info
moon package
```

The source tree contains approximately 20,000 lines of MoonBit implementation
across the four reusable packages, plus boundary tests and runnable examples.
The suite is executed on wasm, wasm-gc, js, and native targets. Reproducible
timings and numerical thresholds are recorded in
[docs/benchmark.md](docs/benchmark.md).

The current MoonBit CLI exposes warning denial on `moon check` and `moon test`.
The warning list temporarily excludes 25 (implicit test-package imports) and
79 (derived trait method promotion) in this older codebase; all other warnings
remain fatal. Those two warnings require a separate repository-wide migration.
For formatting and interface generation, CI uses `moon fmt --check` and
`moon info` followed by a generated-interface diff check.
