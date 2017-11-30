solution "urbanspork"
	configurations {
		"Debug",
		"Release",
	}

	if _ACTION == "xcode4" then
		platforms {
			"Universal",
		}
	else
		platforms {
			"x32",
			"x64",
--			"Xbox360",
			"Native", -- for targets where bitness is not specified
		}
	end

	language "C++"
	startproject "Engine"

BGFX_DIR   = path.getabsolute("./../node_modules/bgfx")

URBAN_SPORK_DIR = path.getabsolute("./..");

BX_DIR     = os.getenv("BX_DIR")
if not BX_DIR then
	BX_DIR = path.getabsolute(path.join(BGFX_DIR, "../bx"))
end

BIMG_DIR   = os.getenv("BIMG_DIR")
if not BIMG_DIR then
	BIMG_DIR = path.getabsolute(path.join(BGFX_DIR, "../bimg"))
end

local URBANSPORK_BUILD_DIR = path.join(URBAN_SPORK_DIR, ".build")
local URBANSPORK_THIRD_PARTY_DIR = path.join(URBAN_SPORK_DIR, "3rdparty")

if not os.isdir(BX_DIR) or not os.isdir(BIMG_DIR) then

	if not os.isdir(BX_DIR) then
		print("bx not found at " .. BX_DIR)
	end

	if not os.isdir(BIMG_DIR) then
		print("bimg not found at " .. BIMG_DIR)
	end

	print("For more info see: https://bkaradzic.github.io/bgfx/build.html")
	os.exit()
end

dofile (path.join(BX_DIR, "scripts/toolchain.lua"))
if not toolchain(URBANSPORK_BUILD_DIR, URBANSPORK_THIRD_PARTY_DIR) then
	return -- no action specified
end

function copyLib()
end

