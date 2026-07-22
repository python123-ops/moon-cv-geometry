# RANSAC Notes

`RansacConfig` exposes:

- `iterations`: number of deterministic samples.
- `threshold`: maximum residual for an inlier.
- `min_inliers`: acceptance floor.
- `seed`: deterministic pseudo-random seed.

The current homography estimator solves a four-point projective homography. The
API is shaped so normalized DLT over larger correspondence sets can complement it
without changing user-facing result types.
