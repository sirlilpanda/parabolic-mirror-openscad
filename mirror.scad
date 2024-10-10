focus_point_x = 0.0;
focus_point_y = 0.0;
focus_point_z = 50.0;
width = 110.0;
height = 10.0;
rim = 15.0;
mounting_hole_pos_tweak = 2.0;
center_hole_width = 30.0;
rim_height = 20.0;
focus_point_debug = true;
/*
    parabola module
    
    - focus_point,    focus point as 3D-vector
    - base_area,      dimension of the base are as 2D-vector
    - resolution,     number of grid points as 2D-vector
*/
module parabola( 
    focus_point, 
    base_area, 
    resolution = [10, 10], 
    thickness  = 0   
){
    
    function parabola_point( focus_point, base_point ) =
        let ( dist_fb = norm(focus_point - base_point) )
        [
            base_point.x,
            base_point.y,
            ( dist_fb * dist_fb ) / ( 2 * (focus_point.z - base_point.z) )
        ];
    
    function flip(vec) = [ vec[3], vec[2], vec[1], vec[0] ];

    parabola_points = [
        for ( 
            y = [0 : base_area.y / resolution.y : base_area.y + 0.1], 
            x = [0 : base_area.x / resolution.x : base_area.x + 0.1] 
        )
        parabola_point( focus_point, [x,y,0] )
    ];

    base_points = [
        for ( 
            y = [0 : base_area.y / resolution.y : base_area.y + 0.1], 
            x = [0 : base_area.x / resolution.x : base_area.x + 0.1] 
        ) 
        let ( p = parabola_point( focus_point, [x,y,0] ) )
        if (thickness > 0)
            [x, y, p.z - thickness]
        else
            [x, y, 0]
    ];

    size_x = resolution.x + 1;
                
    parabola_faces = [
        for ( 
            y = [0 : resolution.y - 1], 
            x = [0 : resolution.x - 1] 
        )
        [ 
            y    * size_x + x + 1,
            y    * size_x + x, 
           (y+1) * size_x + x,
           (y+1) * size_x + x + 1
        ]
    ];

    size_ppoints = len( parabola_points );
    
    base_faces = [
        for ( 
            y = [0 : resolution.y - 1], 
            x = [0 : resolution.x - 1] 
        )
        [ y    * size_x + x     + size_ppoints, 
          y    * size_x + x + 1 + size_ppoints,
         (y+1) * size_x + x + 1 + size_ppoints,
         (y+1) * size_x + x     + size_ppoints]
    ];


    side_faces_1 = [
        for ( x = [0 : resolution.x - 1] )
        [ x, 
          x + 1, 
          x + 1 + size_ppoints, 
          x     + size_ppoints ]
    ];


    last_row = resolution.y * size_x;
        
    side_faces_2 = [
        for ( x = [0 : resolution.x - 1] )
        [ 
            last_row + x, 
            last_row + x     + size_ppoints,
            last_row + x + 1 + size_ppoints, 
            last_row + x + 1
        ]
    ];

    side_faces_3 = [ // good
        for ( y = [0 : resolution.y - 1] )
        [ 
            y      * size_x, 
            y      * size_x + size_ppoints, 
           (y + 1) * size_x + size_ppoints, 
           (y + 1) * size_x
        ]
    ];

    last_col = resolution.x;

    side_faces_4 = [ // good
        for ( y = [0 : resolution.y - 1] )
        [ 
            last_col +  y      * size_x, 
            last_col + (y + 1) * size_x, 
            last_col + (y + 1) * size_x + size_ppoints, 
            last_col +  y      * size_x + size_ppoints
        ]
    ];
    // translate(parabola_point( focus_point, [x,y,0] ) )
    polyhedron(
        points = concat( parabola_points, base_points ), 
        faces  = concat( parabola_faces, 
                         base_faces, 
                         side_faces_2,
                         side_faces_1,
                         side_faces_3,
                         side_faces_4
                         )
    );
    
}


module mirror(
    width, 
    height, 
    focus_point = [0, 0, 500], 
    draw_focus_point = true, 
    center_hole_width = 30, 
    rim = 1,
    rim_height = height,
    base_thickness=4, 
    number_mounting_holes = 3, 
    mounting_hole_size = 6,
    mounting_hole_pos_tweak = 0,
    holding_holes_amount = 3,
    holding_holes_diameter = width/2,
    ) {
    thickness = 100;

    real_focus_point = focus_point + [width, width, 0];

        if (draw_focus_point){
            color("red", 1)
            translate([-width, -width, 0])
            translate(real_focus_point)
            sphere(5);
        }

    rot_amount = 360/number_mounting_holes;

    difference(){
        difference() {
            difference() {
                union() { // rim
                    difference(){
                        color("blue", 1)
                        translate([0, 0, -0.001]) cylinder(r=width/2+rim, h=rim_height+0.01);
                        translate([0, 0, -0.01]) cylinder(r=width/2, h=rim_height*2);
                    }
                    // filler underneath
                    cylinder(r=width/2, h=rim+0.01);

                    // // mirror
                    translate([0, 0, rim]) 
                    difference() {
                        // mirror shape
                        translate([0, 0, -0.001]) cylinder(r=width/2, h=height+real_focus_point.z*real_focus_point.z-real_focus_point.z/2);
                        // mirror suface
                        translate([-width, -width, real_focus_point.z*real_focus_point.z-real_focus_point.z/2]) {
                            parabola( 
                                focus_point = real_focus_point,
                                base_area   = [width*2,width * 2], // needs to be focus point, x, y * 2 
                                thickness   = real_focus_point.z*real_focus_point.z,
                                resolution = [100, 100]
                            );
                        }; 
                    }    
                }
                // middle hole
                translate([0, 0, -rim-1]) cylinder(d=center_hole_width, h=real_focus_point.z*real_focus_point.z);
            }
            // mounting holes
            for (i=[1:number_mounting_holes]) {
                color("blue", 1)
                rotate(rot_amount*i, [0, 0, 1])
                translate([0, (width+rim)/2+mounting_hole_pos_tweak, -rim/2])
                cylinder(d=mounting_hole_size, real_focus_point.z*3);
            }
        }
    // cuts off everything above to keep the model clean
    color("gold", 1)
    translate([-width, -width, height])
    scale([1, 1, real_focus_point.z*real_focus_point.z]) 
        cube(width*2);
    }
}




mirror(
    width, 
    height, 
    rim=rim, 
    rim_height = rim_height,
    draw_focus_point = focus_point_debug,
    center_hole_width = center_hole_width, 
    focus_point = [focus_point_x, focus_point_y, focus_point_z],
    mounting_hole_pos_tweak = mounting_hole_pos_tweak
    );

// width = 75;
// height = 20;
// center_hole_width = 30;
// focus_point = [90, 90, 100];




// difference() {
    // difference() {
    // };
    // translate([0, 0, -0.01]) cylinder(r=30, h=height+0.001);
// }


//  union()       {cube(12, center=true); sphere(8);} // cube or  sphere
//  difference()  {cube(12, center=true); sphere(8);} // cube and not sphere
//  difference()  {sphere(8); cube(12, center=true);} // sphere and not cube
//  intersection(){
//     translate([2, 0, 0]) {   
//     cube(12, center=true); 
//     };
//     sphere(8);
// } // cube and sphere

