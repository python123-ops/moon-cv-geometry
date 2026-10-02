///|
pub(all) struct CalibrationObservation {
  world : @core.Point3
  pixel : @core.Point2
  weight : Double
} derive(Debug, Eq)

///|
pub fn CalibrationObservation::new(
  world~ : @core.Point3,
  pixel~ : @core.Point2,
  weight? : Double = 1.0,
) -> CalibrationObservation {
  { world, pixel, weight, }
}

///|
pub fn CalibrationObservation::residual(
  observation : CalibrationObservation,
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
  distortion? : Distortion = Distortion::none(),
) -> @core.Vec2 raise @core.GeometryError {
  let predicted = project_point_with_pose(
    observation.world,
    intrinsics,
    pose,
    distortion~,
  )
  predicted.minus(observation.pixel)
}

///|
pub fn reprojection_cost(
  observations : ArrayView[CalibrationObservation],
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
  distortion? : Distortion = Distortion::none(),
) -> Double raise @core.GeometryError {
  let mut total = 0.0
  let mut weight = 0.0
  for observation in observations {
    let residual = observation.residual(intrinsics, pose, distortion~)
    total += observation.weight * residual.norm2()
    weight += observation.weight
  }
  if weight <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "observation weights must be positive",
    )
  }
  total / weight
}

///|
pub(all) struct ProjectionJacobian {
  du_dx : Double
  du_dy : Double
  du_dz : Double
  dv_dx : Double
  dv_dy : Double
  dv_dz : Double
} derive(Debug, Eq)

///|
pub fn projection_jacobian(
  point : @core.Point3,
  intrinsics : CameraIntrinsics,
) -> ProjectionJacobian raise @core.GeometryError {
  if point.z <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "jacobian point must be in front of camera",
    )
  }
  let iz = 1.0 / point.z
  let iz2 = iz * iz
  {
    du_dx: intrinsics.fx * iz,
    du_dy: intrinsics.skew * iz,
    du_dz: -(intrinsics.fx * point.x + intrinsics.skew * point.y) * iz2,
    dv_dx: 0.0,
    dv_dy: intrinsics.fy * iz,
    dv_dz: -intrinsics.fy * point.y * iz2,
  }
}

///|
pub fn distortion_jacobian(p : @core.Point2, d : Distortion) -> @core.Mat3 {
  let x = p.x
  let y = p.y
  let r2 = x * x + y * y
  let r4 = r2 * r2
  let r6 = r4 * r2
  let radial = 1.0 + d.k1 * r2 + d.k2 * r4 + d.k3 * r6
  let radial_derivative = 2.0 * (d.k1 + 2.0 * d.k2 * r2 + 3.0 * d.k3 * r4)
  let dx = radial + x * x * radial_derivative + 2.0 * d.p1 * y + 6.0 * d.p2 * x
  let dy = x * y * radial_derivative + 2.0 * d.p1 * x + 2.0 * d.p2 * y
  let ex = x * y * radial_derivative + 2.0 * d.p1 * x + 2.0 * d.p2 * y
  let ey = radial + y * y * radial_derivative + 6.0 * d.p1 * y + 2.0 * d.p2 * x
  @core.mat3_from_rows((dx, dy, 0.0), (ex, ey, 0.0), (0.0, 0.0, 1.0))
}

///|
pub fn project_points(
  points : ArrayView[@core.Point3],
  intrinsics : CameraIntrinsics,
  pose? : CameraPose = CameraPose::identity(),
  distortion? : Distortion = Distortion::none(),
) -> Array[@core.Point2] raise @core.GeometryError {
  let output : Array[@core.Point2] = []
  for point in points {
    output.push(project_point_with_pose(point, intrinsics, pose, distortion~))
  }
  output
}

///|
pub fn bearing_rays(
  pixels : ArrayView[@core.Point2],
  intrinsics : CameraIntrinsics,
  distortion? : Distortion = Distortion::none(),
) -> Array[@core.Vec3] raise @core.GeometryError {
  let rays : Array[@core.Vec3] = []
  for pixel in pixels {
    rays.push(bearing_from_pixel(pixel, intrinsics, distortion~))
  }
  rays
}

///|
pub(all) struct ImagePyramidLevel {
  size : ImageSize
  intrinsics : CameraIntrinsics
  level : Int
} derive(Debug, Eq)

///|
pub fn image_pyramid(
  size : ImageSize,
  intrinsics : CameraIntrinsics,
  levels~ : Int,
) -> Array[ImagePyramidLevel] raise @core.GeometryError {
  if levels <= 0 {
    raise @core.GeometryError::DegenerateInput(
      "pyramid needs one or more levels",
    )
  }
  let result : Array[ImagePyramidLevel] = []
  for level in 0..<levels {
    let mut divisor = 1.0
    for _ in 0..<level {
      divisor *= 2.0
    }
    let width = (Double::from_int(size.width) / divisor).to_int()
    let height = (Double::from_int(size.height) / divisor).to_int()
    if width < 1 || height < 1 {
      break
    }
    let current = ImageSize::new(width~, height~)
    result.push({
      size: current,
      intrinsics: intrinsics.scaled(
        scale_x=1.0 / divisor,
        scale_y=1.0 / divisor,
      ),
      level,
    })
  }
  result
}

///|
pub(all) struct Frustum {
  left : Double
  right : Double
  top : Double
  bottom : Double
  near : Double
  far : Double
} derive(Debug, Eq)

///|
pub fn Frustum::from_intrinsics(
  k : CameraIntrinsics,
  size : ImageSize,
  near~ : Double,
  far~ : Double,
) -> Frustum raise @core.GeometryError {
  if near <= 0.0 || far <= near {
    raise @core.GeometryError::DegenerateInput("frustum depth range is invalid")
  }
  {
    left: -k.cx / k.fx * near,
    right: (Double::from_int(size.width) - k.cx) / k.fx * near,
    top: -k.cy / k.fy * near,
    bottom: (Double::from_int(size.height) - k.cy) / k.fy * near,
    near,
    far,
  }
}

///|
pub fn Frustum::contains(f : Frustum, p : @core.Point3) -> Bool {
  if p.z < f.near || p.z > f.far {
    false
  } else {
    let scale = p.z / f.near
    p.x >= f.left * scale &&
    p.x <= f.right * scale &&
    p.y >= f.top * scale &&
    p.y <= f.bottom * scale
  }
}

///|
pub fn valid_intrinsics(k : CameraIntrinsics) -> Bool {
  k.fx > 0.0 && k.fy > 0.0
}

///|
pub fn distortion_is_identity(d : Distortion) -> Bool {
  d.k1 == 0.0 && d.k2 == 0.0 && d.k3 == 0.0 && d.p1 == 0.0 && d.p2 == 0.0
}

///|
pub fn normalized_reprojection_error(
  a : @core.Point2,
  b : @core.Point2,
) -> Double {
  a.minus(b).norm()
}
