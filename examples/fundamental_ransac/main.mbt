///|
fn main raise {
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
  let result = @ransac.estimate_fundamental_ransac(
    left,
    right,
    config=@ransac.RansacConfig::new(threshold=0.000001, min_inliers=3),
  )
  println("inliers: \{result.inlier_count}")
}
