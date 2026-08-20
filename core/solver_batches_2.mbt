///|
/// Iterate a scalar fixed-point update with explicit iteration bounds.
pub fn fixed_point_iterate(
  initial : Double,
  update : (Double) -> Double,
  iterations~ : Int,
) -> Double {
  let mut value = initial
  for _ in 0..<iterations.max(0) {
    value = update(value)
  }
  value
}

///|
pub fn fixed_point_history(
  initial : Double,
  update : (Double) -> Double,
  iterations : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut value = initial
  result.push(value)
  for _ in 0..<iterations.max(0) {
    value = update(value)
    result.push(value)
  }
  result
}

///|
pub fn fixed_point_residual(
  value : Double,
  update : (Double) -> Double,
) -> Double {
  (update(value) - value).abs()
}

///|
pub fn fixed_point_until(
  initial : Double,
  update : (Double) -> Double,
  tolerance : Double,
  maximum_iterations : Int,
) -> Double {
  let mut value = initial
  for _ in 0..<maximum_iterations.max(0) {
    let next = update(value)
    if (next - value).abs() <= tolerance {
      return next
    }
    value = next
  }
  value
}

///|
pub fn gradient_step(
  value : Double,
  gradient : Double,
  step : Double,
) -> Double {
  value - step * gradient
}

///|
pub fn gradient_descent_1d(
  initial : Double,
  gradient : (Double) -> Double,
  step : Double,
  iterations : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut value = initial
  result.push(value)
  for _ in 0..<iterations.max(0) {
    value = gradient_step(value, gradient(value), step)
    result.push(value)
  }
  result
}

///|
pub fn finite_difference_gradient(
  function : (Double) -> Double,
  value : Double,
  epsilon : Double,
) -> Double {
  let h = epsilon.abs().max(0.000000000001)
  (function(value + h) - function(value - h)) / (2.0 * h)
}

///|
pub fn finite_difference_hessian(
  function : (Double) -> Double,
  value : Double,
  epsilon : Double,
) -> Double {
  let h = epsilon.abs().max(0.000000000001)
  (function(value + h) - 2.0 * function(value) + function(value - h)) / (h * h)
}

///|
pub fn line_search_backtrack(
  function : (Double) -> Double,
  start : Double,
  direction : Double,
  initial_step : Double,
  shrink : Double,
  maximum : Int,
) -> Double {
  let mut step = initial_step.abs()
  let baseline = function(start)
  for _ in 0..<maximum.max(0) {
    if function(start + direction * step) < baseline {
      return step
    }
    step *= shrink.max(0.0).min(1.0)
  }
  0.0
}

///|
pub fn solve_linear_2x2(
  a00 : Double,
  a01 : Double,
  a10 : Double,
  a11 : Double,
  b0 : Double,
  b1 : Double,
) -> (Double, Double) raise GeometryError {
  let determinant = a00 * a11 - a01 * a10
  if determinant.abs() <= 0.000000000001 {
    raise GeometryError::DegenerateInput("2x2 matrix is singular")
  }
  ((b0 * a11 - a01 * b1) / determinant, (a00 * b1 - b0 * a10) / determinant)
}

///|
pub fn solve_diagonal(
  diagonal : ArrayView[Double],
  values : ArrayView[Double],
) -> Array[Double] raise GeometryError {
  if diagonal.length() != values.length() {
    raise GeometryError::DegenerateInput("diagonal solve dimensions differ")
  }
  let result : Array[Double] = []
  for i in 0..<diagonal.length() {
    if diagonal[i].abs() <= 0.000000000001 {
      raise GeometryError::DegenerateInput("diagonal entry is zero")
    }
    result.push(values[i] / diagonal[i])
  }
  result
}

///|
pub fn residual_sum_squares(
  predicted : ArrayView[Double],
  observed : ArrayView[Double],
) -> Double {
  let count = predicted.length().min(observed.length())
  let mut result = 0.0
  for i in 0..<count {
    let difference = predicted[i] - observed[i]
    result += difference * difference
  }
  result
}

///|
pub fn residual_gradient(
  predicted : ArrayView[Double],
  observed : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    result.push(2.0 * (predicted[i] - observed[i]))
  }
  result
}

///|
pub fn residual_jacobian_diagonal(
  jacobian : ArrayView[Double],
  residuals : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = jacobian.length().min(residuals.length())
  for i in 0..<count {
    result.push(jacobian[i] * residuals[i])
  }
  result
}

///|
pub fn normalize_residual_vector(
  residuals : ArrayView[Double],
) -> Array[Double] {
  let norm = norm_scalars(residuals).max(0.000000000001)
  let result : Array[Double] = []
  for residual in residuals {
    result.push(residual / norm)
  }
  result
}

///|
pub fn cosine_similarity_values(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let denominator = norm_scalars(left) * norm_scalars(right)
  if denominator <= 0.000000000001 {
    0.0
  } else {
    dot_scalars(left, right) / denominator
  }
}

///|
pub fn project_box(
  value : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  value.max(minimum).min(maximum)
}

///|
pub fn project_box_batch(
  values : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(project_box(value, minimum, maximum))
  }
  result
}

///|
pub fn solver_converged(
  history : ArrayView[Double],
  tolerance : Double,
) -> Bool {
  if history.length() < 2 {
    false
  } else {
    (history[history.length() - 1] - history[history.length() - 2]).abs() <=
    tolerance
  }
}

///|
pub fn solver_best_value(
  history : ArrayView[Double],
  minimization : Bool,
) -> Double {
  if history.length() == 0 {
    0.0
  } else {
    let mut result = history[0]
    for value in history {
      result = if minimization { result.min(value) } else { result.max(value) }
    }
    result
  }
}

///|
pub fn solver_improvement(
  history : ArrayView[Double],
  minimization : Bool,
) -> Double {
  if history.length() < 2 {
    0.0
  } else if minimization {
    history[history.length() - 2] - history[history.length() - 1]
  } else {
    history[history.length() - 1] - history[history.length() - 2]
  }
}
