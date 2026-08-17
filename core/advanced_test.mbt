///|
test "quaternion identity and axis rotation" {
  let q = quaternion_from_axis_angle(
    Vec3::new(x=0.0, y=0.0, z=1.0),
    1.5707963267948966,
  )
  let v = q.rotate(Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(almost_equal(v.x, 0.0))
  assert_true(almost_equal(v.y, 1.0))
  assert_true(Quaternion::identity().norm() == 1.0)
}

///|
test "rigid transform compose and inverse" {
  let a = RigidTransform::new(
    rotation=identity3(),
    translation=Vec3::new(x=1.0, y=2.0, z=3.0),
  )
  let b = a.inverse()
  let p = Point3::new(x=4.0, y=5.0, z=6.0)
  let recovered = b.apply(a.apply(p))
  assert_true(distance3(recovered, p) < 0.000001)
}

///|
test "statistics include even and odd medians" {
  assert_true(almost_equal(median([3.0, 1.0, 2.0]), 2.0))
  assert_true(almost_equal(median([4.0, 1.0, 3.0, 2.0]), 2.5))
  assert_true(almost_equal(percentile([0.0, 10.0], fraction=0.25), 2.5))
  assert_true(robust_scale([1.0, 1.0, 1.0]) == 0.0)
}

///|
test "line and plane projections" {
  let line = Line2::from_points(
    Point2::new(x=0.0, y=0.0),
    Point2::new(x=1.0, y=0.0),
  )
  assert_true(
    almost_equal(abs(line.signed_distance(Point2::new(x=0.0, y=2.0))), 2.0),
  )
  let plane = Plane3::from_points(
    Point3::new(x=0.0, y=0.0, z=0.0),
    Point3::new(x=1.0, y=0.0, z=0.0),
    Point3::new(x=0.0, y=1.0, z=0.0),
  )
  assert_true(
    almost_equal(plane.signed_distance(Point3::new(x=0.0, y=0.0, z=2.0)), 2.0),
  )
}

///|
test "polygon centroid and barycentric boundary" {
  let square = [
    Point2::new(x=0.0, y=0.0),
    Point2::new(x=2.0, y=0.0),
    Point2::new(x=2.0, y=2.0),
    Point2::new(x=0.0, y=2.0),
  ]
  let center = polygon_centroid(square)
  assert_true(almost_equal(center.x, 1.0))
  assert_true(almost_equal(polygon_signed_area(square), 4.0))
  let weights = barycentric_2d(
    square[0],
    square[1],
    square[3],
    Point2::new(x=0.0, y=0.0),
  )
  assert_true(barycentric_contains(weights))
}

///|
test "solver rejects singular systems" {
  try solve_2x2(a00=1.0, a01=2.0, a10=2.0, a11=4.0, b0=1.0, b1=2.0) catch {
    GeometryError::DegenerateInput(_) => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected error")
  }
  assert_true(
    almost_equal(
      solve_2x2(a00=2.0, a01=0.0, a10=0.0, a11=4.0, b0=2.0, b1=8.0).y,
      2.0,
    ),
  )
}

///|
test "array utilities preserve dimensions" {
  let values = scale_array([1.0, 2.0, 3.0], 2.0)
  assert_true(all_close(values, [2.0, 4.0, 6.0]))
  assert_true(almost_equal(weighted_mean([1.0, 3.0], [1.0, 3.0]), 2.5))
  assert_true(relative_error(100.001, 100.0) < 0.0001)
}
