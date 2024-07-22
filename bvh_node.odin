package main

import "core:fmt"
import "core:math/rand"
import "core:slice"


BVH_Node :: struct {
	left:  ^Hittable,
	right: ^Hittable,
	bbox:  AABB,
}

bvh_make :: proc(objects: []Hittable, start, end: u64) -> BVH_Node {
	bvh: BVH_Node
	axis := int(rand.int31_max(2))
	fmt.printfln("axis: %v", axis)
	context.user_index = axis

	object_span := end - start
	if object_span == 1 {
		bvh.left = &objects[start]
		bvh.right = &objects[start]
	} else if object_span == 2 {
		if shape_compare(objects[start], objects[start + 1]) {
			bvh.left = &objects[start]
			bvh.right = &objects[start + 1]
		} else {
			bvh.left = &objects[start + 1]
			bvh.right = &objects[start]
		}
	} else {
		sorting := objects[start:end]
		slice.sort_by(sorting, shape_compare)

		mid := start + object_span / 2
		bvh.left = bvh_make(sorting, start, mid)
		bvh.right = bvh_make(sorting, mid, end)
	}

	left := bvh.left.(BVH_Node)
	right := bvh.right.(BVH_Node)
	bvh.bbox = {left.bbox, right.bbox}

	return bvh
}

box_compare :: proc(a, b: Hittable, axis_index: int) -> bool {
	a := a.(BVH_Node)
	b := b.(BVH_Node)
	return aabb_axis(a.bbox, axis_index).min < aabb_axis(b.bbox, axis_index).min
}

shape_compare :: proc(a, b: Hittable) -> bool {
	return box_compare(a, b, context.user_index)
}

bvh_hit :: proc(bvh: BVH_Node, r: Ray, ray_t: Interval, rec: Hit_Record) -> bool {
	if !aabb_hit(bvh.bbox, r, ray_t) do return false

	hit_left := bvh_hit(bvh.left, r, ray_t, rec)
	hit_right := bvh_hit(bvh.right, r, Interval{ray_t.min, hit_left ? rec.t : ray_t.max}, rec)

	return hit_left || hit_right
}
