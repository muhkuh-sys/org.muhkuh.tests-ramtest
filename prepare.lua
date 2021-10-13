local t = ...
local pl = t.pl
local tLog = t.tLog

-- Get the project version from the setup.xml .
local tXml = pl.xml.parse('../../setup.xml', true)
local atElem = tXml:get_elements_with_name('project_version')
if atElem==nil then
  error('Failed to get the project_version element.')
elseif #atElem==0 then
  error('No project_version element found.')
elseif #atElem>1 then
  error('More than one project_version element found.')
end
local strProjectVersion = atElem[1]:get_text()

local strRepositoryPathAbs = pl.path.abspath('../..')
local strGitId = t:getGitDescription(strRepositoryPathAbs)
local strProjectVersionVcs, strProjectVersionVcsLong = t:parseGitID(strGitId)

-- Read the test template.
local strTestcaseTemplate, strErrorRead = pl.utils.readfile('../../ramtest_cli.xml', false)
if strTestcaseTemplate==nil then
  tLog.error('Failed to read "%s": %s', strSourceFile, tostring(strErrorRead))
  error('Failed to read the source file.')
else
  local atReplace = {
    PROJECT_VERSION = strProjectVersion,
    PROJECT_VERSION_VCS = strProjectVersionVcs,
    PROJECT_VERSION_VCS_LONG = strProjectVersionVcsLong
  }
  local strTestcaseXml = string.gsub(strTestcaseTemplate, '%$%{([a-zA-Z0-9_]+)%}', atReplace)

  -- Write the testcase XML.
  local tResultWrite, strErrorWrite = pl.utils.writefile('ramtest_cli.xml', strTestcaseXml, false)
  if tResultWrite~=true then
    tLog.error('Failed to write "%s": %s', strErrorWrite, tostring(strErrorWrite))
    error('Failed to write the destination file.')
  end
end

return true
