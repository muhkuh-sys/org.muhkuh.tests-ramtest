#! /usr/bin/python2.7

import os
import subprocess
import site
import sys
import xml.etree.ElementTree

# --------------------------------------------------------------------------
# -
# - Configuration
# -

# Get the project folder. This is the folder of this script.
strCfg_projectFolder = os.path.dirname(os.path.realpath(__file__))

# This is the complete path to the testbench folder. The installation will be
# written there.
strCfg_testbenchFolder = os.path.join(
    strCfg_projectFolder,
    'targets',
    'testbench'
)

# This is the complete path to the project's setup.xml . The version number
# will be extracted from this file.
strCfg_setupFile = os.path.join(strCfg_projectFolder, 'setup.xml')

# Where is the jonchkihere module?
strCfg_jonchkiHerePath = os.path.join(
    strCfg_projectFolder,
    'installer',
    'jonchki',
    'jonchkihere'
)
# This is the Jonchki version to use.
strCfg_jonchkiVersion = '0.0.2.1'
# Look in this folder for Jonchki archives before downloading them.
strCfg_jonchkiLocalArchives = os.path.join(
    strCfg_projectFolder,
    'jonchki',
    'local_archives'
)
# The target folder for the jonchki installation. A subfolder named
# "jonchki-VERSION" will be created there. "VERSION" will be replaced with
# the version number from strCfg_jonchkiVersion.
strCfg_jonchkiInstallationFolder = os.path.join(
    strCfg_projectFolder,
    'targets'
)

strCfg_jonchkiSystemConfiguration = os.path.join(
    strCfg_projectFolder,
    'installer',
    'jonchki',
    'testbench',
    'jonchkisys.cfg'
)
strCfg_jonchkiProjectConfiguration = os.path.join(
    strCfg_projectFolder,
    'installer',
    'jonchki',
    'testbench',
    'jonchkicfg.xml'
)
# This is the template for the artifact file. It has 2 "%s" for the
# project version.
strCfg_artifactTemplate = os.path.join(
    strCfg_projectFolder,
    'targets',
    'jonchki',
    'repository',
    'org',
    'muhkuh',
    'tests',
    'ramtest',
    '%s',
    'lua5.1-ramtest-%s.xml'
)

# -
# --------------------------------------------------------------------------

# Add the module path for jonchkihere.
site.addsitedir(strCfg_jonchkiHerePath)
import jonchkihere

# Create the testbench folder if it does not exist yet.
if os.path.exists(strCfg_testbenchFolder) is not True:
    os.makedirs(strCfg_testbenchFolder)

# Get the project version.
tSetupXml = xml.etree.ElementTree.parse(strCfg_setupFile)
tNodeCurrentVersion = tSetupXml.find('project_version')
if tNodeCurrentVersion is None:
    raise Exception(
        'The project configuration "%s" has no project version.' %
        strCfg_setupFile
    )
strCurrentVersion = tNodeCurrentVersion.text
if (strCurrentVersion is None) or (strCurrentVersion == ''):
    raise Exception(
        'Failed to extract the project version from "%s".' %
        strCfg_setupFile
    )

# Get the path to the artifact configuration.
strArtifactCfg = strCfg_artifactTemplate % (
    strCurrentVersion,
    strCurrentVersion
)
if os.path.exists(strArtifactCfg) is not True:
    raise Exception(
        'The artifact configuration "%s" does not exist. '
        'Try to build the project first.' % strArtifactCfg
    )

# Install jonchki.
jonchkihere.install(
    strCfg_jonchkiVersion,
    strCfg_jonchkiInstallationFolder,
    LOCAL_ARCHIVES=strCfg_jonchkiLocalArchives
)
# Get the path to the Jonchki tool.
strJonchki = os.path.join(
    strCfg_jonchkiInstallationFolder,
    'jonchki-%s' % strCfg_jonchkiVersion,
    'jonchki'
)

# Run jonchki.
print('Running jonchki (%s)' % strJonchki)
sys.stdout.flush()
sys.stderr.flush()
astrArguments = [strJonchki]
astrArguments.extend(['--syscfg', strCfg_jonchkiSystemConfiguration])
astrArguments.extend(['--prjcfg', strCfg_jonchkiProjectConfiguration])
astrArguments.append(strArtifactCfg)
astrArguments.extend(sys.argv[1:])
sys.exit(subprocess.call(astrArguments))
