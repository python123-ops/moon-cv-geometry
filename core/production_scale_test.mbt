///|
test "robust statistics expose stable quantiles and scale" {
  let values = [1.0, 2.0, 2.0, 3.0, 100.0]
  assert_true(@core.abs(@core.quantile_linear(values, 0.5) - 2.0) < 0.000001)
  assert_true(@core.median_absolute_deviation2(values) > 0.0)
  let clipped = @core.robust_clip(values, center=2.0, scale=1.0, multiplier=2.0)
  assert_eq(clipped[4], 4.0)
}

///|
test "batch linear algebra handles dimensions and zero vectors" {
  let matrix = @core.mat3_from_rows(
    (1.0, 2.0, 3.0),
    (0.0, 1.0, 4.0),
    (5.0, 6.0, 0.0),
  )
  let values = @core.mat3_apply_batch(matrix, [
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
    @core.Vec3::new(x=0.0, y=1.0, z=0.0),
  ])
  assert_eq(values.length(), 2)
  assert_true(values[0].z == 5.0)
  assert_eq(@core.batch_norms([]).length(), 0)
}

///|
test "geometry quality detects collinearity and duplicate support" {
  let collinear = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=2.0, y=2.0),
  ]
  assert_true(@core.is_collinear2(collinear, tolerance=0.000001))
  let duplicated = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
  ]
  assert_eq(@core.duplicate_count2(duplicated, tolerance=0.000001), 1)
}

///|
test "iterative solver and interpolation batches converge on simple data" {
  let result = @core.fixed_point_iterate(1.0, fn(x) { x / 2.0 }, iterations=3)
  assert_true(result < 0.2)
  let curve = @core.cubic_hermite_sample(0.0, 1.0, 1.0, 1.0, count=5)
  assert_eq(curve.length(), 5)
  assert_true(curve[0] == 0.0 && curve[4] == 1.0)
}

///|
test "transform batches and streaming statistics remain deterministic" {
  let transform = @core.RigidTransform::new(
    rotation=@core.identity3(),
    translation=@core.Vec3::new(x=1.0, y=2.0, z=3.0),
  )
  let points = @core.transform_points_batch(transform, [
    @core.Point3::new(x=0.0, y=0.0, z=0.0),
  ])
  assert_eq(points[0].x, 1.0)
  let summary = @core.streaming_summary([1.0, 2.0, 3.0])
  assert_eq(summary.count, 3)
  assert_true(summary.mean == 2.0)
}

///|
test "point cloud pipeline preserves centroid and pair statistics" {
  let points = [
    @core.Point3::new(x=0.0, y=0.0, z=1.0),
    @core.Point3::new(x=2.0, y=0.0, z=1.0),
    @core.Point3::new(x=0.0, y=2.0, z=1.0),
  ]
  let summary = @core.point_cloud_pipeline_summary(points)
  assert_eq(summary.count, 3)
  assert_true((summary.centroid.x - 0.6666666667).abs() < 0.000001)
  assert_true(summary.maximum_distance > 1.4)
}

///|
test "point cloud voxel sampling handles invalid resolution" {
  let points = [@core.Point3::new(x=1.0, y=2.0, z=3.0)]
  assert_eq(@core.point_cloud_voxel_sample(points, 0.0).length(), 1)
  assert_eq(@core.point_cloud_voxel_sample([], 1.0).length(), 0)
}

///|
test "point cloud export and health metrics are deterministic" {
  let points = [
    @core.Point3::new(x=0.0, y=0.0, z=0.0),
    @core.Point3::new(x=1.0, y=0.0, z=0.0),
  ]
  let flat = @core.point_cloud_to_flat(points)
  assert_eq(flat.length(), 6)
  assert_eq(@core.point_cloud_from_flat(flat).length(), 2)
  assert_true(@core.point_cloud_health_score(points, 2, 2.0, 0.001) > 0.0)
  assert_true(@core.point_cloud_csv(points).contains("x,y,z"))
}

///|
test "point cloud distances and projections handle empty and singleton input" {
  let point = @core.Point3::new(x=1.0, y=2.0, z=3.0)
  assert_eq(@core.point_cloud_nearest_distances([point]).length(), 1)
  assert_eq(@core.point_cloud_pairwise_distances([]).length(), 0)
  assert_eq(@core.point_cloud_project_xy([point])[0].x, 1.0)
  assert_true(@core.point_cloud_chamfer([], [point]) == 0.0)
}

