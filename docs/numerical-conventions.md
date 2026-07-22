# Numerical Conventions

`moon-cv-geometry` keeps its first release intentionally small and explicit.
The library is not a general-purpose linear algebra package; it exposes only the
fixed-size numeric tools needed by the public camera and multi-view APIs.

## Coordinates

- Pixel coordinates use the usual image convention: `x` grows to the right and
  `y` grows downward.
- Normalized camera coordinates use `z = 1` before distortion and projection.
- `CameraPose.world_to_camera` stores a `3x4` matrix that maps world points into
  the camera coordinate frame.
- Camera projection rejects points with non-positive or near-zero depth.

## Matrices

- `Mat3` is row-major in its field names: `m10` means row 1, column 0.
- Homogeneous 2D points are represented as `Vec3(x, y, w)`.
- `point2_from_homogeneous` rejects values with very small `w` to avoid silent
  division by an unstable scale.

## Distortion

- `Distortion` follows the Brown-Conrady radial and tangential model.
- Distortion and undistortion operate on normalized image-plane coordinates, not
  pixel coordinates.
- Iterative undistortion is deterministic; callers can choose the iteration
  count when they need a speed/accuracy tradeoff.

## Robust Estimation

- RANSAC sampling uses an explicit seed so tests, examples, and CI runs are
  reproducible.
- Scores are the inlier ratio for the tested correspondence set.
- Thresholds are residual thresholds in the estimator's native error metric:
  reprojection error for homography and epipolar residual for the fundamental
  matrix helper.
