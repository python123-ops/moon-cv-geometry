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
- Finite-coordinate predicates and filters reject both NaN and infinity. Checked
  homogeneous conversion, camera projection, and homography application reject
  non-finite mapped results, including floating-point overflow during division.
- Checked camera projection/bearing entry points require finite intrinsics and
  positive focal lengths. `focal_from_fov` requires a finite positive sensor
  extent and a finite angle strictly between zero and pi. Non-raising algebra
  helpers such as `pixel_to_normalized` remain unchecked transformations.

## Distortion

- `Distortion` follows the Brown-Conrady radial and tangential model.
- Distortion and undistortion operate on normalized image-plane coordinates, not
  pixel coordinates.
- Iterative undistortion is deterministic; callers can choose the iteration
  count when they need a speed/accuracy tradeoff.

## Robust Estimation

- RANSAC sampling uses an explicit seed so tests, examples, and CI runs are
  reproducible.
- Four-point samples contain four distinct indices. Invalid estimator configuration
  and non-finite input coordinates are errors; singular sampled models are skipped
  within the configured iteration budget. No eager full-data/prefix fallback
  solve is needed before robust sampling.
- Scores are the sum of inlier residuals; `RansacResult::inlier_ratio` exposes
  the corresponding ratio separately.
- Homography RANSAC thresholds are pixel/projective reprojection distances.
  Fundamental RANSAC thresholds use the square root of Sampson error, which
  has the same first-order units as an image residual.
- Multi-point homography estimation normalizes each point set to centroid zero
  and RMS distance `sqrt(2)`, solves the fixed eight-parameter system, and
  maps the result back to the original coordinates.
- The linear eight-point API fixes the bottom-right coefficient to one. It is
  useful for stable, testable small inputs, but does not perform the optional
  rank-two SVD projection.

## Confidence and iteration budgets

Confidence helpers use `-expm1(n * log1p(-p))` for `1 - (1 - p)^n` so tiny
positive sample probabilities remain informative. Iteration estimates find the
smallest sufficient count by bounded bisection, requiring at most 31 steps.
Sample probabilities use exponentiation rather than loops over sample size.
The confidence/count APIs described here reject NaN, infinity, and values outside
their stated ranges when they expose a throwing interface.

`required_iterations` and `adaptive_iteration_bound` retain their historical
1,000,000 cap. `schedule_required_iterations` caps at 2,147,483,647;
`adaptive_required_iterations` uses the caller's positive budget (at least one).
Returning the cap does not guarantee the requested confidence is reachable.
Non-throwing schedule helpers clamp ratios/confidences, map NaN to zero,
and retain the schedule confidence ceiling of 0.999999999. A zero target needs
one trial; an impossible positive target returns the cap. Non-positive sample
sizes retain their existing zero-size-sample success convention.