///|
test "point cloud public operators cover production batch paths" {
  let points = [
    @core.Point3::new(x=-1.0, y=0.0, z=1.0),
    @core.Point3::new(x=0.0, y=1.0, z=2.0),
    @core.Point3::new(x=1.0, y=0.0, z=3.0),
  ]
  let center = @core.point_cloud_centroid(points)
  ignore(@core.point_cloud_bounds(points))
  ignore(@core.point_cloud_radius(points, center))
  ignore(@core.point_cloud_mean_distance(points, center))
  ignore(
    @core.point_cloud_translate(points, @core.Vec3::new(x=1.0, y=2.0, z=3.0)),
  )
  ignore(@core.point_cloud_scale(points, 2.0))
  ignore(@core.point_cloud_centered(points))
  ignore(@core.point_cloud_normalize_radius(points))
  ignore(@core.point_cloud_filter_radius(points, center, 2.0))
  ignore(@core.point_cloud_filter_box(points, points[0], points[2]))
  ignore(@core.point_cloud_distances(points, center))
  ignore(@core.point_cloud_squared_distances(points, center))
  ignore(@core.point_cloud_nearest_distance(points[0], points))
  ignore(@core.point_cloud_nearest_distances(points))
  ignore(@core.point_cloud_pairwise_distances(points))
  ignore(@core.point_cloud_pairwise_mean(points))
  ignore(@core.point_cloud_pairwise_maximum(points))
  ignore(@core.point_cloud_count_within(points, center, 2.0))
  ignore(@core.point_cloud_density(points, center, 2.0))
  ignore(@core.point_cloud_remove_duplicates(points, 0.01))
  ignore(@core.point_cloud_chunk(points, 2))
  ignore(@core.point_cloud_take(points, 2))
  ignore(@core.point_cloud_drop(points, 1))
  ignore(@core.point_cloud_stride(points, 2))
  ignore(@core.point_cloud_interleave(points, points))
  ignore(@core.point_cloud_resample_line(points[0], points[2], 4))
  ignore(@core.point_cloud_path_length(points))
  ignore(@core.point_cloud_axis_range(points, 0))
  ignore(@core.point_cloud_axis_values(points, 1))
  ignore(@core.point_cloud_variance_axis(points, 2))
  ignore(@core.point_cloud_voxel_sample(points, 0.5))
  ignore(@core.point_cloud_outlier_flags(points, 2.0))
  ignore(@core.point_cloud_remove_outliers(points, 2.0))
  ignore(@core.point_cloud_weighted_centroid(points, [1.0, 2.0, 1.0]))
  ignore(@core.point_cloud_weighted_radius(points, [1.0, 2.0, 1.0]))
  ignore(@core.point_cloud_align_centroids(points, points))
  ignore(@core.point_cloud_quality_score(points, 2, 3.0))
  ignore(@core.point_cloud_reflect_x(points))
  ignore(@core.point_cloud_reflect_y(points))
  ignore(@core.point_cloud_reflect_z(points))
  ignore(@core.point_cloud_axis_scale(points, 1.0, 2.0, 3.0))
  ignore(@core.point_cloud_axis_minimum(points, 0))
  ignore(@core.point_cloud_axis_maximum(points, 1))
  ignore(@core.point_cloud_axis_mean(points, 2))
  ignore(@core.point_cloud_axis_median(points, 0))
  ignore(@core.point_cloud_axis_quantile(points, 1, 0.5))
  ignore(@core.point_cloud_project_xz(points))
  ignore(@core.point_cloud_project_yz(points))
  ignore(@core.point_cloud_lift_xy(@core.point_cloud_project_xy(points), 1.0))
  ignore(@core.point_cloud_chamfer(points, points))
  ignore(@core.point_cloud_hausdorff(points, points))
  ignore(@core.point_cloud_overlap(points, points, 0.01))
  ignore(@core.point_cloud_intersection(points, points, 0.01))
  ignore(@core.point_cloud_union(points, points, 0.01))
  ignore(@core.point_cloud_sample_uniform(points, 2))
  ignore(@core.point_cloud_sample_endpoints(points, 3))
  ignore(@core.point_cloud_health_report(points, 2, 3.0, 0.01))
}
