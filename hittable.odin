package main

import "core:math/linalg"


Hit_Record :: struct {
	p:          Point3,
	normal:     Vec3,
	t:          f64,
	front_face: bool,
}

Sphere :: struct {
	center: Point3,
	radius: f64,
}

Hittable_List :: struct {
	objects: [dynamic]Hittable,
}

Hittable :: union {
	Sphere,
	Hittable_List,
}

hit :: proc(h: Hittable, r: Ray, ray_t: Interval, rec: ^Hit_Record) -> bool {
	#partial switch type in h {
	case Sphere:
		h := h.(Sphere)

		oc := r.orig - h.center
		a := linalg.length2(r.dir) // same as dot(dir, dir)
		half_b := linalg.dot(oc, r.dir)
		c := linalg.length2(oc) - h.radius * h.radius

		discriminant := half_b * half_b - a * c
		if discriminant < 0 do return false
		sqrtd := linalg.sqrt(discriminant)

		// Find the nearest root that lies in the acceptable range.
		root := (-half_b - sqrtd) / a
		if !interval_surrounds(ray_t, root) {
			root = (-half_b + sqrtd) / a
			if !interval_surrounds(ray_t, root) do return false
		}

		rec.t = root
		rec.p = ray_at(r, rec.t)
		outward_normal := (rec.p - h.center) / h.radius
		set_face_normal(rec, r, outward_normal)

		return true

	case Hittable_List:
		h := h.(Hittable_List)

		temp_rec := Hit_Record{}
		hit_anything := false
		closest_so_far := ray_t.max

		for object in h.objects {
			if hit(object, r, {ray_t.min, closest_so_far}, &temp_rec) {
				hit_anything = true
				closest_so_far = temp_rec.t

				rec.p = temp_rec.p
				rec.normal = temp_rec.normal
				rec.front_face = temp_rec.front_face
				rec.t = temp_rec.t
			}
		}

		return hit_anything
	}

	return false
}

// Sets the hit record normal vector.
// NOTE: the parameter `outward_normal` is assumed to have unit length.
set_face_normal :: proc(rec: ^Hit_Record, r: Ray, outward_normal: Vec3) {
	rec.front_face = linalg.dot(r.dir, outward_normal) < 0
	rec.normal = rec.front_face ? outward_normal : -outward_normal
}
