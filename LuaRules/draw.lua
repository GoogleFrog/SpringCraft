-- Wiki: http://springrts.com/wiki/Gamedev:Glossary#springcontent.sdz

-- Include base content gadget handler to run unsynced gadgets
--VFS.Include("luagadgets/gadgets.lua",nil, VFS.BASE)

local SCRIPT_DIR = Script.GetName() .. '/'
Spring.Echo("Unsynced Luarules - Loading")
VFS.Include(SCRIPT_DIR .. "gadgets.lua", nil, VFSMODE)
Spring.Echo("Unsynced Luarules - Done")