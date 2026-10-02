///|
pub(all) struct Quadratic {
  a : Double
  b : Double
  c : Double
} derive(Debug, Eq)

///|
pub fn Quadratic::new(a~ : Double, b~ : Double, c~ : Double) -> Quadratic {
  { a, b, c, }
}

///|
pub fn Quadratic::evaluate(q : Quadratic, x : Double) -> Double {
  q.a * x * x + q.b * x + q.c
}

///|
pub fn Quadratic::derivative(q : Quadratic, x : Double) -> Double {
  2.0 * q.a * x + q.b
}

///|
pub fn Quadratic::roots(q : Quadratic) -> Array[Double] raise GeometryError {
  if abs(q.a) <= 0.000000000001 {
    if abs(q.b) <= 0.000000000001 {
      if abs(q.c) <= 0.000000000001 {
        []
      } else {
        raise GeometryError::DegenerateInput("constant polynomial has no root")
      }
    } else {
      [-q.c / q.b]
    }
  } else {
    let d = q.b * q.b - 4.0 * q.a * q.c
    if d < 0.0 {
      []
    } else if abs(d) <= 0.000000000001 {
      [-q.b / (2.0 * q.a)]
    } else {
      let s = d.sqrt()
      let x0 = (-q.b - s) / (2.0 * q.a)
      let x1 = (-q.b + s) / (2.0 * q.a)
      if x0 < x1 {
        [x0, x1]
      } else {
        [x1, x0]
      }
    }
  }
}

///|
pub fn newton_step(q : Quadratic, x : Double) -> Double raise GeometryError {
  let derivative = q.derivative(x)
  if abs(derivative) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("Newton derivative is zero")
  }
  x - q.evaluate(x) / derivative
}

///|
pub fn solve_newton(
  q : Quadratic,
  initial~ : Double,
  iterations? : Int = 8,
) -> Double raise GeometryError {
  if iterations <= 0 {
    raise GeometryError::DegenerateInput("Newton iterations must be positive")
  }
  for value = initial, i = 0; i < iterations; {
    continue newton_step(q, value), i + 1
  } nobreak {
    value
  }
}

///|
pub fn polynomial_residuals(
  q : Quadratic,
  values : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(q.evaluate(value))
  }
  result
}
