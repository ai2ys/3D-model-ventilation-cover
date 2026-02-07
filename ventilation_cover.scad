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
plate_x = 120;              // Width X direction (mm)
plate_y = 120;              // Width Y direction (mm)
plate_z = 5;                // Thickness Z direction (mm)

// Hollow conical cylinder
cyl_dia_bottom = 95;        // Outer diameter at z=0 (mm)
cyl_dia_top = 96;           // Outer diameter at z=cyl_height (mm)
cyl_wall_thickness = 2;     // Wall thickness (mm)
cyl_height = 20;            // Height Z direction (mm)
cyl_tolerance = 0.05;       // Radius reduction tolerance (mm)

// Cylinder slots (vertical)
cyl_slot_count = 6;         // Number of slots distributed radially
cyl_slot_width_bottom = 1;  // Width of each slot at bottom (z=0) (mm)
cyl_slot_width_top = 5;     // Width of each slot at top (z=height) (mm)

// Line grid stripes (in cylinder opening at z=0)
stripe_thickness = 2.4;       // Thickness Z direction (mm)
stripe_width = 1.2;           // Width of each stripe (mm)
stripe_spacing = 2;         // Distance between stripes (mm)

// Stabilizing stripes (perpendicular to grid, in Y direction)
stabilizer_count = 4;       // Number of stabilizing stripes
stabilizer_width = 1.2;     // Width of each stabilizer stripe (mm)
stabilizer_height = 2.4;    // Height Z direction (mm)
stabilizer_overlap = 0.5;   // Overlap with grid stripes in Z direction (mm)

// Rendering quality
$fn = 360;                  // Fragment number for smooth circles


// ========== MODULES ==========

// Module: Create rectangular base plate
module rectangular_plate() {
    translate([-plate_x / 2, -plate_y / 2, 0])
        cube([plate_x, plate_y, plate_z]);
}

// Module: Create slots in cylinder (radial distribution)
module cylinder_slots() {
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance;
    r_inner_bottom = r_outer_bottom - cyl_wall_thickness;
    slot_depth = r_outer_bottom + 1;  // Extend beyond outer radius to ensure full penetration
    
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
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance;
    r_outer_top = cyl_dia_top / 2 - cyl_tolerance;
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
    
    // Create stripes spanning X direction across cylinder opening
    for (x = [-(r_outer * 2) : (stripe_width + stripe_spacing) : (r_outer * 2)]) {
        // Intersection: stripe intersected with cylinder opening creates grid pattern
        intersection() {
            // Rectangular stripe in X direction
            translate([x, 0, 0])
                cube([stripe_width, r_outer * 3, stripe_thickness], center = true);
            
            // Circular cylinder boundary
            cylinder(h = stripe_thickness, r = r_outer, center = false, $fn = $fn);
        }
    }
}

// Module: Create stabilizing stripes (perpendicular to grid, in Y direction)
module stabilizing_stripes() {
    r_outer = cyl_dia_bottom / 2;
    stabilizer_spacing = (2 * r_outer) / stabilizer_count;  // Equal spacing based on cylinder opening
    stabilizer_z_start = stripe_thickness - stabilizer_overlap;  // Start where stripes end minus overlap
    
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
            cylinder(h = stabilizer_height + stripe_thickness, r = r_outer, center = false, $fn = $fn);
        }
    }
}

// Module: Create hole in plate where cylinder intersects
module cylinder_hole_in_plate() {
    r_outer_bottom = cyl_dia_bottom / 2 - cyl_tolerance;
    r_inner_bottom = r_outer_bottom - cyl_wall_thickness;
    
    // Cylindrical hole through plate (with extra height to ensure full penetration)
    translate([0, 0, -0.1])
        cylinder(h = plate_z + 0.2, r = r_inner_bottom, $fn = $fn);
}


// ========== ASSEMBLY ==========

// Base rectangular plate with hole
difference() {
    rectangular_plate();
    
    // Subtract cylinder hole from plate
    cylinder_hole_in_plate();
}

// Hollow conical cylinder (sits on plate at z=0)
hollow_cylinder();

// Stripe grid at z=0 in cylinder opening
stripe_grid();

// Stabilizing stripes perpendicular to grid
stabilizing_stripes();
