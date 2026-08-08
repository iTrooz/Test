#!/bin/bash
# Disable all GL extensions not required for OpenGL 3.3 core profile.
# Applied to Mesa source before building.

set -e

MESA_SRC="${1:-.}"

###############################################################################
# 1. extensions.c – keep only the always-on extensions needed for GL 3.3
###############################################################################
cat > /tmp/ext_patch.py << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    src = f.read()

# Extensions required for GL 3.3 (from the always-on list in extensions.c):
keep_always_on = {
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

# Match lines like: extensions->SomeExt = GL_TRUE;
pat = re.compile(r'(\s*extensions->(\w+)\s*=\s*GL_TRUE;)')

def repl(m):
    indent, name = m.group(1), m.group(2)
    if name in keep_always_on:
        return indent
    return indent.replace('extensions->', '// extensions->')

new = pat.sub(repl, src)

# Also disable MESA_*, ATI_*, NV_*, OES_* extras (non-3.3)
for name in ['MESA_pack_invert', 'MESA_window_pos', 'MESA_framebuffer_flip_y',
             'ATI_fragment_shader', 'ATI_texture_env_combine3',
             'NV_copy_image', 'NV_fog_distance', 'NV_texture_env_combine4',
             'NV_texture_rectangle',
             'OES_EGL_image', 'OES_EGL_image_external', 'OES_draw_texture']:
    new = new.replace(f'extensions->{name} = GL_TRUE;', f'// extensions->{name} = GL_TRUE; (disabled for GL3.3)')

# Disable other non-3.3 ARB/EXT lines
for name in ['ARB_ES2_compatibility', 'ARB_explicit_uniform_location',
             'ARB_fragment_program', 'ARB_internalformat_query',
             'ARB_internalformat_query2', 'ARB_occlusion_query',
             'ARB_vertex_program',
             'EXT_EGL_image_storage', 'EXT_gpu_program_parameters',
             'EXT_shadow_samplers', 'EXT_texture_env_dot3']:
    new = new.replace(f'extensions->{name} = GL_TRUE;', f'// extensions->{name} = GL_TRUE; (disabled for GL3.3)')

with open(path, 'w') as f:
    f.write(new)
print(f"Patched {path}")
PYEOF
python3 /tmp/ext_patch.py "$MESA_SRC/src/mesa/main/extensions.c"

###############################################################################
# 2. st_extensions.c – disable EXT_CAP for non-3.3 extensions
###############################################################################
cat > /tmp/stext_patch.py << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

# Extensions REQUIRED for GL 3.3 that use EXT_CAP
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

out = []
for line in lines:
    m = re.match(r'\s*EXT_CAP\((\w+),', line)
    if m:
        ext_name = m.group(1)
        if ext_name not in keep_ext_cap:
            out.append('   /* disabled for GL3.3: ' + line.strip() + ' */\n')
            continue
    out.append(line)

with open(path, 'w') as f:
    f.writelines(out)
print(f"Patched {path}")
PYEOF
python3 /tmp/stext_patch.py "$MESA_SRC/src/mesa/state_tracker/st_extensions.c"

###############################################################################
# 3. st_extensions.c – disable GLSLVersion-gated non-3.3 extensions
###############################################################################
cat > /tmp/stext_glsl_patch.py << 'PYEOF'
import sys

path = sys.argv[1]
with open(path) as f:
    src = f.read()

# Extensions gated by GLSLVersion that are NOT required for GL 3.3
# (ARB_shader_bit_encoding at line 1299 IS required – keep it)
disable_glsl_exts = [
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
]

for ext in disable_glsl_exts:
    # Comment out lines like: extensions->ARB_foo = GL_TRUE;
    src = src.replace(
        f'      extensions->{ext} = GL_TRUE;',
        f'      /* disabled for GL3.3: extensions->{ext} = GL_TRUE; */'
    )
    src = src.replace(
        f'       extensions->{ext} = GL_TRUE;',
        f'       /* disabled for GL3.3: extensions->{ext} = GL_TRUE; */'
    )

with open(path, 'w') as f:
    f.write(src)
print(f"Patched GLSL-gated extensions in {path}")
PYEOF
python3 /tmp/stext_glsl_patch.py "$MESA_SRC/src/mesa/state_tracker/st_extensions.c"

echo "Done patching Mesa for GL 3.3 only extensions."
