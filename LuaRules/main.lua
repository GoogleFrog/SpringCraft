-- Wiki: http://springrts.com/wiki/Gamedev:Glossary#springcontent.sdz

-- Include base content gadget handler to run synced gadgets
local SCRIPT_DIR = Script.GetName() .. '/'
Spring.Echo("Luarules - Loading Utilities")
VFS.Include(SCRIPT_DIR .. 'utilities.lua', nil, VFSMODE)

Spring.Echo("Luarules - Loading GadgetHandler")
VFS.Include(SCRIPT_DIR .. "gadgets.lua", nil, VFSMODE)
--VFS.Include("luagadgets/gadgets.lua",nil, VFS.BASE)

Spring.Echo("Luarules - Loading Done")
