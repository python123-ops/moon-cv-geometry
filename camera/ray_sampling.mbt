///|
/// A compact diagnostic for a batch of camera rays.
pub(all) struct RayBundleReport {
  count : Int
  mean_direction_norm : Double
  min_direction_z : Double
  max_direction_z : Double
} derive(Debug, Eq)

///|
/// Create a ray through every point of a regular image lattice.
pub fn image_ray_grid(
  size : ImageSize,
  intrinsics : CameraIntrinsics,
  columns : Int,
  rows : Int,
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  if columns <= 0 || rows <= 0 {
    return result
  }
  for row in 0..<rows {
    for column in 0..<columns {
      let x = if columns == 1 {
        0.5 * size.width.to_double()
      } else {
        column.to_double() *
        (size.width.to_double() - 1.0) /
        (columns - 1).to_double()
      }
      let y = if rows == 1 {
        0.5 * size.height.to_double()
      } else {
        row.to_double() *
        (size.height.to_double() - 1.0) /
        (rows - 1).to_double()
      }
      let pixel = @core.Point2::new(x~, y~)
      let normalized = pixel_to_normalized(pixel, intrinsics)
      let direction = @core.Vec3::new(x=normalized.x, y=normalized.y, z=1.0).normalize() catch {
        _ => @core.Vec3::new(x=0.0, y=0.0, z=1.0)
      }
      result.push({ origin: @core.Point3::new(x=0.0, y=0.0, z=0.0), direction })
    }
  }
  result
}

///|
/// Convert valid pixels to bearing rays, ignoring points outside the image.
pub fn sample_pixels(
  size : ImageSize,
  intrinsics : CameraIntrinsics,
  pixels : ArrayView[@core.Point2],
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  for pixel in pixels {
    if pixel.x >= 0.0 &&
      pixel.y >= 0.0 &&
      pixel.x < size.width.to_double() &&
      pixel.y < size.height.to_double() {
      let n = pixel_to_normalized(pixel, intrinsics)
      let direction = @core.Vec3::new(x=n.x, y=n.y, z=1.0).normalize() catch {
        _ => @core.Vec3::new(x=0.0, y=0.0, z=1.0)
      }
      result.push({ origin: @core.Point3::new(x=0.0, y=0.0, z=0.0), direction })
    }
  }
  result
}

///|
/// Summarize ray normalization and forward-facing coverage.
pub fn ray_bundle_report(rays : ArrayView[@core.Ray3]) -> RayBundleReport {
  if rays.length() == 0 {
    return {
      count: 0,
      mean_direction_norm: 0.0,
      min_direction_z: 0.0,
      max_direction_z: 0.0,
    }
  }
  let mut sum = 0.0
  let mut min_z = rays[0].direction.z
  let mut max_z = rays[0].direction.z
  for ray in rays {
    sum += ray.direction.norm()
    if ray.direction.z < min_z {
      min_z = ray.direction.z
    }
    if ray.direction.z > max_z {
      max_z = ray.direction.z
    }
  }
  {
    count: rays.length(),
    mean_direction_norm: sum / rays.length().to_double(),
    min_direction_z: min_z,
    max_direction_z: max_z,
  }
}

///|
/// Return only forward-facing rays for a camera-centered reconstruction.
pub fn forward_rays(
  rays : ArrayView[@core.Ray3],
  minimum_z? : Double = 0.000001,
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    if ray.direction.z >= minimum_z {
      result.push(ray)
    }
  }
  result
}
