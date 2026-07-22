# Algorithms

`moon-cv-geometry` implements the small, reusable layer of vision geometry:

- Fixed-size 2D/3D points, vectors, `Mat3`, and `Mat34`.
- Pinhole camera projection and normalized image-plane conversion.
- Brown-Conrady radial and tangential distortion.
- Homography application and a four-point projective estimator.
- Epipolar residual, line distance, Sampson error, and a skew-symmetric translation fundamental matrix helper.
- Deterministic RANSAC wrappers for repeatable examples and tests.

The first release favors clear APIs and verifiable behavior. Normalized DLT over
larger correspondence sets, eight-point estimation, triangulation, PnP, and
bundle-adjustment residual blocks are planned after the OSC2026 acceptance
baseline.
