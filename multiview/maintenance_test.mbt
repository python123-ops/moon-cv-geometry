///|
test "homography rejects non-finite mapped points and division overflow" {
  let infinity = 1.0e308 * 1.0e308
  for
    point in [
      @core.Point2::new(x=infinity, y=0.0),
      @core.Point2::new(x=infinity - infinity, y=0.0),
    ] {
    try
      @multiview.Homography::new(matrix=@core.identity3()).apply(point)
    catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected non-finite homography input error")
    }
  }
  let overflow = @multiview.Homography::new(
    matrix=@core.mat3_from_rows(
      (1.0e308, 0.0, 0.0),
      (0.0, 1.0, 0.0),
      (0.0, 0.0, 1.0e-11),
    ),
  )
  try overflow.apply(@core.Point2::new(x=1.0, y=0.0)) catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected division overflow")
  }
}
