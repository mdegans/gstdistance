tests = [
  'test_config',
]

foreach unit : tests
  exe = executable(unit + '.vala',
    link_with: libgstdistance,
    dependencies : libgstdistance_deps,
  )
  test(unit, exe)
endforeach
