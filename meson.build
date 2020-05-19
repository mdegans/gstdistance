project('gstdistance', ['c', 'vala'],
  version: run_command(
    'head', '-n', '1', files('VERSION'),
  ).stdout().strip(),
  meson_version: '>= 0.47.0',
)

libgstdistance_inc = include_directories('include')

subdir('src')
# subdir('test')
