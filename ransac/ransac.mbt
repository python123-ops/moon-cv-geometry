///|
pub(all) struct RansacConfig {
  iterations : Int
  threshold : Double
  min_inliers : Int
  seed : UInt
} derive(Debug, Eq)

///|
pub fn RansacConfig::new(
  iterations? : Int = 128,
  threshold? : Double = 2.0,
  min_inliers? : Int = 4,
  seed? : UInt = 1U,
) -> RansacConfig {
  { iterations, threshold, min_inliers, seed }
}

///|
pub(all) struct InlierMask {
  values : Array[Bool]
} derive(Debug, Eq)

///|
pub(all) struct RansacResult[T] {
  model : T
  inliers : InlierMask
  inlier_count : Int
  score : Double
} derive(Debug, Eq)

///|
fn lcg_next(state : UInt) -> UInt {
  state * 1664525U + 1013904223U
}

///|
fn pick_index(state : UInt, len : Int) -> Int {
  (state % len.reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn sample_four(len : Int, seed : UInt, iter : Int) -> (Int, Int, Int, Int) {
  let s0 = lcg_next(seed + iter.reinterpret_as_uint() * 747796405U)
  let i0 = pick_index(s0, len)
  let s1 = lcg_next(s0)
  let i1 = (pick_index(s1, len - 1) + i0 + 1) % len
  let s2 = lcg_next(s1)
  let i2 = (pick_index(s2, len - 2) + i1 + 1) % len
  let s3 = lcg_next(s2)
  let i3 = (pick_index(s3, len - 3) + i2 + 1) % len
  (i0, i1, i2, i3)
}

///|
fn make_four(
  points : ArrayView[@core.Point2],
  indices : (Int, Int, Int, Int),
) -> Array[@core.Point2] {
  let (i0, i1, i2, i3) = indices
  [points[i0], points[i1], points[i2], points[i3]]
}

///|
pub fn estimate_homography_ransac(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
  config? : RansacConfig = RansacConfig::new(),
) -> RansacResult[@multiview.Homography] raise @core.GeometryError {
  if src.length() != dst.length() || src.length() < 4 {
    raise @core.GeometryError::NotEnoughPoints(
      "homography RANSAC needs at least four paired points",
    )
  }
  let fallback = @multiview.estimate_homography_from_four(src, dst)
  let empty_mask = InlierMask::{ values: [] }
  let initial = RansacResult::{
    model: fallback,
    inliers: empty_mask,
    inlier_count: -1,
    score: 1.0e100,
  }
  for best = initial, iter = 0; iter < config.iterations; {
    let indices = sample_four(src.length(), config.seed, iter)
    let candidate_src = make_four(src, indices)
    let candidate_dst = make_four(dst, indices)
    let candidate = try
      @multiview.estimate_homography_from_four(candidate_src, candidate_dst)
    catch {
      _ => best
    } noraise {
      h => {
        let mask : Array[Bool] = []
        let mut count = 0
        let mut score = 0.0
        for i in 0..<src.length() {
          let err = @multiview.homography_reprojection_error(h, src[i], dst[i]) catch {
            _ => 1.0e100
          }
          let ok = err <= config.threshold
          mask.push(ok)
          if ok {
            count += 1
            score += err
          }
        }
        if count > best.inlier_count ||
          (count == best.inlier_count && score < best.score) {
          RansacResult::{
            model: h,
            inliers: InlierMask::{ values: mask },
            inlier_count: count,
            score,
          }
        } else {
          best
        }
      }
    }
    continue candidate, iter + 1
  } nobreak {
    if best.inlier_count < config.min_inliers {
      raise @core.GeometryError::DegenerateInput(
        "RANSAC could not find enough homography inliers",
      )
    }
    best
  }
}

///|
pub fn estimate_fundamental_ransac(
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  config? : RansacConfig = RansacConfig::new(),
) -> RansacResult[@multiview.FundamentalMatrix] raise @core.GeometryError {
  if left.length() != right.length() || left.length() < 2 {
    raise @core.GeometryError::NotEnoughPoints(
      "fundamental RANSAC needs paired points",
    )
  }
  let model = @multiview.estimate_fundamental_from_translation(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
  )
  let mask : Array[Bool] = []
  let mut count = 0
  let mut score = 0.0
  for i in 0..<left.length() {
    let err = @core.abs(@multiview.epipolar_residual(model, left[i], right[i]))
    let ok = err <= config.threshold
    mask.push(ok)
    if ok {
      count += 1
      score += err
    }
  }
  if count < config.min_inliers {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC could not find enough fundamental inliers",
    )
  }
  RansacResult::{
    model,
    inliers: InlierMask::{ values: mask },
    inlier_count: count,
    score,
  }
}
