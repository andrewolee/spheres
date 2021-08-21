// https://www.shadertoy.com/view/4dt3zn
// https://michaelwalczyk.com/blog-ray-marching.html

precision highp float;

#define SPHERES 3
#define REFLECTIONS 2
#define MAX_STEPS 32
#define MAX_DIST 1000.0
#define MIN_DIST 0.001

uniform vec2 u_window;
uniform vec3 u_pos[SPHERES];

float sphere(vec3 p, vec3 c, float r) {
    return length(p - c) - r;
}

float smoothmin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float map(vec3 p) {
    float d = MAX_DIST;
    for (int i = 0; i < SPHERES; i++) {
        d = smoothmin(d, sphere(p, u_pos[i], 1.0), 0.5);
    }
    return d;
}

vec3 normal(vec3 p) {
    const vec2 e = vec2(0.0001, 0.0);

    vec3 normal;
    normal.x = map(p + e.xyy) - map(p - e.xyy);
    normal.y = map(p + e.yxy) - map(p - e.yxy);
    normal.z = map(p + e.yyx) - map(p - e.yyx);

    return normalize(normal);
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = map(ro + rd * t);
        if (d < MIN_DIST) {
            return t;
        }
        if (d > MAX_DIST) break;
        t += d;
    }
    return 0.0;
}

vec3 render(vec3 ro, vec3 rd, vec3 lp) {
    vec3 col = vec3(0.0);
    for (int i = 0; i < REFLECTIONS; i++) {
        float t = raymarch(ro, rd);
        if (t == 0.0) {
            break;
        }
        vec3 p = ro + rd * t; // position
        vec3 sn = normal(p); // surface normal
        vec3 ld = normalize(lp - p); // light direction
        vec3 c = clamp(p, 0.2, 0.7); // color

        float amb = 0.2;
        float dif = max(0.0, dot(sn, ld));
        float spec = pow(max(0.0, dot(reflect(-ld, sn), -rd)), 8.0);
        
        col += (dif + amb + spec) * c * pow(0.8, float(i));
    }
    return col;
}

void main() {
    vec2 uv = (-u_window + 2.0 * gl_FragCoord.xy) / u_window.y;

    vec3 lp = vec3(2.0, 1.0, -2.0);

    vec3 ro = vec3(0.0, 0.0, -5.0);
    vec3 rd = normalize(vec3(uv, 1.0));

    vec3 col = render(ro, rd, lp);

    gl_FragColor = vec4(col, 1.0);
}