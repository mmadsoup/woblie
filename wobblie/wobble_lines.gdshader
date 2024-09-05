shader_type canvas_item;

uniform float normal_offset : hint_range(0, 1, 0.01) = 1.0;
uniform float time_influence : hint_range(0, 50) = 5;//3
uniform float y_div : hint_range(0, 10, .1) = 7;//2.87

void vertex() {
    VERTEX.x += sin(VERTEX.y * y_div + round(TIME * time_influence)) * normal_offset;
    VERTEX.y += sin(VERTEX.x * y_div + round(TIME * time_influence)) * normal_offset;
}