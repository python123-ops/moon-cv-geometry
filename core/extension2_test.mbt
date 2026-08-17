///|
test "transform chain composes in insertion order" {
  let first = RigidTransform::new(
    rotation=identity3(),
    translation=Vec3::new(x=1.0, y=0.0, z=0.0),
  )
  let second = RigidTransform::new(
    rotation=identity3(),
    translation=Vec3::new(x=0.0, y=2.0, z=0.0),
  )
  let chain = TransformChain::new([first, second])
  let p = chain.apply(Point3::new(x=0.0, y=0.0, z=1.0))
  assert_true(almost_equal(p.x, 1.0))
  assert_true(almost_equal(p.y, 2.0))
  assert_true(chain.length() == 2)
}

///|
test "point cloud report filters invalid depth" {
  let cloud = PointCloud::from_points([
    Point3::new(x=0.0, y=0.0, z=1.0),
    Point3::new(x=2.0, y=0.0, z=3.0),
    Point3::new(x=1.0, y=1.0, z=-1.0),
  ])
  assert_true(cloud.valid_depth_count() == 2)
  assert_true(almost_equal(cloud.centroid().z, 1.0))
  assert_true(cloud.depth_range().1 == 3.0)
}

///|
test "matrix diagnostics expose trace and power" {
  let m = mat3_from_rows((2.0, 0.0, 0.0), (0.0, 3.0, 0.0), (0.0, 0.0, 4.0))
  assert_true(almost_equal(m.trace(), 9.0))
  assert_true(almost_equal(m.power(2).m11, 9.0))
  assert_true(m.hadamard(identity3()).m22 == 4.0)
}
