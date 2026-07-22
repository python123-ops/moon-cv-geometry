///|
test "vector operations and matrix inverse" {
  let a = Vec3::new(x=1.0, y=0.0, z=0.0)
  let b = Vec3::new(x=0.0, y=1.0, z=0.0)
  let c = a.cross(b)
  assert_true(almost_equal(c.z, 1.0))
  assert_true(almost_equal(Vec2::new(x=3.0, y=4.0).norm(), 5.0))
  let m = mat3_from_rows((2.0, 0.0, 0.0), (0.0, 4.0, 0.0), (0.0, 0.0, 8.0))
  let inv = m.inverse()
  let p = inv.mul_vec3(Vec3::new(x=2.0, y=4.0, z=8.0))
  assert_true(almost_equal(p.x, 1.0))
  assert_true(almost_equal(p.y, 1.0))
  assert_true(almost_equal(p.z, 1.0))
}

///|
test "singular matrix raises an explicit error" {
  let m = mat3_from_rows((1.0, 2.0, 3.0), (2.0, 4.0, 6.0), (0.0, 0.0, 1.0))
  try m.inverse() catch {
    GeometryError::DegenerateInput(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected singular matrix error")
  }
}

///|
test "homogeneous point conversion checks scale" {
  let p = Point2::new(x=3.0, y=-2.0)
  let h = p.to_homogeneous()
  assert_true(almost_equal(h.z, 1.0))
  let recovered = point2_from_homogeneous(Vec3::new(x=6.0, y=-4.0, z=2.0))
  assert_true(almost_equal(recovered.x, p.x))
  assert_true(almost_equal(recovered.y, p.y))
}

///|
test "closest point between crossing rays" {
  let a = Ray3::new(
    origin=Point3::new(x=0.0, y=0.0, z=0.0),
    direction=Vec3::new(x=0.0, y=0.0, z=1.0),
  )
  let b = Ray3::new(
    origin=Point3::new(x=1.0, y=0.0, z=0.0),
    direction=Vec3::new(x=-1.0, y=0.0, z=2.0),
  )
  let p = a.closest_midpoint(b)
  assert_true(almost_equal(p.x, 0.0))
  assert_true(almost_equal(p.y, 0.0))
  assert_true(almost_equal(p.z, 2.0))
  assert_true(a.closest_separation(b) < 0.000000001)
}

///|
test "Rect2 bounds and set operations" {
  let points = [
    Point2::new(x=1.0, y=2.0),
    Point2::new(x=-1.0, y=5.0),
    Point2::new(x=4.0, y=0.0),
  ]
  let bounds = rect2_from_points(points)
  assert_true(almost_equal(bounds.width(), 5.0))
  assert_true(almost_equal(bounds.height(), 5.0))
  assert_true(bounds.contains(Point2::new(x=0.0, y=3.0)))
  let padded = bounds.expand(1.0)
  assert_true(almost_equal(padded.area(), 49.0))
  let other = Rect2::from_center_size(
    center=Point2::new(x=2.0, y=2.0),
    width=2.0,
    height=2.0,
  )
  let merged = bounds.union(other)
  assert_true(merged.contains(Point2::new(x=3.0, y=3.0)))
  guard bounds.intersection(other) is Some(hit) else {
    fail("expected intersection")
  }
  assert_true(hit.contains(Point2::new(x=1.0, y=1.0)))
}
