///|
test "finite predicates and filters reject infinities as well as NaN" {
  let infinity = 1.0e308 * 1.0e308
  let nan = infinity - infinity
  for invalid in [infinity, -infinity, nan] {
    assert_false(@core.finite_point2(@core.Point2::new(x=invalid, y=0.0)))
    assert_false(
      @core.finite_point3(@core.Point3::new(x=0.0, y=invalid, z=0.0)),
    )
    assert_false(
      @core.coordinate_finite_point2(@core.Point2::new(x=0.0, y=invalid)),
    )
    assert_false(
      @core.coordinate_finite_point3(@core.Point3::new(x=0.0, y=0.0, z=invalid)),
    )
    assert_false(@core.finite_vec2(@core.Vec2::new(x=invalid, y=0.0)))
    assert_false(@core.finite_vec3(@core.Vec3::new(x=0.0, y=0.0, z=invalid)))
    assert_false(
      @core.points2_are_finite([@core.Point2::new(x=invalid, y=0.0)]),
    )
    assert_false(
      @core.points3_are_finite([@core.Point3::new(x=invalid, y=0.0, z=0.0)]),
    )
  }
  assert_eq(@core.finite_scalars([infinity, 1.0, nan, -infinity, -2.0]), [
    1.0, -2.0,
  ])
  let valid = @core.Point3::new(x=1.0e300, y=-1.0e300, z=0.0)
  assert_eq(
    @core.finite_points3([valid, @core.Point3::new(x=infinity, y=0.0, z=0.0)]),
    [valid],
  )
  assert_true(@core.points2_are_finite([]))
  assert_true(@core.finite_point3(valid))
}

///|
test "homogeneous conversion rejects non-finite inputs and overflow" {
  let infinity = 1.0e308 * 1.0e308
  for
    value in [
      @core.Vec3::new(x=infinity, y=0.0, z=1.0),
      @core.Vec3::new(x=1.0, y=0.0, z=infinity),
      @core.Vec3::new(x=1.0e308, y=0.0, z=1.0e-11),
    ] {
    try @core.point2_from_homogeneous(value) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid homogeneous point")
    }
  }
}
