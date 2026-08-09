# Algorithms

`moon-cv-geometry` implements the small, reusable layer of vision geometry:

- Fixed-size 2D/3D points, vectors, `Ray3`, `Rect2`, `Mat3`, and `Mat34`.
- Bearing-ray closest midpoint triangulation for simple stereo geometry checks.
- Pinhole camera projection and normalized image-plane conversion.
- Image size helpers, centered camera construction, intrinsic matrix export,
  and intrinsic scaling for resized frames or image pyramids.
- Brown-Conrady radial and tangential distortion.
- Homography application, four-point estimation, and normalized multi-point DLT.
- Epipolar residual, line distance, Sampson error, a translation fundamental
  matrix helper, and the linear eight-point estimator.
- Bearing-ray cheirality and triangulation-angle checks for rejecting points
  behind either camera or configurations with weak stereo baselines.
- Deterministic RANSAC wrappers for repeatable examples and tests, including
  eight-point fundamental samples when enough matches are available.

The current release favors clear APIs and verifiable behavior. The fixed-size
implementation intentionally keeps the eight-point estimator linear and
does not pretend to perform rank-2 SVD enforcement; callers that need a final
rank-constrained model can pass its result to a dedicated numerical package.
PnP and bundle-adjustment residual blocks remain later extensions.
