#!/bin/bash
# Disable all GL extensions not required for OpenGL 3.3 core profile.

set -e
MESA_SRC="${1:-.}"

python3 - "$MESA_SRC/src/mesa/main/extensions.c" "$MESA_SRC/src/mesa/state_tracker/st_extensions.c" << 'PYEOF'
import re, sys

extensions_path = sys.argv[1]
st_extensions_path = sys.argv[2]

###############################################################################
# 1. extensions.c – keep only the always-on extensions needed for GL 3.3
###############################################################################
with open(extensions_path) as f:
    lines = f.readlines()

keep = {
    'dummy_true',
    'ARB_draw_elements_base_vertex',
    'ARB_explicit_attrib_location',
    'ARB_fragment_coord_conventions',
    'ARB_fragment_shader',
    'ARB_half_float_vertex',
    'ARB_map_buffer_range',
    'ARB_sync',
    'ARB_vertex_shader',
    'EXT_provoking_vertex',
    'EXT_stencil_two_side',
}

out = []
for line in lines:
    m = re.match(r'(\s*)extensions->(\w+)\s*=\s*GL_TRUE;', line)
    if m and m.group(2) not in keep:
        indent = m.group(1)
        ext = m.group(2)
        out.append(f'{indent}/* disabled for GL3.3: extensions->{ext} = GL_TRUE; */\n')
    else:
        out.append(line)

with open(extensions_path, 'w') as f:
    f.writelines(out)
print(f"Patched {extensions_path}")

###############################################################################
# 2. st_extensions.c – disable EXT_CAP for non-3.3, disable single-line
#    GLSL-gated extension enables for non-3.3
###############################################################################
with open(st_extensions_path) as f:
    lines = f.readlines()

keep_ext_cap = {
    'ARB_depth_clamp',
    'ARB_framebuffer_object',
    'ARB_instanced_arrays',
    'ARB_seamless_cube_map',
    'ARB_shader_texture_lod',
    'ARB_shadow',
    'ARB_texture_multisample',
    'ARB_texture_non_power_of_two',
    'ARB_timer_query',
    'EXT_blend_equation_separate',
    'EXT_draw_buffers2',
    'EXT_texture_array',
    'EXT_texture_swizzle',
    'EXT_transform_feedback',
    'NV_conditional_render',
    'NV_primitive_restart',
}

disable_exts = {
    'ARB_gpu_shader5',
    'ARB_shader_precision',
    'AMD_vertex_shader_layer',
    'EXT_gpu_shader4',
    'EXT_texture_buffer_object',
    'ARB_enhanced_layouts',
    'ARB_conservative_depth',
    'ARB_shading_language_packing',
    'ARB_shading_language_420pack',
    'ARB_texture_query_levels',
    'ARB_arrays_of_arrays',
    'EXT_shader_integer_mix',
    'MESA_shader_integer_functions',
    'OVR_multiview',
    'OVR_multiview2',
    'INTEL_shader_integer_functions2',
    'ARB_tessellation_shader',
    'ARB_compute_shader',
    'ARB_gpu_shader_fp64',
    'ARB_vertex_attrib_64bit',
    'ARB_ES3_compatibility',
    'ARB_ES3_1_compatibility',
    'ARB_ES3_2_compatibility',
    'ARB_viewport_array',
    'ARB_fragment_layer_viewport',
    'ARB_shader_atomic_counters',
    'ARB_shader_atomic_counter_ops',
    'ARB_shader_storage_buffer_object',
    'ARB_shader_image_load_store',
    'ARB_shader_image_size',
}

out = []
for line in lines:
    # EXT_CAP lines
    m = re.match(r'(\s*)EXT_CAP\((\w+),', line)
    if m:
        ext_name = m.group(2)
        if ext_name not in keep_ext_cap:
            indent = m.group(1)
            out.append(f'{indent}/* disabled for GL3.3: {line.strip()} */\n')
            continue

    # Single-line extension enables: extensions->FOO = GL_TRUE;
    m2 = re.match(r'(\s*)extensions->(\w+)\s*=\s*GL_TRUE;', line)
    if m2 and m2.group(2) in disable_exts:
        indent = m2.group(1)
        ext = m2.group(2)
        out.append(f'{indent}/* disabled for GL3.3: extensions->{ext} = GL_TRUE; */\n')
        continue

    out.append(line)

with open(st_extensions_path, 'w') as f:
    f.writelines(out)
print(f"Patched {st_extensions_path}")
PYEOF

echo "Done patching Mesa for GL 3.3 only extensions."
