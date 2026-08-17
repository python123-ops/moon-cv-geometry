///|
pub(all) struct ReconstructionReport {
  total : Int
  positive_depth : Int
  median_depth : Double
  median_parallax : Double
} derive(Debug, Eq)

///|
pub fn reconstruction_report(
  points : ArrayView[@core.Point3],
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> ReconstructionReport raise @core.GeometryError {
  if points.length() != left.length() ||
    points.length() != right.length() ||
    points.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints(
      "reconstruction report inputs differ",
    )
  }
  let depths : Array[Double] = []
  let mut positive = 0
  for p in points {
    depths.push(p.z)
    if p.z > 0.0 {
      positive += 1
    }
  }
  {
    total: points.length(),
    positive_depth: positive,
    median_depth: @core.median(depths),
    median_parallax: median_parallax(left, right),
  }
}

///|
pub fn reconstruction_usable(
  report : ReconstructionReport,
  minimum_positive_ratio? : Double = 0.8,
  minimum_parallax? : Double = 0.5,
) -> Bool {
  Double::from_int(report.positive_depth) / Double::from_int(report.total) >=
  minimum_positive_ratio &&
  report.median_parallax >= minimum_parallax
}

///|
pub fn reprojection_residual_matrix(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Array[Double]] raise @core.GeometryError {
  if predicted.length() != observed.length() {
    raise @core.GeometryError::DegenerateInput("residual matrix inputs differ")
  }
  let result : Array[Array[Double]] = []
  for i in 0..<predicted.length() {
    let d = predicted[i].minus(observed[i])
    result.push([d.x, d.y, d.norm()])
  }
  result
}

///|
pub fn residual_norms(matrix : ArrayView[Array[Double]]) -> Array[Double] {
  let result : Array[Double] = []
  for row in matrix {
    if row.length() >= 3 {
      result.push(row[2])
    }
  }
  result
}

///|
pub fn triangulation_reprojection_check(
  result : TriangulatedPoint,
  left : @core.Ray3,
  right : @core.Ray3,
  threshold~ : Double,
) -> Bool {
  result.separation <= threshold &&
  triangulated_point_is_in_front(result, left, right)
}
