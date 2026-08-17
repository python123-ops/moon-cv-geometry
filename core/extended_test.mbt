///|
test "mesh bounds and polynomial roots" {
  let triangle = Triangle3::new(
    a=Point3::new(x=0.0, y=0.0, z=0.0),
    b=Point3::new(x=1.0, y=0.0, z=0.0),
    c=Point3::new(x=0.0, y=1.0, z=0.0),
  )
  assert_true(almost_equal(triangle.area(), 0.5))
  assert_true(barycentric3_contains(triangle.barycentric(triangle.centroid())))
  let box = Aabb3::from_points([triangle.a, triangle.b, triangle.c])
  assert_true(box.contains(triangle.centroid()))
  assert_true(box.volume() == 0.0)
  let q = Quadratic::new(a=1.0, b=-3.0, c=2.0)
  assert_true(q.roots() == [1.0, 2.0])
  assert_true(almost_equal(solve_newton(q, initial=1.2), 1.0))
}

///|
test "interpolation and robust statistics" {
  assert_true(almost_equal(smoothstep(edge0=0.0, edge1=1.0, x=0.5), 0.5))
  assert_true(almost_equal(interpolate_table(0.5, [0.0, 1.0], [0.0, 2.0]), 1.0))
  assert_true(trimmed_mean([0.0, 1.0, 2.0, 100.0], trim_fraction=0.25) == 1.5)
  assert_true(interquartile_range([0.0, 1.0, 2.0, 3.0]) > 1.0)
  assert_true(
    cumulative_lengths([Point2::new(x=0.0, y=0.0), Point2::new(x=3.0, y=4.0)])[1] ==
    5.0,
  )
}
