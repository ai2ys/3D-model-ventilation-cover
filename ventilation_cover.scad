/**
 * Model created via prompting with Copilot
 * Givinng instructions on how to:
 * - Structure the code with parameters and methods
 * - Create a rectangular plate with a hole for a conical cylinder
 * - Create a hollow conical cylinder with specified dimensions and wall thickness
 * - Create keil-förmige slots in the cylinder, distributed radially
 * - Create a line grid of stripes in the cylinder opening at z=0
 * - Create stabilizing stripes perpendicular to the grid, in the Y direction
 * - Ensure all components are properly aligned and assembled
 */ 
// The model is designed in OpenSCAD and includes parameters for dimensions and rendering quality. 
// ========== PARAMETERS ==========
// Rectangular plate
plate_x = 150;              // Width X direction (mm)
plate_y = 150;              // Width Y direction (mm)
plate_z = 2.8;                // Thickness Z direction (mm)
plate_fillet = 2;            // Radius for 2D corner fillet on plate (mm)
plate_edge_fillet = 0.8;     // Radius for vertical edge fillet (minkowski). Set 0 to disable (mm)
plate_rim_height = 2.0;      // Height of rim above plate in +Z (mm)
plate_rim_width = 3.0;       // Rim wall width (inwards from edge) (mm)

// Hollow conical cylinder
cyl_dia_bottom = 95;        // Outer diameter at z=0 (mm)
cyl_dia_top = 96;           // Outer diameter at z=cyl_height (mm) 96mm inner diameter of tube to fit in 
cyl_wall_thickness = 2;     // Wall thickness (mm)
cyl_height = 20;            // Height Z direction (mm)
cyl_tolerance_bottom = 0;    // Radius reduction tolerance at z=0 (mm)
cyl_tolerance_top = -1.5;       // Radius reduction tolerance at z=cyl_height (mm)

// Cylinder slots (vertical)
cyl_slot_count = 7;         // Number of slots distributed radially
cyl_slot_width_bottom = 0.5;  // Width of each slot at bottom (z=0) (mm)
cyl_slot_width_top = 4;     // Width of each slot at top (z=height) (mm)

// Line grid stripes (in cylinder opening at z=0)
stripe_height = 2.4;       // Thickness Z direction (mm)
stripe_width = 0.8;           // Width of each stripe (mm)
stripe_spacing = 1.6;         // Distance between stripes (mm)
stripe_shear_angle = 25;    // Shear angle in Y direction (degrees)

// Stabilizing stripes (perpendicular to grid, in Y direction)
stabilizer_count = 3;       // Number of stabilizing stripes
stabilizer_width = 1.2;     // Width of each stabilizer stripe (mm)
stabilizer_height = 2.0;    // Height Z direction (mm)
stabilizer_overlap = 0.0;   // Overlap with grid stripes in Z direction (mm)

// Rendering quality
$fn = 360;                  // Fragment number for smooth circles


// ========== MODULES ==========

// Module: Plate 2D outline with rounded corners (centered at origin)
module plate_outline_2d() {
    base_w = max(0, plate_x - 2*plate_fillet);
    base_h = max(0, plate_y - 2*plate_fillet);
    offset(r = plate_fillet)
        square([base_w, base_h], center = true);
}

// Module: Create rectangular base plate
module rectangular_plate() {
    linear_extrude(height = plate_z)
        plate_outline_2d();
}

// Module: Create rim on top of plate (positive Z)
module plate_rim() {
    if (plate_rim_height > 0 && plate_rim_width > 0) {
        translate([0, 0, plate_z])
            linear_extrude(height = plate_rim_height)
                difference() {
                    plate_outline_2d();
                    offset(delta = -plate_rim_width)
                        plate_outline_2d();
                }
    }
}

// Module: Create slots in cylinder (radial distribution)
module cylinder_slots() {
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance_bottom;
    r_outer_top = cyl_dia_top / 2 - cyl_tolerance_top;
    slot_depth = max(r_outer_bottom, r_outer_top) + 1;  // Extend beyond outer radius to ensure full penetration
    
    // Distribute slots evenly around cylinder circumference
    for (i = [0 : cyl_slot_count - 1]) {
        angle = (360 / cyl_slot_count) * i;
        rotate([0, 0, angle]) {
            // Keil-förmiger Slot: unten schmaler, oben breiter
            hull() {
                // Bottom rectangle (narrow)
                translate([0, -cyl_slot_width_bottom / 2, -0.1])
                    cube([slot_depth, cyl_slot_width_bottom, 0.2]);
                
                // Top rectangle (wide)
                translate([0, -cyl_slot_width_top / 2, cyl_height])
                    cube([slot_depth, cyl_slot_width_top, 0.2]);
            }
        }
    }
}

