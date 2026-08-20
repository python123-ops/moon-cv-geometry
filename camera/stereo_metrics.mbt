///|
/// Summary of stereo depth recovered from disparity measurements.
pub(all) struct StereoDepthReport {
  total : Int
  valid_count : Int
  invalid_count : Int
  mean : Double
  minimum : Double
  maximum : Double
} derive(Debug, Eq)

///|
pub fn disparity_to_depth(
  disparity : Double,
  baseline : Double,
  focal : Double,
) -> Double {
  if disparity <= 0.0 || baseline <= 0.0 || focal <= 0.0 {
    0.0
  } else {
    baseline * focal / disparity
  }
}

///|
pub fn stereo_depth_report(
  disparities : ArrayView[Double],
  baseline~ : Double,
  focal~ : Double,
) -> StereoDepthReport {
  let mut valid = 0
  let mut sum = 0.0
  let mut minimum = 0.0
  let mut maximum = 0.0
  for disparity in disparities {
    let depth = disparity_to_depth(disparity, baseline, focal)
    if depth > 0.0 {
      if valid == 0 {
        minimum = depth
        maximum = depth
      } else {
        minimum = minimum.min(depth)
        maximum = maximum.max(depth)
      }
      sum += depth
      valid += 1
    }
  }
  {
    total: disparities.length(),
    valid_count: valid,
    invalid_count: disparities.length() - valid,
    mean: if valid == 0 {
      0.0
    } else {
      sum / valid.to_double()
    },
    minimum: if valid == 0 {
      0.0
    } else {
      minimum
    },
    maximum: if valid == 0 {
      0.0
    } else {
      maximum
    },
  }
}

///|
pub fn stereo_depths2(
  disparities : ArrayView[Double],
  baseline : Double,
  focal : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for disparity in disparities {
    result.push(disparity_to_depth(disparity, baseline, focal))
  }
  result
}

///|
pub fn depth_to_disparity(
  depth : Double,
  baseline : Double,
  focal : Double,
) -> Double {
  if depth <= 0.0 || baseline <= 0.0 || focal <= 0.0 {
    0.0
  } else {
    baseline * focal / depth
  }
}

///|
pub fn disparity_error_to_depth_error(
  disparity : Double,
  disparity_error : Double,
  baseline : Double,
  focal : Double,
) -> Double {
  let depth = disparity_to_depth(disparity, baseline, focal)
  if depth <= 0.0 {
    0.0
  } else {
    disparity_error.abs() / disparity.max(0.000000000001) * depth
  }
}

///|
pub fn stereo_valid_ratio(report : StereoDepthReport) -> Double {
  if report.total == 0 {
    0.0
  } else {
    report.valid_count.to_double() / report.total.to_double()
  }
}

///|
pub fn stereo_report_is_usable(
  report : StereoDepthReport,
  minimum_ratio : Double,
  maximum_span : Double,
) -> Bool {
  stereo_valid_ratio(report) >= minimum_ratio &&
  report.maximum - report.minimum <= maximum_span
}

///|
pub fn clip_disparities(
  disparities : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for disparity in disparities {
    result.push(disparity.max(minimum).min(maximum))
  }
  result
}

///|
pub fn disparity_histogram(
  disparities : ArrayView[Double],
  bins : Int,
  minimum : Double,
  maximum : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<bins.max(0) {
    result.push(0)
  }
  let width = (maximum - minimum).max(0.000000000001)
  for disparity in disparities {
    if disparity >= minimum && disparity <= maximum && result.length() > 0 {
      let index = ((disparity - minimum) / width * result.length().to_double())
        .to_int()
        .max(0)
        .min(result.length() - 1)
      result[index] += 1
    }
  }
  result
}

///|
pub fn stereo_consistency(
  left : ArrayView[Double],
  right : ArrayView[Double],
  tolerance : Double,
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    0.0
  } else {
    let mut valid = 0
    for i in 0..<count {
      if (left[i] - right[i]).abs() <= tolerance {
        valid += 1
      }
    }
    valid.to_double() / count.to_double()
  }
}
