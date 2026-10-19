# RANSAC Notes

`RansacConfig` exposes:

- `iterations`: number of deterministic samples.
- `threshold`: maximum residual for an inlier.
- `min_inliers`: acceptance floor.
- `seed`: deterministic pseudo-random seed.

The current homography estimator solves a four-point projective homography. The
API is shaped so normalized DLT over larger correspondence sets can complement it
without changing user-facing result types.

The estimator validates the configuration and finite paired coordinates before
searching. Each four-point sample uses distinct indices, and degenerate sampled
models are skipped. It succeeds only if a sampled model meets `min_inliers`;
a singular initial prefix cannot abort an otherwise valid search. The eight-point
fundamental path likewise avoids an eager full-data fallback solve while retaining
its existing deterministic consecutive-window sampling and the compatibility
path for fewer than eight matches.

The public confidence/count helpers share stable probability arithmetic and
bounded iteration-count calculation. See `numerical-conventions.md` for exact
caps and input policies. Changing the four-point sampling fix can change the
chosen model for a historical seed, while repeated runs with the same updated
implementation remain deterministic.
