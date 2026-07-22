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
