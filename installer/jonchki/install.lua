local t = ...
local tResult

-- Install the complete "doc" folder.
t:install('doc/', '${build_doc}/org.muhkuh.tests.ramtest.ramtest/')

-- Install the complete "parameter" folder.
t:install('parameter/', '${install_base}/parameter/')

-- Install the complete "lua" folder.
t:install('lua/', '${install_lua_path}/')

-- Install the complete "netx" folder.
t:install('netx/', '${install_base}/netx/')

tResult = true

return tResult
