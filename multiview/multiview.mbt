///|
pub(all) struct Homography {
  matrix : @core.Mat3
} derive(Debug, Eq)

///|
pub fn Homography::new(matrix~ : @core.Mat3) -> Homography {
  { matrix, }
}

///|
pub(all) struct FundamentalMatrix {
  matrix : @core.Mat3
} derive(Debug, Eq)

///|
pub fn FundamentalMatrix::new(matrix~ : @core.Mat3) -> FundamentalMatrix {
  { matrix, }
}

///|
pub(all) struct EssentialMatrix {
  matrix : @core.Mat3
} derive(Debug, Eq)

///|
pub(all) struct TriangulatedPoint {
  point : @core.Point3
  separation : Double
} derive(Debug, Eq)

///|
pub fn EssentialMatrix::new(matrix~ : @core.Mat3) -> EssentialMatrix {
  { matrix, }
}

///|
pub fn Homography::apply(
  h : Homography,
  p : @core.Point2,
) -> @core.Point2 raise @core.GeometryError {
  let q = h.matrix.mul_vec3(@core.Vec3::new(x=p.x, y=p.y, z=1.0))
  if @core.abs(q.z) <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "homography maps point to infinity",
    )
  }
  @core.Point2::new(x=q.x / q.z, y=q.y / q.z)
}

///|
pub fn homography_reprojection_error(
  h : Homography,
  src : @core.Point2,
  dst : @core.Point2,
) -> Double raise @core.GeometryError {
  @core.reprojection_error(h.apply(src), dst)
}

///|
fn swap_rows(a : Array[Double], row_a : Int, row_b : Int, width : Int) -> Unit {
  for col in 0..<width {
    let ia = row_a * width + col
    let ib = row_b * width + col
    let tmp = a[ia]
    a[ia] = a[ib]
    a[ib] = tmp
  }
}

///|
fn solve_8x8(
  a_in : Array[Double],
  b_in : Array[Double],
) -> Array[Double] raise @core.GeometryError {
  if a_in.length() != 64 || b_in.length() != 8 {
    raise @core.GeometryError::DegenerateInput(
      "solve_8x8 expects an 8x8 matrix and 8-vector",
    )
  }
  let a = a_in.copy()
  let b = b_in.copy()
  for pivot in 0..<8 {
    let mut best = pivot
    let mut best_abs = @core.abs(a[pivot * 8 + pivot])
    for row in (pivot + 1)..<8 {
      let value = @core.abs(a[row * 8 + pivot])
      if value > best_abs {
        best = row
        best_abs = value
      }
    }
    if best_abs <= 0.000000000001 {
      raise @core.GeometryError::DegenerateInput(
        "point configuration is singular",
      )
    }
    if best != pivot {
      swap_rows(a, pivot, best, 8)
      let tmp = b[pivot]
      b[pivot] = b[best]
      b[best] = tmp
    }
    let diag = a[pivot * 8 + pivot]
    for col in pivot..<8 {
      a[pivot * 8 + col] = a[pivot * 8 + col] / diag
    }
    b[pivot] = b[pivot] / diag
    for row in 0..<8 {
      if row != pivot {
        let factor = a[row * 8 + pivot]
        if @core.abs(factor) > 0.0 {
          for col in pivot..<8 {
            a[row * 8 + col] = a[row * 8 + col] - factor * a[pivot * 8 + col]
          }
          b[row] = b[row] - factor * b[pivot]
        }
      }
    }
  }
  b
}

///|
pub fn estimate_homography_from_four(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
) -> Homography raise @core.GeometryError {
  if src.length() < 4 || dst.length() < 4 {
    raise @core.GeometryError::NotEnoughPoints(
      "homography needs four point pairs",
    )
  }
  let a : Array[Double] = []
  let b : Array[Double] = []
  for i in 0..<4 {
    let x = src[i].x
    let y = src[i].y
    let u = dst[i].x
    let v = dst[i].y
    a.push(x)
    a.push(y)
    a.push(1.0)
    a.push(0.0)
    a.push(0.0)
    a.push(0.0)
    a.push(-u * x)
    a.push(-u * y)
    b.push(u)
    a.push(0.0)
    a.push(0.0)
    a.push(0.0)
    a.push(x)
    a.push(y)
    a.push(1.0)
    a.push(-v * x)
    a.push(-v * y)
    b.push(v)
  }
  let h = solve_8x8(a, b)
  Homography::new(
    matrix=@core.mat3_from_rows(
      (h[0], h[1], h[2]),
      (h[3], h[4], h[5]),
      (h[6], h[7], 1.0),
    ),
  )
}

