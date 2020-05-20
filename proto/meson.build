protoc = find_program('protoc-c')
libprotobuf_c = dependency('libprotobuf-c')

proto_name = 'meta'

infile = proto_name + '.proto'
output = [proto_name + '.pb-c.c', proto_name + '.pb-c.h']

# there is probably an easier way to do this
# meson is ... annoying, at times
# if anybody can clean this disaster up,
# I'd be much obliged.
# I am probably doing this "wrong".
# and the symlinks are hacky.
meta = custom_target(proto_name,
  input: infile,
  output: output,
  command: [
    protoc,
    '--proto_path', meson.current_source_dir(),
    '--c_out', meson.current_build_dir(),
    infile,
  ],
  install_dir: proto_name,
  install: true,
)

meta_lib = static_library('distancing' + proto_name, meta,
  dependency: libprotobuf_c,
  install: true,
)