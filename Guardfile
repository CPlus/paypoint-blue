guard :minitest, all_after_pass: true do
  watch(%r{^test/test_(.*)\.rb$})
  watch(%r{^lib/((?:.*/)?[^/]+)\.rb$}) do |m|
    test_file = "test/test_#{m[1].tr('/', '_')}.rb"
    File.exists?(test_file) ? test_file : 'test'
  end
  watch(%r{^test/minitest_helper\.rb$}) { 'test' }
end
