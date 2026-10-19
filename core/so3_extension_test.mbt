///|
test "axis angle rotation and interpolation" {
  let axis = @core.Vec3::new(x=0.0, y=0.0, z=1.0)
  let r = @core.rotation_from_axis_angle(axis, @math.PI / 2.0)
  let turned = r.mul_vec3(@core.Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(@core.abs(turned.x) < 0.000001)
  assert_true(@core.abs(turned.y - 1.0) < 0.000001)
  let half = @core.interpolate_rotation(@core.identity3(), r, 0.5)
  let v = half.mul_vec3(@core.Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(@core.abs(v.norm() - 1.0) < 0.000001)
}

///|
test "rotation between vectors handles parallel and opposite inputs" {
  let same = @core.rotation_between(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
    @core.Vec3::new(x=2.0, y=0.0, z=0.0),
  )
  assert_true(@core.abs(same.det() - 1.0) < 0.000001)
  let opposite = @core.rotation_between(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
    @core.Vec3::new(x=-1.0, y=0.0, z=0.0),
  )
  let mapped = opposite.mul_vec3(@core.Vec3::new(x=1.0, y=0.0, z=0.0))
  assert_true(mapped.x < -0.999999)
}

///|
test "rotation validation and pose blending" {
  assert_true(@core.is_rotation_matrix(@core.identity3()))
  assert_false(
    @core.is_rotation_matrix(
      @core.mat3_from_rows((1.0, 0.0, 0.0), (0.0, 2.0, 0.0), (0.0, 0.0, 1.0)),
    ),
  )
  let a = @core.RigidTransform::identity()
  let b = @core.RigidTransform::new(
    rotation=@core.identity3(),
    translation=@core.Vec3::new(x=2.0, y=4.0, z=6.0),
  )
  let c = @core.interpolate_pose(a, b, 0.25)
  assert_true(@core.abs(c.translation.x - 0.5) < 0.000001)
}
