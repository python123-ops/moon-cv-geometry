///|
/// Map the four corners of a source-image rectangle and enclose the result in
/// an axis-aligned target-image rectangle ready for bbox evaluation.
fn mapped_detection_bounds(
  rect : @core.Rect2,
  homography : @multiview.Homography,
) -> @core.Rect2 raise @core.GeometryError {
  let corners = [
    rect.min,
    @core.Point2::new(x=rect.max.x, y=rect.min.y),
    rect.max,
    @core.Point2::new(x=rect.min.x, y=rect.max.y),
  ]
  let mapped : Array[@core.Point2] = []
  for corner in corners {
    mapped.push(homography.apply(corner))
  }
  @core.rect2_from_points(mapped)
}

///|
fn main raise {
  let source = @core.Rect2::new(
    min=@core.Point2::new(x=0.0, y=0.0),
    max=@core.Point2::new(x=10.0, y=10.0),
  )
  let source_corners = [
    source.min,
    @core.Point2::new(x=10.0, y=0.0),
    source.max,
    @core.Point2::new(x=0.0, y=10.0),
  ]
  let target_corners = [
    @core.Point2::new(x=20.0, y=30.0),
    @core.Point2::new(x=40.0, y=30.0),
    @core.Point2::new(x=40.0, y=50.0),
    @core.Point2::new(x=20.0, y=50.0),
  ]
  let homography = @multiview.estimate_homography_from_four(
    source_corners, target_corners,
  )
  let bounds = mapped_detection_bounds(source, homography)
  println(
    "target bbox xywh: \{bounds.min.x}, \{bounds.min.y}, \{bounds.width()}, \{bounds.height()}",
  )
}

///|
test "mapped detection bounds enclose four transformed corners" {
  let source = @core.Rect2::new(
    min=@core.Point2::new(x=0.0, y=0.0),
    max=@core.Point2::new(x=10.0, y=10.0),
  )
  let from = [
    source.min,
    @core.Point2::new(x=10.0, y=0.0),
    source.max,
    @core.Point2::new(x=0.0, y=10.0),
  ]
  let to = [
    @core.Point2::new(x=20.0, y=30.0),
    @core.Point2::new(x=40.0, y=30.0),
    @core.Point2::new(x=40.0, y=50.0),
    @core.Point2::new(x=20.0, y=50.0),
  ]
  let homography = @multiview.estimate_homography_from_four(from, to)
  let bounds = mapped_detection_bounds(source, homography)
  assert_true((bounds.min.x - 20.0).abs() < 0.000000001)
  assert_true((bounds.min.y - 30.0).abs() < 0.000000001)
  assert_true((bounds.width() - 20.0).abs() < 0.000000001)
  assert_true((bounds.height() - 20.0).abs() < 0.000000001)
}
