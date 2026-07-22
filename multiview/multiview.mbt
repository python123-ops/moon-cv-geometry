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