function projectDefaults()

	debugdir (path.join(BGFX_DIR, "examples/runtime"))

	includedirs {
		path.join(BX_DIR,   "include"),
		path.join(BIMG_DIR, "include"),
		path.join(BGFX_DIR, "include"),
		path.join(BGFX_DIR, "3rdparty"),
		path.join(BGFX_DIR, "examples/common"),
	}

	flags {
		"FatalWarnings",
	}

	links {
		"example-common",
		"example-glue",
		"bgfx",
		"bimg_decode",
		"bimg",
		"bx",
	}

	configuration { "vs*", "x32 or x64" }
		linkoptions {
			"/ignore:4199", -- LNK4199: /DELAYLOAD:*.dll ignored; no imports found from *.dll
		}
		links { -- this is needed only for testing with GLES2/3 on Windows with VS2008
			"DelayImp",
		}

	configuration { "vs201*", "x32 or x64" }
		linkoptions { -- this is needed only for testing with GLES2/3 on Windows with VS201x
			"/DELAYLOAD:\"libEGL.dll\"",
			"/DELAYLOAD:\"libGLESv2.dll\"",
		}

	configuration { "mingw*" }
		targetextension ".exe"
		links {
			"gdi32",
			"psapi",
		}

	configuration { "vs20*", "x32 or x64" }
		links {
			"gdi32",
			"psapi",
		}

	configuration { "durango" }
		links {
			"d3d11_x",
			"d3d12_x",
			"combase",
			"kernelx",
		}

	configuration { "winphone8* or winstore8*" }
		removelinks {
			"DelayImp",
			"gdi32",
			"psapi"
		}
		links {
			"d3d11",
			"dxgi"
		}
		linkoptions {
			"/ignore:4264" -- LNK4264: archiving object file compiled with /ZW into a static library; note that when authoring Windows Runtime types it is not recommended to link with a static library that contains Windows Runtime metadata
		}

	-- WinRT targets need their own output directories or build files stomp over each other
	configuration { "x32", "winphone8* or winstore8*" }
		targetdir (path.join(URBANSPORK_BUILD_DIR, "win32_" .. _ACTION, "bin", _name))
		objdir (path.join(URBANSPORK_BUILD_DIR, "win32_" .. _ACTION, "obj", _name))

	configuration { "x64", "winphone8* or winstore8*" }
		targetdir (path.join(URBANSPORK_BUILD_DIR, "win64_" .. _ACTION, "bin", _name))
		objdir (path.join(URBANSPORK_BUILD_DIR, "win64_" .. _ACTION, "obj", _name))

	configuration { "ARM", "winphone8* or winstore8*" }
		targetdir (path.join(URBANSPORK_BUILD_DIR, "arm_" .. _ACTION, "bin", _name))
		objdir (path.join(URBANSPORK_BUILD_DIR, "arm_" .. _ACTION, "obj", _name))

	configuration { "mingw-clang" }
		kind "ConsoleApp"

	configuration { "android*" }
		kind "ConsoleApp"
		targetextension ".so"
		linkoptions {
			"-shared",
		}
		links {
			"EGL",
			"GLESv2",
		}

	configuration { "nacl*" }
		kind "ConsoleApp"
		targetextension ".nexe"
		links {
			"ppapi",
			"ppapi_gles2",
			"pthread",
		}

	configuration { "pnacl" }
		kind "ConsoleApp"
		targetextension ".pexe"
		links {
			"ppapi",
			"ppapi_gles2",
			"pthread",
		}

	configuration { "asmjs" }
		kind "ConsoleApp"
		targetextension ".bc"

	configuration { "linux-* or freebsd", "not linux-steamlink" }
		links {
			"X11",
			"GL",
			"pthread",
		}

	configuration { "linux-steamlink" }
		links {
			"EGL",
			"GLESv2",
			"SDL2",
			"pthread",
		}

	configuration { "rpi" }
		links {
			"X11",
			"brcmGLESv2",
			"brcmEGL",
			"bcm_host",
			"vcos",
			"vchiq_arm",
			"pthread",
		}

	configuration { "osx" }
		linkoptions {
			"-framework Cocoa",
			"-framework QuartzCore",
			"-framework OpenGL",
			"-weak_framework Metal",
		}

	configuration { "ios* or tvos*" }
		kind "ConsoleApp"
		linkoptions {
			"-framework CoreFoundation",
			"-framework Foundation",
			"-framework OpenGLES",
			"-framework UIKit",
			"-framework QuartzCore",
			"-weak_framework Metal",
		}

	configuration { "xcode4", "ios" }
		kind "WindowedApp"
		files {
			path.join(BGFX_DIR, "examples/runtime/iOS-Info.plist"),
		}

	configuration { "xcode4", "tvos" }
		kind "WindowedApp"
		files {
			path.join(BGFX_DIR, "examples/runtime/tvOS-Info.plist"),
		}


	configuration { "qnx*" }
		targetextension ""
		links {
			"EGL",
			"GLESv2",
		}

	configuration {}

	strip()
end

function exampleProject(...)
    for _, name in ipairs({...}) do
        project (name)
            uuid (os.uuid(name))
            kind "WindowedApp"

        files {
            path.join(URBAN_SPORK_DIR, "Source", name, "**.c"),
            path.join(URBAN_SPORK_DIR, "Source", name, "**.cpp"),
            path.join(URBAN_SPORK_DIR, "Source", name, "**.h"),
        }

        removefiles {
            path.join(URBAN_SPORK_DIR, "URBAN_SPORK_DIR", name, "**.bin.h"),
        }

        defines {
            "ENTRY_CONFIG_IMPLEMENT_MAIN=1",
        }

        projectDefaults()
    end

end

dofile(path.join(BGFX_DIR, "scripts/bgfx.lua"))

group "libs"
bgfxProject("", "StaticLib", {})

dofile(path.join(BX_DIR,   "scripts/bx.lua"))
dofile(path.join(BIMG_DIR, "scripts/bimg.lua"))
dofile(path.join(BIMG_DIR, "scripts/bimg_decode.lua"))

dofile(path.join(BIMG_DIR, "scripts/bimg_encode.lua"))



group "examples"
dofile(path.join(BGFX_DIR, "scripts/example-common.lua"))

group "examples"
exampleProject("Engine")

group "tools"
dofile(path.join(BGFX_DIR, "scripts/shaderc.lua"))
dofile(path.join(BGFX_DIR, "scripts/texturec.lua"))
dofile(path.join(BGFX_DIR, "scripts/texturev.lua"))
dofile(path.join(BGFX_DIR, "scripts/geometryc.lua"))
