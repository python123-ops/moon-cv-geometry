# Examples

These runnable examples are intentionally small and deterministic:

- `project_point`: pinhole projection from camera coordinates to pixels.
- `undistort`: Brown-Conrady distortion and iterative undistortion.
- `homography`: normalized multi-point projective homography estimation.
- `fundamental_ransac`: deterministic eight-point epipolar inlier counting.

Run from the repository root:

```bash
moon run examples/project_point
moon run examples/undistort
moon run examples/homography
moon run examples/fundamental_ransac
```
