#!/bin/bash
# Disable always-on GL extensions not required for OpenGL 3.3 core profile.
# Only patches extensions.c (safe). st_extensions.c is left alone because
# its extension enables are embedded in complex multi-line conditionals.

set -e
MESA_SRC="${1:-.}"

python3 - "$MESA_SRC/src/mesa/main/extensions.c" << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
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
        out.append(f'{indent}/* disabled for GL3.3 */\n')
    else:
        out.append(line)

with open(path, 'w') as f:
    f.writelines(out)
print(f"Patched {path}")
PYEOF

echo "Done."
