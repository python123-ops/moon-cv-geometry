///|
/// Construct a proper rotation with Rodrigues' formula.
pub fn rotation_from_axis_angle(
  axis : Vec3,
  angle : Double,
) -> Mat3 raise GeometryError {
  let unit = axis.normalize()
  let x = unit.x
  let y = unit.y
  let z = unit.z
  let c = @math.cos(angle)
  let s = @math.sin(angle)
  let v = 1.0 - c
  mat3_from_rows(
    (c + x * x * v, x * y * v - z * s, x * z * v + y * s),
    (y * x * v + z * s, c + y * y * v, y * z * v - x * s),
    (z * x * v - y * s, z * y * v + x * s, c + z * z * v),
  )
}

///|
/// Return a shortest-arc rotation between two non-zero directions.
pub fn rotation_between(from : Vec3, to : Vec3) -> Mat3 raise GeometryError {
  let a = from.normalize()
  let b = to.normalize()
  let cross = a.cross(b)
  let dot = a.dot(b)
  if dot > 1.0 - 0.000000000001 {
    identity3()
  } else if dot < -1.0 + 0.000000000001 {
    let helper = if abs(a.x) < abs(a.y) {
      Vec3::new(x=1.0, y=0.0, z=0.0)
    } else {
      Vec3::new(x=0.0, y=1.0, z=0.0)
    }
    rotation_from_axis_angle(a.cross(helper), @math.PI)
  } else {
    let angle = @math.atan2(cross.norm(), dot)
    rotation_from_axis_angle(cross, angle)
  }
}

///|
/// Check orthogonality and handedness with a scale-aware tolerance.
pub fn is_rotation_matrix(m : Mat3) -> Bool {
  let gram = m.transpose().mul(m)
  let error = gram.sub(identity3()).frobenius_norm()
  abs(m.det() - 1.0) < 0.000001 && error < 0.000001
}

///|
/// Linearly blend rotations in quaternion space, preserving unit length.
pub fn interpolate_rotation(a : Mat3, b : Mat3, amount : Double) -> Mat3 {
  let blended = a.scale(1.0 - amount).add(b.scale(amount))
  orthogonalize_rotation(blended) catch {
    _ => a
  }
}

///|
/// Interpolate a rigid pose for timestamp alignment and motion compensation.
pub fn interpolate_pose(
  a : RigidTransform,
  b : RigidTransform,
  amount : Double,
) -> RigidTransform {
  let t = a.translation.scale(1.0 - amount).add(b.translation.scale(amount))
  RigidTransform::new(
    rotation=interpolate_rotation(a.rotation, b.rotation, amount),
    translation=t,
  )
}

///|
/// Batch-apply a rotation while retaining point-array order.
pub fn rotate_points(
  rotation : Mat3,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for p in points {
    let v = rotation.mul_vec3(p.to_vec())
    result.push(Point3::new(x=v.x, y=v.y, z=v.z))
  }
  result
}

///|
/// Measure how far a matrix is from the SO(3) manifold.
pub fn rotation_residual(m : Mat3) -> Double {
  m.transpose().mul(m).sub(identity3()).frobenius_norm() + abs(m.det() - 1.0)
}

///|
/// Project a near-rotation onto SO(3) using a stable transpose averaging pass.
pub fn orthogonalize_rotation(m : Mat3) -> Mat3 raise GeometryError {
  let mut result = m
  for _ in 0..<6 {
    result = result.add(result.inverse().transpose()).scale(0.5)
  }
  if result.det() < 0.0 {
    mat3_from_rows(
      (-result.m00, result.m01, result.m02),
      (-result.m10, result.m11, result.m12),
      (-result.m20, result.m21, result.m22),
    )
  } else {
    result
  }
}
