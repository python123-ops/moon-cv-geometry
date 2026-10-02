# Examples

These runnable examples are intentionally small and deterministic:

- `project_point`: pinhole projection from camera coordinates to pixels.
- `undistort`: Brown-Conrady distortion and iterative undistortion.
- `homography`: normalized multi-point projective homography estimation.
- `fundamental_ransac`: deterministic eight-point epipolar inlier counting.
- `detection_bounds`: map a source-image rectangle through a homography and emit its target-image `xywh` envelope for detector evaluation.

Run from the repository root:

```bash
moon run examples/project_point
moon run examples/undistort
moon run examples/homography
moon run examples/fundamental_ransac
moon run examples/detection_bounds
```
