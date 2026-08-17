///|
test "axis angle rotation and interpolation" {
  let axis = Vec3::new(x=0.0, y=0.0, z=1.0)
  let r = rotation_from_axis_angle(axis, @math.PI / 2.0)
  let turned = r.mul_vec3(Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(abs(turned.x) < 0.000001)
  assert_true(abs(turned.y - 1.0) < 0.000001)
  let half = interpolate_rotation(identity3(), r, 0.5)
  let v = half.mul_vec3(Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(abs(v.norm() - 1.0) < 0.000001)
}

///|
test "rotation between vectors handles parallel and opposite inputs" {
  let same = rotation_between(
    Vec3::new(x=1.0, y=0.0, z=0.0),
    Vec3::new(x=2.0, y=0.0, z=0.0),
  )
  assert_true(abs(same.det() - 1.0) < 0.000001)
  let opposite = rotation_between(
    Vec3::new(x=1.0, y=0.0, z=0.0),
    Vec3::new(x=-1.0, y=0.0, z=0.0),
  )
  let mapped = opposite.mul_vec3(Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(mapped.x < -0.999999)
}

///|
test "rotation validation and pose blending" {
  assert_true(is_rotation_matrix(identity3()))
  assert_false(
    is_rotation_matrix(
      mat3_from_rows((1.0, 0.0, 0.0), (0.0, 2.0, 0.0), (0.0, 0.0, 1.0)),
    ),
  )
  let a = RigidTransform::identity()
  let b = RigidTransform::new(
    rotation=identity3(),
    translation=Vec3::new(x=2.0, y=4.0, z=6.0),
  )
  let c = interpolate_pose(a, b, 0.25)
  assert_true(abs(c.translation.x - 0.5) < 0.000001)
}
