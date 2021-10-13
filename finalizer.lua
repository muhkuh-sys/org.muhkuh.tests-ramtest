local t = ...

-- Copy all additional files.
t:install{
  -- Install the CLI init script.
  ['local/muhkuh_cli_init.lua'] = '${install_base}/',

  -- Copy the complete "templates" folder.
  ['${depack_path_org.muhkuh.tests.ramtest.ramtest}/templates/'] = '${install_base}/templates/',

  ['${report_path}']                        = '${install_base}/.jonchki/'
}

t:createPackageFile()
t:createHashFile()
-- Does the output path exist?
local strOutputPath = t:replace_template('${install_base}/../../../ramtest_cli')
if t.pl.path.exists(strOutputPath)~=strOutputPath then
  t.pl.path.mkdir(strOutputPath)
end
t:createArchive('${install_base}/../../../ramtest_cli/${default_archive_name}', 'native')

return true
