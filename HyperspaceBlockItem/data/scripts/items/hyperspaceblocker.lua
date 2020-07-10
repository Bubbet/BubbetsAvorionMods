package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
include('hyperspaceblocker')
local PlanGenerator = include ("plangenerator")

---@param rarity Rarity
function create(item, rarity)
	item.stackable = true
	item.depleteOnUse = true
	item.icon = "data/textures/icons/fusion-generator.png"
	item.rarity = rarity
	item.price = 5000000 + item.rarity.value * 1000000

	local tooltip = Tooltip()
	tooltip.icon = item.icon

	item.name = rarity.name .. ' Hyperspace Jammer'

	local title = item.name

	local headLineSize = 25
	local headLineFontSize = 15
	local line = TooltipLine(headLineSize, headLineFontSize)
	line.ctext = title
	line.ccolor = item.rarity.color
	tooltip:addLine(line)

	-- empty line
	tooltip:addLine(TooltipLine(14, 14))

	local line = TooltipLine(18, 14)
	HyperSpaceBlocker.rarity = rarity
	line.ltext = 'Range'%_t
	line.rtext = '~' .. math.floor(math.sqrt(HyperSpaceBlocker.getRange())/100) .. 'km'
	tooltip:addLine(line)

	local line = TooltipLine(18, 14)
	line.ltext = 'Durability Factor'
	line.rtext = 30 + item.rarity.value * 10
	tooltip:addLine(line)

	-- empty line
	tooltip:addLine(TooltipLine(14, 14))

	local line = TooltipLine(18, 14)
	line.ltext = "Can be deployed by the player."%_T
	tooltip:addLine(line)

	local line = TooltipLine(18, 14)
	line.ltext = "Blocks Hyperspace engines."%_T
	tooltip:addLine(line)

	local line = TooltipLine(18, 14)
	line.ltext = "Affects everyone in range."%_T
	tooltip:addLine(line)

	item:setTooltip(tooltip)
	return item
end

function activate(item)
	local player = Player()
	local position = player.craft.translationf - player.craft.look * (player.craft.size.y + 2)
	local desc = EntityDescriptor()
	desc:addComponents(
			ComponentType.Plan,
			ComponentType.BspTree,
			ComponentType.Intersection,
			ComponentType.Asleep,
			ComponentType.DamageContributors,
			ComponentType.BoundingSphere,
			ComponentType.BoundingBox,
			ComponentType.Velocity,
			ComponentType.Physics,
			ComponentType.Scripts,
			ComponentType.ScriptCallback,
			ComponentType.Title,
			ComponentType.Owner,
			ComponentType.InteractionText,
			ComponentType.FactionNotifier,
			ComponentType.Durability,
			ComponentType.PlanMaxDurability
	)

	local plan = PlanGenerator.makeBeaconPlan()
	plan:scale(vec3(2))
	plan.accumulatingHealth = true

	local matrix = Matrix()
	matrix.position = position
	desc.position = matrix
	desc:setMovePlan(plan)
	desc.title = "Hyperspace Jammer"

	local beacon = Sector():createEntity(desc)
	Physics(beacon).driftDecrease = 0.9
	Durability(beacon).maxDurabilityFactor = 30 + item.rarity.value * 10
	beacon:addScript("hyperspaceblocker", item.rarity, player)
	return valid(beacon)
end