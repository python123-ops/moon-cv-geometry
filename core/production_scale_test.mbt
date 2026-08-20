///|
test "robust statistics expose stable quantiles and scale" {
  let values = [1.0, 2.0, 2.0, 3.0, 100.0]
  assert_true(abs(quantile_linear(values, 0.5) - 2.0) < 0.000001)
  assert_true(median_absolute_deviation2(values) > 0.0)
  let clipped = robust_clip(values, center=2.0, scale=1.0, multiplier=2.0)
  assert_eq(clipped[4], 4.0)
}

///|
test "batch linear algebra handles dimensions and zero vectors" {
  let matrix = mat3_from_rows((1.0, 2.0, 3.0), (0.0, 1.0, 4.0), (5.0, 6.0, 0.0))
  let values = mat3_apply_batch(matrix, [
    Vec3::new(x=1.0, y=0.0, z=0.0),
    Vec3::new(x=0.0, y=1.0, z=0.0),
  ])
  assert_eq(values.length(), 2)
  assert_true(values[0].z == 5.0)
  assert_eq(batch_norms([]).length(), 0)
}

///|
test "geometry quality detects collinearity and duplicate support" {
  let collinear = [
    Point2::new(x=0.0, y=0.0),
    Point2::new(x=1.0, y=1.0),
    Point2::new(x=2.0, y=2.0),
  ]
  assert_true(is_collinear2(collinear, tolerance=0.000001))
  let duplicated = [
    Point2::new(x=0.0, y=0.0),
    Point2::new(x=0.0, y=0.0),
    Point2::new(x=1.0, y=0.0),
  ]
  assert_eq(duplicate_count2(duplicated, tolerance=0.000001), 1)
}

///|
test "iterative solver and interpolation batches converge on simple data" {
  let result = fixed_point_iterate(1.0, fn(x) { x / 2.0 }, iterations=3)
  assert_true(result < 0.2)
  let curve = cubic_hermite_sample(0.0, 1.0, 1.0, 1.0, count=5)
  assert_eq(curve.length(), 5)
  assert_true(curve[0] == 0.0 && curve[4] == 1.0)
}

///|
test "transform batches and streaming statistics remain deterministic" {
  let transform = RigidTransform::new(
    rotation=@core.identity3(),
    translation=Vec3::new(x=1.0, y=2.0, z=3.0),
  )
  let points = transform_points_batch(transform, [
    Point3::new(x=0.0, y=0.0, z=0.0),
  ])
  assert_eq(points[0].x, 1.0)
  let summary = streaming_summary([1.0, 2.0, 3.0])
  assert_eq(summary.count, 3)
  assert_true(summary.mean == 2.0)
}

///|
test "point cloud pipeline preserves centroid and pair statistics" {
  let points = [
    Point3::new(x=0.0, y=0.0, z=1.0),
    Point3::new(x=2.0, y=0.0, z=1.0),
    Point3::new(x=0.0, y=2.0, z=1.0),
  ]
  let summary = point_cloud_pipeline_summary(points)
  assert_eq(summary.count, 3)
  assert_true((summary.centroid.x - 0.6666666667).abs() < 0.000001)
  assert_true(summary.maximum_distance > 1.4)
}

///|
test "point cloud voxel sampling handles invalid resolution" {
  let points = [Point3::new(x=1.0, y=2.0, z=3.0)]
  assert_eq(point_cloud_voxel_sample(points, 0.0).length(), 1)
  assert_eq(point_cloud_voxel_sample([], 1.0).length(), 0)
}
