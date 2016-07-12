# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------#
#   Copyright (C) 2012 by Christoph Thelen                                #
#   doc_bacardi@users.sourceforge.net                                     #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
#-------------------------------------------------------------------------#

import os.path


#----------------------------------------------------------------------------
#
# Set up the Muhkuh Build System.
#
SConscript('mbs/SConscript')
Import('env_default')

# Create a build environment for the ARM9 based netX chips.
env_arm9 = env_default.CreateEnvironment(['gcc-arm-none-eabi-4.7', 'asciidoc'])

# Create a build environment for the Cortex-R based netX chips.
env_cortex7 = env_default.CreateEnvironment(['gcc-arm-none-eabi-4.9', 'asciidoc'])

# Add the local builders.
import ram_test_template
ram_test_template.ApplyToEnv(env_default)


#----------------------------------------------------------------------------
#
# Create the compiler environments.
#
env_netx4000_default = env_cortex7.CreateCompilerEnv('4000', ['arch=armv7', 'thumb'], ['arch=armv7-r', 'thumb'])
env_netx4000_default.Replace(BOOTBLOCK_CHIPTYPE = 4000)

env_netx500_default = env_arm9.CreateCompilerEnv('500', ['arch=armv5te'])
env_netx500_default.Replace(BOOTBLOCK_CHIPTYPE = 500)

env_netx56_default = env_arm9.CreateCompilerEnv('56', ['arch=armv5te'])
env_netx56_default.Replace(BOOTBLOCK_CHIPTYPE = 56)

env_netx50_default = env_arm9.CreateCompilerEnv('50', ['arch=armv5te'])
env_netx50_default.Replace(BOOTBLOCK_CHIPTYPE = 50)

env_netx10_default = env_arm9.CreateCompilerEnv('10', ['arch=armv5te'])
env_netx10_default.Replace(BOOTBLOCK_CHIPTYPE = 10)

Export('env_netx4000_default', 'env_netx500_default', 'env_netx56_default', 'env_netx50_default', 'env_netx10_default')



#----------------------------------------------------------------------------
#
# Build the platform libraries.
#
PLATFORM_LIB_CFG_BUILDS = [4000, 500, 56, 50, 10]
SConscript('platform/SConscript', exports='PLATFORM_LIB_CFG_BUILDS')
Import('platform_lib_netx4000', 'platform_lib_netx500', 'platform_lib_netx56', 'platform_lib_netx50', 'platform_lib_netx10')


#----------------------------------------------------------------------------
#
# Get the source code version from the VCS.
#
env_default.Version('#targets/version/version.h', 'templates/version.h')


#----------------------------------------------------------------------------
#
# Build all sub-projects.
#
SConscript('ramtest/SConscript')
Import('ramtest_netx4000', 'ramtest_netx500', 'ramtest_netx56', 'ramtest_netx50', 'ramtest_netx10')
Import('ramtest_standalone_netx500', 'ramtest_standalone_netx56', 'ramtest_standalone_netx50', 'ramtest_standalone_netx10')
#Import('ramtest_standalone_netx4000')

SConscript('setup_hif_io/SConscript')
Import('setup_netx56')


#----------------------------------------------------------------------------
#
# Build the documentation.
#

# Get the default attributes.
aAttribs = env_default['ASCIIDOC_ATTRIBUTES']
# Add some custom attributes.
aAttribs.update(dict({
	# Use ASCIIMath formulas.
	'asciimath': True,
	
	# Embed images into the HTML file as data URIs.
	'data-uri': True,
	
	# Use icons instead of text for markers and callouts.
	'icons': True,
	
	# Use numbers in the table of contents.
	'numbered': True,
	
	# Generate a scrollable table of contents on the left of the text.
	'toc2': True,
	
	# Use 4 levels in the table of contents.
	'toclevels': 4
}))

tDoc = env_default.Asciidoc('targets/doc/org.muhkuh.tests.ramtest.html', 'README.asciidoc', ASCIIDOC_BACKEND='html5', ASCIIDOC_ATTRIBUTES=aAttribs)

#----------------------------------------------------------------------------
# 
# Build the artifacts.
#

aArtifactServer = ('nexus@netx01', 'muhkuh', 'muhkuh_snapshots')
strArtifactGroup = 'tests.muhkuh.org'

aArtifactGroupReverse = strArtifactGroup.split('.')
aArtifactGroupReverse.reverse()


strArtifactId = 'ramtest'
tArcList = env_default.ArchiveList('zip')
tArcList.AddFiles('netx/',
	ramtest_netx10,
	ramtest_netx50,
	ramtest_netx56,
	ramtest_netx500,
	ramtest_netx4000,
	setup_netx56)
tArcList.AddFiles('standalone/',
#	ramtest_standalone_netx4000,
	ramtest_standalone_netx500,
	ramtest_standalone_netx56,
	ramtest_standalone_netx50,
	ramtest_standalone_netx10)
tArcList.AddFiles('lua/',
	'lua/ramtest.lua')
tArcList.AddFiles('templates/',
	'lua/attributes_template.lua',
	'lua/ramtest_template.lua',
	'lua/test.lua',
	'lua/timing_phase_test_template.lua')
tArcList.AddFiles('doc/',
	tDoc)
tArcList.AddFiles('',
	'ivy/org.muhkuh.tests.ramtest/install.xml')

