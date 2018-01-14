local t = ...

-- Copy additional files.
local atCopyList = {
  ['${report_path}'] = '${install_base}/.jonchki/',
  ['${report_xslt}'] = '${install_base}/.jonchki/'
}
for strSrc, strDst in pairs(atCopyList) do
  t:install(strSrc, strDst)
end

return true
