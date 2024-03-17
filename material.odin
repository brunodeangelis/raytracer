package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"


Material_Type :: enum {
	LAMBERTIAN,
	METAL,
	DIELECTRIC,
}

Material :: struct {
	type:   Material_Type,
	albedo: Color,
	fuzz:   f64, // Fuzziness/Roughness
	ir:     f64, // Index of Refraction
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
	case .DIELECTRIC:
		return material_scatter_dielectric(material, r_in, rec, attenuation, scattered)
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

material_scatter_dielectric :: proc(
	material: ^Material,
	r_in: Ray,
	rec: Hit_Record,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	refraction_ratio := rec.front_face ? (1 / material.ir) : material.ir

	unit_direction := linalg.normalize(r_in.dir)
	cos_theta := min(linalg.dot(-unit_direction, rec.normal), 1.0)
	sin_theta := linalg.sqrt(1 - cos_theta * cos_theta)

	cannot_refract := refraction_ratio * sin_theta > 1
	direction: Vec3

	if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand.float64() {
		direction = linalg.reflect(unit_direction, rec.normal)
	} else {
		direction = refract(unit_direction, rec.normal, refraction_ratio)
	}

	scattered^ = Ray{rec.p, direction}
	attenuation^ = {1, 1, 1} // Absorbs nothing.
	return true
}

reflectance :: proc(cosine, ref_idx: f64) -> f64 {
	// Use Schlick's approximation for reflectance.
	r0 := (1 - ref_idx) / (1 + ref_idx)
	r0 *= r0
	return r0 + (1 - r0) * linalg.pow(1 - cosine, 5)
}
