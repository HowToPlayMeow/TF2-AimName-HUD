## Description
- Aim at Enemy, Their Name Will Appear and Health
 
![20250924195831_1](https://github.com/user-attachments/assets/b0d664af-3315-4179-b385-0603dd12da37)

## ConVar
|Name|Default Value|Description|
|-|:-:|-|
|`sm_tfhud_version`|`"1.1"`|Version of TF2HUD AimName|
|`sm_tfhud_enable`|`"1"`|TF2HUD AimName<br>**(1 = Enable, 0 = Disable)**|
|`sm_tfhud_icon`|`"leaderboard_streak"`|HUD Icon|
|`sm_tfhud_distance`|`"100"`|Distance in Meters|
|`sm_tfhud_interval`|`"0.2"`|Check Interval|
|`sm_tfhud_blockspy`|`"1"`|Block HUD for Spy Class<br>**(1 = Enable, 0 = Disable)**|
|`sm_tfhud_hp`|`"0"`|See HP<br>**(0 = OFF, 1 = All Teams, 2 = RED Teams, 3 = BLU Teams)**|

## Small Problems
- **HUD** will Disappear in **2-3** s.
- **Spy** Disguised as their Own Team, **HUD** will **Not Work**.
- **ConVar:** `sm_tfhud_hp` should not be used in **MVM** _`(I haven't tested it in MVM, I think it might be a problem).`_

## How To Change Icon
- Open File - _**...\steamapps\common\Team Fortress 2\tf\tf2_misc_dir.vpk\root\scripts\mod_textures.txt**_

## Credit
- [Dragonissa](https://github.com/Dragonissa/aimnames/blob/main/addons/sourcemod/scripting/aimnames.sp) - Code aimnames
- [Arthurdead](https://github.com/arthurdead/sm-plugins/blob/master/addons/sourcemod/scripting/hudnotifyfix.sp) - Code hudnotifyfix
