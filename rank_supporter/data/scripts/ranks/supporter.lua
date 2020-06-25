local SectorTurretGenerator = include ("sectorturretgenerator")
include("utility")

local welcome = Mail()
welcome.header = "Thank you for donating!!!!!"
welcome.text = "A little gift from us for supporting the server!."
welcome.money = 100000
welcome:setResources(10000,200,300,400,500,600,700)
welcome:addTurret(SectorTurretGenerator():generate(0, 0, 0, Rarity(RarityType.Rare), WeaponType.RawMiningLaser, Material(MaterialType.Titanium)))

local daily = Mail()
daily.header = "Daily Supporter Login Bonus"
daily.text = "Thanks for logging in today!"
daily:setResources(1000)

return {
    name = "Supporter",
    power = 5, -- EXAMPLE NUMBERS: 0 being owner, 1 being super admin, 2 being admin, 3 being moderator, 4 being trial moderator, 5 donator -- Used when comparing power over other users
    mail = welcome, -- generally you wont want to change this, instead change the code above
    daily = {seconds = 10*60, mail = daily},
    commands = {"back", "addcrew"}, -- commands this rank can use
    privileges = {"sectoroverview", "resource_display", "sectormanager"} -- permissions this rank has for use in other mods
}
