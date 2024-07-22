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

interval_from_intervals :: proc(a, b: Interval) -> Interval {
	return {min(a.min, b.min), max(a.max, b.max)}
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

interval_size :: proc(i: Interval) -> f64 {
	return i.max - i.min
}

interval_expand :: proc(i: Interval, delta: f64) -> Interval {
	padding := delta / 2
	return {i.min - padding, i.max + padding}
}
