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
  assert_true(result.inlier_ratio() >= 0.8)
  assert_true(result.inliers.length() == 5)
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
  assert_true(result.inliers.is_inlier(1))
}

///|
test "fundamental RANSAC uses eight point samples" {
  let left = [
    @core.Point2::new(x=0.1, y=0.2),
    @core.Point2::new(x=0.4, y=-0.3),
    @core.Point2::new(x=-0.2, y=0.5),
    @core.Point2::new(x=0.7, y=0.1),
    @core.Point2::new(x=-0.6, y=-0.4),
    @core.Point2::new(x=0.2, y=0.8),
    @core.Point2::new(x=-0.8, y=0.3),
    @core.Point2::new(x=0.9, y=-0.7),
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=0.3, y=0.6),
  ]
  let right = [
    @core.Point2::new(x=0.3, y=-0.1666666667),
    @core.Point2::new(x=-0.4, y=0.0),
    @core.Point2::new(x=0.2, y=-0.2083333333),
    @core.Point2::new(x=-0.1, y=0.15),
    @core.Point2::new(x=0.5, y=-0.2333333333),
    @core.Point2::new(x=-0.3, y=0.1833333333),
    @core.Point2::new(x=0.6, y=-0.2666666667),
    @core.Point2::new(x=-0.2, y=0.2166666667),
    @core.Point2::new(x=99.0, y=-80.0),
    @core.Point2::new(x=-70.0, y=90.0),
  ]
  let result = estimate_fundamental_ransac(
    left,
    right,
    config=RansacConfig::new(
      iterations=64,
      threshold=0.0001,
      min_inliers=8,
      seed=11U,
    ),
  )
  assert_true(result.inlier_count >= 8)
  assert_true(result.inlier_ratio() >= 0.8)
}