///|
fn solve_least_squares_8(
  rows : Array[Array[Double]],
  values : Array[Double],
) -> Array[Double] raise @core.GeometryError {
  if rows.length() != values.length() || rows.length() < 8 {
    raise @core.GeometryError::NotEnoughPoints(
      "least squares needs at least eight equations",
    )
  }
  let normal : Array[Double] = []
  let rhs : Array[Double] = []
  for i in 0..<8 {
    for j in 0..<8 {
      let mut value = 0.0
      for row in 0..<rows.length() {
        value += rows[row][i] * rows[row][j]
      }
      normal.push(value)
    }
    let mut value = 0.0
    for row in 0..<rows.length() {
      value += rows[row][i] * values[row]
    }
    rhs.push(value)
  }
  solve_8x8(normal, rhs)
}

///|
pub fn estimate_homography(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
) -> Homography raise @core.GeometryError {
  if src.length() != dst.length() || src.length() < 4 {
    raise @core.GeometryError::NotEnoughPoints(
      "homography needs at least four point pairs",
    )
  }
  if src.length() == 4 {
    estimate_homography_from_four(src, dst)
  } else {
    let (normalized_src, source_transform) = normalize_points(src)
    let (normalized_dst, destination_transform) = normalize_points(dst)
    let normalized = estimate_homography_raw(normalized_src, normalized_dst)
    let denormalized = destination_transform
      .inverse()
      .mul(normalized.matrix)
      .mul(source_transform)
    Homography::new(matrix=denormalized)
  }
}

///|
fn normalize_points(
  points : ArrayView[@core.Point2],
) -> (Array[@core.Point2], @core.Mat3) raise @core.GeometryError {
  if points.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints(
      "cannot normalize an empty point set",
    )
  }
  let mut center_x = 0.0
  let mut center_y = 0.0
  for point in points {
    center_x += point.x
    center_y += point.y
  }
  center_x = center_x / Double::from_int(points.length())
  center_y = center_y / Double::from_int(points.length())
  let mut squared_distance = 0.0
  for point in points {
    let dx = point.x - center_x
    let dy = point.y - center_y
    squared_distance += dx * dx + dy * dy
  }
  let rms = (squared_distance / Double::from_int(points.length())).sqrt()
  if rms <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput("point set has zero spread")
  }
  let scale = 1.4142135623730951 / rms
  let normalized : Array[@core.Point2] = []
  for point in points {
    normalized.push(
      @core.Point2::new(
        x=scale * (point.x - center_x),
        y=scale * (point.y - center_y),
      ),
    )
  }
  let transform = @core.mat3_from_rows(
    (scale, 0.0, -scale * center_x),
    (0.0, scale, -scale * center_y),
    (0.0, 0.0, 1.0),
  )
  (normalized, transform)
}

///|
fn estimate_homography_raw(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
) -> Homography raise @core.GeometryError {
  if src.length() != dst.length() || src.length() < 4 {
    raise @core.GeometryError::NotEnoughPoints(
      "homography needs at least four point pairs",
    )
  }
  if src.length() == 4 {
    estimate_homography_from_four(src, dst)
  } else {
    let rows : Array[Array[Double]] = []
    let values : Array[Double] = []
    for i in 0..<src.length() {
      let x = src[i].x
      let y = src[i].y
      let u = dst[i].x
      let v = dst[i].y
      rows.push([x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y])
      values.push(u)
      rows.push([0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y])
      values.push(v)
    }
    let h = solve_least_squares_8(rows, values)
    Homography::new(
      matrix=@core.mat3_from_rows(
        (h[0], h[1], h[2]),
        (h[3], h[4], h[5]),
        (h[6], h[7], 1.0),
      ),
    )
  }
}

///|
pub fn estimate_fundamental_from_translation(
  t : @core.Vec3,
) -> FundamentalMatrix {
  FundamentalMatrix::new(
    matrix=@core.mat3_from_rows(
      (0.0, -t.z, t.y),
      (t.z, 0.0, -t.x),
      (-t.y, t.x, 0.0),
    ),
  )
}

