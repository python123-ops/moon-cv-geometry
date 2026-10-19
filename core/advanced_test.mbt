///|
test "quaternion identity and axis rotation" {
  let q = @core.quaternion_from_axis_angle(
    @core.Vec3::new(x=0.0, y=0.0, z=1.0),
    1.5707963267948966,
  )
  let v = q.rotate(@core.Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(@core.almost_equal(v.x, 0.0))
  assert_true(@core.almost_equal(v.y, 1.0))
  assert_true(@core.Quaternion::identity().norm() == 1.0)
}

///|
test "rigid transform compose and inverse" {
  let a = @core.RigidTransform::new(
    rotation=@core.identity3(),
    translation=@core.Vec3::new(x=1.0, y=2.0, z=3.0),
  )
  let b = a.inverse()
  let p = @core.Point3::new(x=4.0, y=5.0, z=6.0)
  let recovered = b.apply(a.apply(p))
  assert_true(@core.distance3(recovered, p) < 0.000001)
}

///|
test "statistics include even and odd medians" {
  assert_true(@core.almost_equal(@core.median([3.0, 1.0, 2.0]), 2.0))
  assert_true(@core.almost_equal(@core.median([4.0, 1.0, 3.0, 2.0]), 2.5))
  assert_true(
    @core.almost_equal(@core.percentile([0.0, 10.0], fraction=0.25), 2.5),
  )
  assert_true(@core.robust_scale([1.0, 1.0, 1.0]) == 0.0)
}

///|
test "line and plane projections" {
  let line = @core.Line2::from_points(
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
  )
  assert_true(
    @core.almost_equal(
      @core.abs(line.signed_distance(@core.Point2::new(x=0.0, y=2.0))),
      2.0,
    ),
  )
  let plane = @core.Plane3::from_points(
    @core.Point3::new(x=0.0, y=0.0, z=0.0),
    @core.Point3::new(x=1.0, y=0.0, z=0.0),
    @core.Point3::new(x=0.0, y=1.0, z=0.0),
  )
  assert_true(
    @core.almost_equal(
      plane.signed_distance(@core.Point3::new(x=0.0, y=0.0, z=2.0)),
      2.0,
    ),
  )
}

///|
test "polygon centroid and barycentric boundary" {
  let square = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=2.0, y=0.0),
    @core.Point2::new(x=2.0, y=2.0),
    @core.Point2::new(x=0.0, y=2.0),
  ]
  let center = @core.polygon_centroid(square)
  assert_true(@core.almost_equal(center.x, 1.0))
  assert_true(@core.almost_equal(@core.polygon_signed_area(square), 4.0))
  let weights = @core.barycentric_2d(
    square[0],
    square[1],
    square[3],
    @core.Point2::new(x=0.0, y=0.0),
  )
  assert_true(@core.barycentric_contains(weights))
}

///|
test "solver rejects singular systems" {
  try
    @core.solve_2x2(a00=1.0, a01=2.0, a10=2.0, a11=4.0, b0=1.0, b1=2.0)
  catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected error")
  }
  assert_true(
    @core.almost_equal(
      @core.solve_2x2(a00=2.0, a01=0.0, a10=0.0, a11=4.0, b0=2.0, b1=8.0).y,
      2.0,
    ),
  )
}

///|
test "array utilities preserve dimensions" {
  let values = @core.scale_array([1.0, 2.0, 3.0], 2.0)
  assert_true(@core.all_close(values, [2.0, 4.0, 6.0]))
  assert_true(
    @core.almost_equal(@core.weighted_mean([1.0, 3.0], [1.0, 3.0]), 2.5),
  )
  assert_true(@core.relative_error(100.001, 100.0) < 0.0001)
}
