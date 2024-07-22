package main

import "core:slice"


AABB :: struct {
	x, y, z: Interval,
}

aabb_from_points :: proc(a, b: Point3) -> AABB {
	return {x = {min(a.x, b.x), max(a.x, b.x)}, y = {min(a.y, b.y), max(a.y, b.y)}, z = {min(a.z, b.z), max(a.z, b.z)}}
}

aabb_from_aabbs :: proc(box0, box1: AABB) -> AABB {
	return(
		 {
			x = interval_from_intervals(box0.x, box1.x),
			y = interval_from_intervals(box0.y, box1.y),
			z = interval_from_intervals(box0.z, box1.z),
		} \
	)
}

aabb_axis :: proc(aabb: AABB, n: int) -> Interval {
	if n == 1 do return aabb.y
	if n == 2 do return aabb.z
	return aabb.x
}

aabb_hit :: proc(aabb: AABB, r: Ray, ray_t: ^Interval) -> bool {
	for a in 0 ..< 3 {
		invD := 1 / r.dir[a]
		orig := r.orig[a]
		axis_a := aabb_axis(aabb, a)

		t0 := (axis_a.min - orig) * invD
		t1 := (axis_a.max - orig) * invD

		if invD < 0 {
			temp := t0
			t0 = t1
			t1 = temp
		}

		if t0 > ray_t.min do ray_t.min = t0
		if t1 < ray_t.max do ray_t.max = t1

		if ray_t.max <= ray_t.min do return false
	}
	return true
}

// Unoptimised approach
aabb_hit_unoptimal :: proc(aabb: AABB, r: Ray, ray_t: ^Interval) -> bool {
	for a in 0 ..< 3 {
		axis_a := aabb_axis(aabb, a)
		t0 := min((axis_a.min - r.orig[a]) / r.dir[a], (axis_a.max - r.orig[a]) / r.dir[a])
		t1 := max((axis_a.min - r.orig[a]) / r.dir[a], (axis_a.max - r.orig[a]) / r.dir[a])
		ray_t.min = max(t0, ray_t.min)
		ray_t.max = min(t1, ray_t.max)
		if ray_t.max <= ray_t.min do return false
	}
	return true
}
