///|
fn main raise {
  let left = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=0.2, y=0.4),
    @core.Point2::new(x=-0.1, y=0.7),
    @core.Point2::new(x=0.7, y=0.1),
    @core.Point2::new(x=-0.6, y=-0.4),
    @core.Point2::new(x=0.2, y=0.8),
    @core.Point2::new(x=-0.8, y=0.3),
    @core.Point2::new(x=0.9, y=-0.7),
  ]
  let right = [
    @core.Point2::new(x=-0.2, y=0.0),
    @core.Point2::new(x=-0.1, y=0.4),
    @core.Point2::new(x=-0.4, y=0.7),
    @core.Point2::new(x=-0.1, y=0.15),
    @core.Point2::new(x=0.5, y=-0.2333333333),
    @core.Point2::new(x=-0.3, y=0.1833333333),
    @core.Point2::new(x=0.6, y=-0.2666666667),
    @core.Point2::new(x=-0.2, y=0.2166666667),
  ]
  let result = @ransac.estimate_fundamental_ransac(
    left,
    right,
    config=@ransac.RansacConfig::new(threshold=0.0001, min_inliers=8),
  )
  println("inliers: \{result.inlier_count}")
}