strArtifactPath = 'targets/ivy/repository/%s/%s/%s' % ('/'.join(aArtifactGroupReverse),strArtifactId,PROJECT_VERSION)
tArc = env_default.Archive(os.path.join(strArtifactPath, '%s-%s.zip' % (strArtifactId,PROJECT_VERSION)), None, ARCHIVE_CONTENTS=tArcList)
tIvy = env_default.Version(os.path.join(strArtifactPath, 'ivy-%s.xml' % PROJECT_VERSION), 'ivy/%s.%s/ivy.xml' % ('.'.join(aArtifactGroupReverse),strArtifactId))
tPom = env_default.ArtifactVersion(os.path.join(strArtifactPath, '%s-%s.pom' % (strArtifactId,PROJECT_VERSION)), 'ivy/%s.%s/pom.xml' % ('.'.join(aArtifactGroupReverse),strArtifactId))


# Build the artifact list for the deploy operation to bintray.
env_default.AddArtifact(tArc, aArtifactServer, strArtifactGroup, strArtifactId, PROJECT_VERSION, 'zip')
env_default.AddArtifact(tIvy, aArtifactServer, strArtifactGroup, strArtifactId, PROJECT_VERSION, 'ivy')
tArtifacts = env_default.Artifact('targets/artifacts.xml', None)

# Copy the artifacts to a fixed filename to allow a deploy to github.
Command('targets/ivy/%s.zip' % strArtifactId,  tArc,  Copy("$TARGET", "$SOURCE"))
Command('targets/ivy/ivy.xml', tIvy,  Copy("$TARGET", "$SOURCE"))

#----------------------------------------------------------------------------
#
# Make a local demo installation.
#
# Copy all binary binaries.
Command('targets/testbench/netx/ramtest_netx10.bin',   ramtest_netx10,   Copy("$TARGET", "$SOURCE"))
Command('targets/testbench/netx/ramtest_netx50.bin',   ramtest_netx50,   Copy("$TARGET", "$SOURCE"))
Command('targets/testbench/netx/ramtest_netx56.bin',   ramtest_netx56,   Copy("$TARGET", "$SOURCE"))
Command('targets/testbench/netx/ramtest_netx500.bin',  ramtest_netx500,  Copy("$TARGET", "$SOURCE"))
Command('targets/testbench/netx/ramtest_netx4000.bin', ramtest_netx4000, Copy("$TARGET", "$SOURCE"))

Command('targets/testbench/netx/setup_netx56.bin',     setup_netx56,     Copy("$TARGET", "$SOURCE"))

# Copy all LUA scripts.
Command('targets/testbench/lua/ramtest.lua',                        'lua/ramtest.lua',                            Copy("$TARGET", "$SOURCE"))

#----------------------------------------------------------------------------
#
# Install a demo test.
# NOTE: Place hexadecimal values in quotes to prevent conversion to decimal.
#
aAttr = {'CHIP_TYPE':             56,
         'REGISTER_GENERAL_CTRL': '0x030D0001',
         'REGISTER_TIMING_CTRL':  '0x00A13251',
         'REGISTER_MODE':         '0x00000033',
         'SIZE_EXPONENT':         23,
         'INTERFACE':             'MEM'}
tP0 = env_default.RamTestTemplate('targets/demo_scripts/attributes_netX56_MEM_MT48LC2M32B2-7IT_ONBOARD.lua', 'lua/attributes_template.lua', RAMTESTTEMPLATE_ATTRIBUTES=aAttr)
tR0 = env_default.RamTestTemplate('targets/demo_scripts/ramtest_netX56_MEM_MT48LC2M32B2-7IT_ONBOARD.lua', 'lua/ramtest_template.lua', RAMTESTTEMPLATE_ATTRIBUTES={'SDRAM_ATTRIBUTES': tP0})
tT0 = env_default.RamTestTemplate('targets/demo_scripts/timing_phase_test_netX56_MEM_MT48LC2M32B2-7IT_ONBOARD.lua', 'lua/timing_phase_test_template.lua', RAMTESTTEMPLATE_ATTRIBUTES={'SDRAM_ATTRIBUTES': tP0})

# IS42S32200L-7I_netX4000_HIF_ONBOARD.xml
aAttr = {'CHIP_TYPE':             4000,
         'REGISTER_GENERAL_CTRL': '0x030D0001',
         'REGISTER_TIMING_CTRL':  '0x02A23251',
         'REGISTER_MODE':         '0x00000033',
         'SIZE_EXPONENT':         23,
         'INTERFACE':             'HIF'}
tP0 = env_default.RamTestTemplate('targets/demo_scripts/attributes_netx4000_HIF_IS42S32200L-7I_ONBOARD.lua', 'lua/attributes_template.lua', RAMTESTTEMPLATE_ATTRIBUTES=aAttr)
tR0 = env_default.RamTestTemplate('targets/demo_scripts/ramtest_netx4000_HIF_IS42S32200L-7I_ONBOARD.lua', 'lua/ramtest_template.lua', RAMTESTTEMPLATE_ATTRIBUTES={'SDRAM_ATTRIBUTES': tP0})
tT0 = env_default.RamTestTemplate('targets/demo_scripts/timing_phase_test_netx4000_HIF_IS42S32200L-7I_ONBOARD.lua', 'lua/timing_phase_test_template.lua', RAMTESTTEMPLATE_ATTRIBUTES={'SDRAM_ATTRIBUTES': tP0})

