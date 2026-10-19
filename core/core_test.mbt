///|
test "vector operations and matrix inverse" {
  let a = @core.Vec3::new(x=1.0, y=0.0, z=0.0)
  let b = @core.Vec3::new(x=0.0, y=1.0, z=0.0)
  let c = a.cross(b)
  assert_true(@core.almost_equal(c.z, 1.0))
  assert_true(@core.almost_equal(@core.Vec2::new(x=3.0, y=4.0).norm(), 5.0))
  let m = @core.mat3_from_rows(
    (2.0, 0.0, 0.0),
    (0.0, 4.0, 0.0),
    (0.0, 0.0, 8.0),
  )
  let inv = m.inverse()
  let p = inv.mul_vec3(@core.Vec3::new(x=2.0, y=4.0, z=8.0))
  assert_true(@core.almost_equal(p.x, 1.0))
  assert_true(@core.almost_equal(p.y, 1.0))
  assert_true(@core.almost_equal(p.z, 1.0))
}

///|
test "singular matrix raises an explicit error" {
  let m = @core.mat3_from_rows(
    (1.0, 2.0, 3.0),
    (2.0, 4.0, 6.0),
    (0.0, 0.0, 1.0),
  )
  try m.inverse() catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected singular matrix error")
  }
}

///|
test "homogeneous point conversion checks scale" {
  let p = @core.Point2::new(x=3.0, y=-2.0)
  let h = p.to_homogeneous()
  assert_true(@core.almost_equal(h.z, 1.0))
  let recovered = @core.point2_from_homogeneous(
    @core.Vec3::new(x=6.0, y=-4.0, z=2.0),
  )
  assert_true(@core.almost_equal(recovered.x, p.x))
  assert_true(@core.almost_equal(recovered.y, p.y))
}

///|
test "closest point between crossing rays" {
  let a = @core.Ray3::new(
    origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
    direction=@core.Vec3::new(x=0.0, y=0.0, z=1.0),
  )
  let b = @core.Ray3::new(
    origin=@core.Point3::new(x=1.0, y=0.0, z=0.0),
    direction=@core.Vec3::new(x=-1.0, y=0.0, z=2.0),
  )
  let p = a.closest_midpoint(b)
  assert_true(@core.almost_equal(p.x, 0.0))
  assert_true(@core.almost_equal(p.y, 0.0))
  assert_true(@core.almost_equal(p.z, 2.0))
  assert_true(a.closest_separation(b) < 0.000000001)
}

///|
test "Rect2 bounds and set operations" {
  let points = [
    @core.Point2::new(x=1.0, y=2.0),
    @core.Point2::new(x=-1.0, y=5.0),
    @core.Point2::new(x=4.0, y=0.0),
  ]
  let bounds = @core.rect2_from_points(points)
  assert_true(@core.almost_equal(bounds.width(), 5.0))
  assert_true(@core.almost_equal(bounds.height(), 5.0))
  assert_true(bounds.contains(@core.Point2::new(x=0.0, y=3.0)))
  let padded = bounds.expand(1.0)
  assert_true(@core.almost_equal(padded.area(), 49.0))
  let other = @core.Rect2::from_center_size(
    center=@core.Point2::new(x=2.0, y=2.0),
    width=2.0,
    height=2.0,
  )
  let merged = bounds.union(other)
  assert_true(merged.contains(@core.Point2::new(x=3.0, y=3.0)))
  guard bounds.intersection(other) is Some(hit) else {
    fail("expected intersection")
  }
  assert_true(hit.contains(@core.Point2::new(x=1.0, y=1.0)))
}
