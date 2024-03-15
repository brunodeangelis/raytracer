package main


Interval :: struct {
	min, max: f64,
}

INTERVAL_EMPTY :: Interval {
	min = +INFINITY,
	max = -INFINITY,
}

INTERVAL_UNIVERSE :: Interval {
	min = -INFINITY,
	max = +INFINITY,
}

interval_contains :: proc(i: Interval, x: f64) -> bool {
	return i.min <= x && x <= i.max
}

interval_surrounds :: proc(i: Interval, x: f64) -> bool {
	return i.min < x && x < i.max
}
