package main

import "core:math"


INFINITY :: math.INF_F64

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

interval_clamp :: proc(i: Interval, x: f64) -> f64 {
	if x < i.min do return i.min
	if x > i.max do return i.max
	return x
}
