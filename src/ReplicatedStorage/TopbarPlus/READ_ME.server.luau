--[[

> If you'd like to receive automatic updates make sure to enable
`AutoUpdate` within PackageLink (inside the Icon).

> I recommend enabling auto updates as the application constantly
receives bug fixes, improvements, etc.

> All updates (within this version of TopbarPlus) will be backwards
compatible so you don't need to worry about updates interfering
with your code.

> Try not to modify any code within Icon. For instance, don't accept
"This script is part of a package. Click here to modify." when
viewing the source code otherwise it will break the package link.
If you want to add your own themes I recommend cloning the `Default`
module outside of the package then requiring and applying that.

> DISCLAIMER: as of 27th March 2024 public packages haven't been fully
rolled out so you won't be able to retrieve the latest version
for the time being.

> READ_ME is Script with RunContext set to 'Client' meaning you can
store it in ReplicatedStorage and Workspace and it will still run 
like a normal LocalScript. DO NOT PLACE place in StarterPlayerScripts
(because this is a Script with RunContext). You need to create a separate
LocalScript for anything under StarterPlayerScripts. 

> You're welcome to move `Icon` and require it yourself. You can
then delete this folder and READ_ME.

> Have feedback? Post it to ``devforum.roblox.com/t/topbarplus/1017485``
which I actively monitor. Enjoy! ~ForeverHD

--]]



local container  = script.Parent
local Icon = require(container.Icon)

Icon.new()
	:setLabel("Example")
	:setImage(16086868244, "Deselected")
	:setImage(16086868447, "Selected")