# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------- #
#   Copyright (C) 2015 by Christoph Thelen                                #
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
# ----------------------------------------------------------------------- #


import string

import SCons.Script


def __ramtesttemplate_action(target, source, env):
    # Get the attributes.
    atAttributes = env['RAMTESTTEMPLATE_ATTRIBUTES']
    if atAttributes is None:
        raise Exception('No attributes specified!')
    atReplacements = {}
    for tKey, tVal in atAttributes.items():
        strKey = str(tKey)
        # Is the value a SCons file object?
        if isinstance(tVal, SCons.Node.FS.File):
            # Read the complete contents of the file.
            strVal = tVal.get_contents()
            atReplacements[strKey] = strVal
        elif isinstance(tVal, SCons.Node.NodeList):
            # Append all file contents.
            strVal = ''
            for tFile in tVal:
                strVal += tFile.get_contents()
            atReplacements[strKey] = strVal
        else:
            # Try to add everything else as strings.
            strVal = str(tVal)
            atReplacements[strKey] = strVal

    # Read the template.
    strSource = source[0].get_text_contents()

    # Replace all symbols in the template.
    strResult = string.Template(strSource).safe_substitute(atReplacements)

    # Write the result.
    tFile = open(target[0].get_path(), 'wt')
    tFile.write(strResult)
    tFile.close()

    return 0


def __ramtesttemplate_emitter(target, source, env):
    if 'RAMTESTTEMPLATE_ATTRIBUTES' in env:
        tAttr = env['RAMTESTTEMPLATE_ATTRIBUTES']

        for strKey, tValue in tAttr.items():
            strDepends = None
            if type(tValue) is SCons.Node.FS.File:
                strDepends = tValue.get_path()
            else:
                strDepends = str(tValue)

            # Make the target depend on the parameter.
            env.Depends(
                target,
                SCons.Node.Python.Value('%s:%s' % (strKey, strDepends))
            )

    return target, source


def __ramtesttemplate_string(target, source, env):
    return 'RamTestTemplate %s' % target[0].get_path()


def ApplyToEnv(env):
    # ---------------------------------------------------------------------------
    #
    # Add RamTestTemplate builder.
    #
    env['RAMTESTTEMPLATE_ATTRIBUTES'] = None

    ramtesttemplate_act = SCons.Action.Action(
        __ramtesttemplate_action,
        __ramtesttemplate_string
    )
    ramtesttemplate_bld = SCons.Script.Builder(
        action=ramtesttemplate_act,
        emitter=__ramtesttemplate_emitter,
        single_source=1
    )
    env['BUILDERS']['RamTestTemplate'] = ramtesttemplate_bld