///|
pub fn estimate_fundamental(
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
) -> FundamentalMatrix raise @core.GeometryError {
  if left.length() != right.length() || left.length() < 8 {
    raise @core.GeometryError::NotEnoughPoints(
      "fundamental matrix needs at least eight point pairs",
    )
  }
  let rows : Array[Array[Double]] = []
  let values : Array[Double] = []
  for i in 0..<left.length() {
    let x = left[i].x
    let y = left[i].y
    let u = right[i].x
    let v = right[i].y
    rows.push([u * x, u * y, u, v * x, v * y, v, x, y])
    values.push(-1.0)
  }
  let f = solve_least_squares_8(rows, values)
  let matrix = @core.mat3_from_rows(
    (f[0], f[1], f[2]),
    (f[3], f[4], f[5]),
    (f[6], f[7], 1.0),
  )
  FundamentalMatrix::new(matrix~)
}

///|
pub fn epipolar_residual(
  f : FundamentalMatrix,
  left : @core.Point2,
  right : @core.Point2,
) -> Double {
  let l = @core.Vec3::new(x=left.x, y=left.y, z=1.0)
  let r = @core.Vec3::new(x=right.x, y=right.y, z=1.0)
  r.dot(f.matrix.mul_vec3(l))
}

///|
pub fn epipolar_line_in_right(
  f : FundamentalMatrix,
  left : @core.Point2,
) -> @core.Vec3 {
  f.matrix.mul_vec3(@core.Vec3::new(x=left.x, y=left.y, z=1.0))
}

///|
pub fn point_line_distance(
  line : @core.Vec3,
  p : @core.Point2,
) -> Double raise @core.GeometryError {
  let denom = @core.Vec2::new(x=line.x, y=line.y).norm()
  if denom <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "epipolar line has no finite normal",
    )
  }
  @core.abs(line.x * p.x + line.y * p.y + line.z) / denom
}

///|
pub fn epipolar_distance(
  f : FundamentalMatrix,
  left : @core.Point2,
  right : @core.Point2,
) -> Double raise @core.GeometryError {
  point_line_distance(epipolar_line_in_right(f, left), right)
}

///|
pub fn sampson_error(
  f : FundamentalMatrix,
  left : @core.Point2,
  right : @core.Point2,
) -> Double raise @core.GeometryError {
  let x1 = @core.Vec3::new(x=left.x, y=left.y, z=1.0)
  let x2 = @core.Vec3::new(x=right.x, y=right.y, z=1.0)
  let fx1 = f.matrix.mul_vec3(x1)
  let ftx2 = f.matrix.transpose().mul_vec3(x2)
  let residual = x2.dot(fx1)
  let denom = fx1.x * fx1.x + fx1.y * fx1.y + ftx2.x * ftx2.x + ftx2.y * ftx2.y
  if denom <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "Sampson denominator is degenerate",
    )
  }
  residual * residual / denom
}

///|
pub fn estimate_essential_from_fundamental(
  f : FundamentalMatrix,
  k_left : @core.Mat3,
  k_right : @core.Mat3,
) -> EssentialMatrix {
  EssentialMatrix::new(matrix=k_right.transpose().mul(f.matrix).mul(k_left))
}

///|
pub fn triangulate_from_rays(
  left : @core.Ray3,
  right : @core.Ray3,
) -> TriangulatedPoint raise @core.GeometryError {
  let point = left.closest_midpoint(right)
  let separation = left.closest_separation(right)
  { point, separation }
}

///|
pub fn triangulation_is_well_conditioned(
  result : TriangulatedPoint,
  max_separation? : Double = 0.001,
) -> Bool {
  result.separation <= max_separation
}

///|
pub fn triangulated_point_is_in_front(
  result : TriangulatedPoint,
  left : @core.Ray3,
  right : @core.Ray3,
) -> Bool {
  let left_depth = result.point.minus(left.origin).dot(left.direction)
  let right_depth = result.point.minus(right.origin).dot(right.direction)
  left_depth > 0.0 && right_depth > 0.0
}

///|
pub fn triangulation_angle(left : @core.Ray3, right : @core.Ray3) -> Double {
  let cosine = left.direction.dot(right.direction)
  let bounded = if cosine < -1.0 {
    -1.0
  } else if cosine > 1.0 {
    1.0
  } else {
    cosine
  }
  @math.acos(bounded)
}
