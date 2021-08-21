// https://www.shadertoy.com/view/4dt3zn
// https://michaelwalczyk.com/blog-ray-marching.html
// https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-ray-tracing/implementing-the-raytracing-algorithm

precision highp float;

#define REFLECTIONS 3
#define MAX_STEPS 32 
#define MAX_DIST 8.0
#define MIN_DIST 0.001

uniform vec2 u_window;
uniform float u_t;

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float boxframe(vec3 p, vec3 b, float e) {
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
        length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
        length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

float sphere(vec3 p, vec3 c, float r) {
    float d = sin(10.0 * p.x) * 0.1;
    return length(p - c) - r;
}

float map(vec3 p) {
    p = fract(p) - 0.5;
    //return boxframe(p, vec3(0.2), 0.02);
    return sphere(p, vec3(0.0), 0.2);
}

vec3 normal(vec3 p) {
    const vec2 e = vec2(MIN_DIST, 0.0);

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
        if (t == 0.0) break;

        vec3 p = ro + rd * t; // position
        vec3 sn = normal(p); // surface normal
        vec3 ld = normalize(lp - p); // light direction
        vec3 c = 0.5 * sin(3.0 * p) + 0.5;

        float amb = 0.2;
        float dif = max(0.0, dot(sn, ld));
        float spec = 2.0 * pow(max(0.0, dot(reflect(-ld, sn), -rd)), 8.0);
        float fog = smoothstep(0.0, 0.95, t / MAX_DIST);

        c *= (dif + amb + spec) * pow(0.2, float(i));
        
        col += mix(c, vec3(0.0), fog);

        rd = reflect(rd, sn);
        ro = p + rd * MIN_DIST;
    }
    return clamp(col, 0.0, 1.0);
}

void main() {
    vec2 uv = (-u_window + 2.0 * gl_FragCoord.xy) / u_window.y;

    vec3 rd = normalize(vec3(uv, 3.0));
    vec3 ro = vec3(0.0, 0.0, u_t);
    vec3 lp = ro + vec3(0, 1, -0.5);

    float cs = cos(u_t * 0.25);
    float si = sin(u_t * 0.25);
    rd.xy = mat2(cs, si, -si, cs) * rd.xy;
    rd.xz = mat2(cs, si, -si, cs) * rd.xz;

    vec3 col = render(ro, rd, lp);

    gl_FragColor = vec4(col, 1.0);
}