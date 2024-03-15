package main


Ray :: struct {
	orig: Point3,
	dir:  Vec3,
}

ray_at :: proc(r: Ray, t: f64) -> Point3 {
	return r.orig + t * r.dir
}
