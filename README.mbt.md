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
```

See `examples/README.md` for the short purpose of each example.

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

The current Mooncakes release is `python123-ops/moon-cv-geometry@0.2.1`. An earlier
mistaken publish under `cxh04/moon-cv-geometry@0.1.0` is not the competition
submission namespace and has been superseded by the current package. See
`docs/authorship-and-provenance.md` for the audit trail.

## Roadmap

- `0.2.x`: normalized DLT over larger correspondence sets, eight-point fundamental matrix estimation, cheirality checks, triangulation angle quality, and stronger numerical conditioning.
- Next: rank-2 fundamental matrix enforcement, calibrated pose decomposition, PnP, and bundle-adjustment-friendly residual helpers.

## Validation and measured scale

```bash
moon fmt --check
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info
moon package
```

The acceptance snapshot contains 6,523 tracked `.mbt` source lines, including
5,764 implementation lines, 49 tests, and runnable examples. The suite is
executed on wasm, wasm-gc, js, and native targets. Reproducible local timings
and numerical thresholds are recorded in [docs/benchmark.md](docs/benchmark.md).

The current MoonBit CLI exposes warning denial on `moon check` and `moon test`.
For formatting and interface generation, CI uses `moon fmt --check` and
`moon info` followed by a generated-interface diff check.
