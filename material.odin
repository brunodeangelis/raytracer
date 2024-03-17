package main

import "core:fmt"
import "core:math/linalg"


Material_Type :: enum {
	LAMBERTIAN,
	METAL,
}

Material :: struct {
	type:   Material_Type,
	albedo: Color,
	fuzz:   f64,
}

material_scatter :: proc(
	material: ^Material,
	r_in: Ray,
	rec: Hit_Record,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	switch material.type {
	case .LAMBERTIAN:
		return material_scatter_lambertian(material, r_in, rec, attenuation, scattered)
	case .METAL:
		return material_scatter_metal(material, r_in, rec, attenuation, scattered)
	}
	return false
}

material_scatter_lambertian :: proc(
	material: ^Material,
	r_in: Ray,
	rec: Hit_Record,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	scatter_direction := rec.normal + random_unit_vector()

	if is_near_zero(scatter_direction) {
		scatter_direction = rec.normal
	}

	scattered^ = Ray{rec.p, scatter_direction}
	attenuation^ = material.albedo
	return true
}

material_scatter_metal :: proc(
	material: ^Material,
	r_in: Ray,
	rec: Hit_Record,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	reflected := linalg.reflect(linalg.normalize(r_in.dir), rec.normal)
	if material.fuzz >= 1 do material.fuzz = 1
	scattered^ = Ray{rec.p, reflected + material.fuzz * random_unit_vector()}
	attenuation^ = material.albedo
	return linalg.dot(scattered.dir, rec.normal) > 0
}
