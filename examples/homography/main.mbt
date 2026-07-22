///|
fn main raise {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
  ]
  let dst = [
    @core.Point2::new(x=10.0, y=20.0),
    @core.Point2::new(x=12.0, y=20.0),
    @core.Point2::new(x=10.0, y=23.0),
    @core.Point2::new(x=12.0, y=23.0),
  ]
  let h = @multiview.estimate_homography_from_four(src, dst)
  let p = h.apply(@core.Point2::new(x=0.25, y=0.5))
  println("mapped point: \{p.x}, \{p.y}")
}
