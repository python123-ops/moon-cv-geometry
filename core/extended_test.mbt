///|
test "mesh bounds and polynomial roots" {
  let triangle = @core.Triangle3::new(
    a=@core.Point3::new(x=0.0, y=0.0, z=0.0),
    b=@core.Point3::new(x=1.0, y=0.0, z=0.0),
    c=@core.Point3::new(x=0.0, y=1.0, z=0.0),
  )
  assert_true(@core.almost_equal(triangle.area(), 0.5))
  assert_true(
    @core.barycentric3_contains(triangle.barycentric(triangle.centroid())),
  )
  let box = @core.Aabb3::from_points([triangle.a, triangle.b, triangle.c])
  assert_true(box.contains(triangle.centroid()))
  assert_true(box.volume() == 0.0)
  let q = @core.Quadratic::new(a=1.0, b=-3.0, c=2.0)
  assert_true(q.roots() == [1.0, 2.0])
  assert_true(@core.almost_equal(@core.solve_newton(q, initial=1.2), 1.0))
}

///|
test "interpolation and robust statistics" {
  assert_true(
    @core.almost_equal(@core.smoothstep(edge0=0.0, edge1=1.0, x=0.5), 0.5),
  )
  assert_true(
    @core.almost_equal(
      @core.interpolate_table(0.5, [0.0, 1.0], [0.0, 2.0]),
      1.0,
    ),
  )
  assert_true(
    @core.trimmed_mean([0.0, 1.0, 2.0, 100.0], trim_fraction=0.25) == 1.5,
  )
  assert_true(@core.interquartile_range([0.0, 1.0, 2.0, 3.0]) > 1.0)
  assert_true(
    @core.cumulative_lengths([
      @core.Point2::new(x=0.0, y=0.0),
      @core.Point2::new(x=3.0, y=4.0),
    ])[1] ==
    5.0,
  )
}
