///|
test "homography RANSAC ignores one clear outlier" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=2.0, y=1.0),
  ]
  let dst = [
    @core.Point2::new(x=10.0, y=20.0),
    @core.Point2::new(x=12.0, y=20.0),
    @core.Point2::new(x=10.0, y=23.0),
    @core.Point2::new(x=12.0, y=23.0),
    @core.Point2::new(x=-100.0, y=-100.0),
  ]
  let result = estimate_homography_ransac(
    src,
    dst,
    config=RansacConfig::new(
      iterations=64,
      threshold=0.001,
      min_inliers=4,
      seed=7U,
    ),
  )
  assert_true(result.inlier_count >= 4)
}

///|
test "fundamental RANSAC scores stereo-like matches" {
  let left = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=0.2, y=0.4),
    @core.Point2::new(x=-0.1, y=0.7),
  ]
  let right = [
    @core.Point2::new(x=-0.2, y=0.0),
    @core.Point2::new(x=-0.1, y=0.4),
    @core.Point2::new(x=-0.4, y=0.7),
  ]
  let result = estimate_fundamental_ransac(
    left,
    right,
    config=RansacConfig::new(threshold=0.000001, min_inliers=3),
  )
  assert_eq(result.inlier_count, 3)
}