// Module: Create hollow conical cylinder
module hollow_cylinder() {
    // Calculate radii
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance_bottom;
    r_outer_top = cyl_dia_top / 2 - cyl_tolerance_top;
    r_inner_bottom = r_outer_bottom - cyl_wall_thickness;
    r_inner_top = r_outer_top - cyl_wall_thickness;
    
    difference() {
        // Outer conical surface
        cylinder(h = cyl_height, r1 = r_outer_bottom, r2 = r_outer_top, $fn = $fn);
        
        // Inner conical surface (subtracted for hollow)
        translate([0, 0, -0.1])
            cylinder(h = cyl_height + 0.2, r1 = r_inner_bottom, r2 = r_inner_top, $fn = $fn);
        
        // Vertical slots
        cylinder_slots();
    }
}

// Module: Create line grid stripes in cylinder opening
module stripe_grid() {
    r_outer = cyl_dia_bottom / 2;
    // Convert angle in degrees to radians for tan()
    shear_offset = stripe_height * tan(stripe_shear_angle);  // X-offset from bottom to top
    echo("Shear offset for stripes (X): ", shear_offset);
    echo("Stripe shear tan angle (deg): ", tan(stripe_shear_angle));
    
    // Create stripes spanning X direction across cylinder opening
    for (x = [-(r_outer * 2) : (stripe_width + stripe_spacing) : (r_outer * 2)]) {
        // Intersection: stripe intersected with cylinder opening creates grid pattern
        intersection() {
            // Parallelogram stripe: use hull of two thin extruded polygons
            hull() {
                // Bottom thin extruded polygon at z=0
                translate([x, 0, 0])
                    linear_extrude(height = 0.01)
                        polygon([
                            [-stripe_width/2, -r_outer],
                            [ stripe_width/2, -r_outer],
                            [ stripe_width/2,  r_outer],
                            [-stripe_width/2,  r_outer]
                        ]);

                // Top thin extruded polygon at z=stripe_height with X offset (shear)
                translate([x + shear_offset, 0, stripe_height])
                    linear_extrude(height = 0.01)
                        polygon([
                            [-stripe_width/2, -r_outer],
                            [ stripe_width/2, -r_outer],
                            [ stripe_width/2,  r_outer],
                            [-stripe_width/2,  r_outer]
                        ]);
            }

            // Circular cylinder boundary
            cylinder(h = stripe_height, r = r_outer, center = false, $fn = $fn);
        }
    }
}

// Module: Create stabilizing stripes (perpendicular to grid, in Y direction)
module stabilizing_stripes() {
    r_outer = cyl_dia_bottom / 2;
    stabilizer_spacing = (2 * r_outer) / stabilizer_count;  // Equal spacing based on cylinder opening
    stabilizer_z_start = stripe_height - stabilizer_overlap;  // Start where stripes end minus overlap
    
    // Distribute stabilizers symmetrically around center
    for (i = [0 : stabilizer_count - 1]) {
        // Calculate symmetric position: center at 0, distribute left and right
        offset = (i - (stabilizer_count - 1) / 2) * stabilizer_spacing;
        
        // Intersection: stabilizer stripe intersected with cylinder opening
        intersection() {
            // Rectangular stripe in Y direction (perpendicular to grid)
            translate([0, offset, stabilizer_z_start + stabilizer_height / 2])
                cube([r_outer * 3, stabilizer_width, stabilizer_height], center = true);
            
            // Circular cylinder boundary
            cylinder(h = stabilizer_height + stripe_height, r = r_outer, center = false, $fn = $fn);
        }
    }
}

// Module: Create hole in plate where cylinder intersects
module cylinder_hole_in_plate() {
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance_bottom;
    r_inner_bottom = r_outer_bottom - cyl_wall_thickness;
    
    // Cylindrical hole through plate (with extra height to ensure full penetration)
    translate([0, 0, -0.1])
        cylinder(h = plate_z + 0.2, r = r_inner_bottom, $fn = $fn);
}


// ========== ASSEMBLY ==========

// Base rectangular plate with hole (and optional rim)
difference() {
    union() {
        rectangular_plate();
        plate_rim();
    }
    
    // Subtract cylinder hole from plate
    cylinder_hole_in_plate();
}

// Hollow conical cylinder (sits on plate at z=0)
hollow_cylinder();

// Stripe grid at z=0 in cylinder opening
stripe_grid();

// Stabilizing stripes perpendicular to grid
stabilizing_stripes();
