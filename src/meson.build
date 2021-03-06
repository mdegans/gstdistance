cc = meson.get_compiler('c')

libgstdistance_sources = [
  'cb_distancing.c',
  'meta.pb-c.c',
  'nvdistance.vala',
  'distance.vala',
  'plugin.vala',
]

libgstdistance_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gstreamer-1.0'),
  dependency('gstreamer-base-1.0'),
  # this is needed for Math
  cc.find_library('m', required : false),
]

# make the library
# the vala_header is a normal .h generated by valac
# the .vapi is for use in other vala projects
# the .gir is for g-ir-compiler for other language bindings
# the .typelib is a compiled typelib for other languages
plugins_install_dir = join_paths(get_option('libdir'), 'gstreamer-1.0')
ver_arr = meson.project_version().split('.')
libgstdistance_name_plus_ver = meson.project_name() + '-' + ver_arr[0]+ '.' + ver_arr[1]
libgstdistance_vapi = libgstdistance_name_plus_ver + '.vapi'
libgstdistance_gir = libgstdistance_name_plus_ver + '.gir'
libgstdistance_typelib = libgstdistance_name_plus_ver + '.typelib'
libgstdistance = shared_library(meson.project_name(), libgstdistance_sources,
  vala_args: '--target-glib=2.58',
  vala_header: meson.project_name() + '.h',
  vala_vapi: libgstdistance_vapi,
  vala_gir: libgstdistance_gir,
  dependencies: libgstdistance_deps,
  include_directories: libgstdistance_inc,
  link_with: meta_lib,
  install: true,
  install_dir: [plugins_install_dir, true, true, true],
)

# # make the typelib bindings for other languages from the .gir
# lols the documentation example has been broken for 3 years
# so this nested ugliness is necessary
# https://github.com/mesonbuild/meson/issues/2296
g_ir_compiler = find_program('g-ir-compiler')
custom_target(meson.project_name() + ' typelib',
  command: [
    g_ir_compiler,
    '--shared-library',
    libgstdistance.full_path(),
    '--output',
    '@OUTPUT@',
    join_paths(
      meson.current_build_dir(),
      libgstdistance_gir,
    ),
  ],
  output: libgstdistance_typelib,
  depends: libgstdistance,
  install: true,
  install_dir: join_paths(get_option('libdir'), 'girepository-1.0')
)

pkg_mod = import('pkgconfig')
pkg_mod.generate(
  description: 'GStreamer social distancing plugin.',
  libraries: libgstdistance,
  version: meson.project_version(),
  name: meson.project_name(),
)
