# Description
- Aim at Enemy, Their Name Will Appear and Health
- Some [aimname](https://github.com/Dragonissa/aimnames?tab=readme-ov-file) codes are used
 
![20250924195831_1](https://github.com/user-attachments/assets/b0d664af-3315-4179-b385-0603dd12da37)

# Dependencies
- [tf2hudmsg](https://github.com/DosMike/tf2hudmsg)

# ConVar
- `sm_tfhud_version`   `"1.1"`                    **(Default)** - _Version of TF2HUD AimName_
- `sm_tfhud_enable`     `"1"`                   **(Default)** - _TF2HUD AimName (1 = Enable, 0 = Disable)_
- `sm_tfhud_icon`       `"leaderboard_streak"`  **(Default)** - _HUD Icon_
- `sm_tfhud_distance`   `"100"`                 **(Default)** - _Distance in Meters_
- `sm_tfhud_interval`   `"0.2"`                   **(Default)** - _Check Interval_
- `sm_tfhud_blockspy`   `"1"`                   **(Default)** - _Block HUD for Spy Class (1 = Enable, 0 = Disable)_
- `sm_tfhud_hp`         `"0"`                   **(Default)** - _See HP (0 = OFF, 1 = All Teams, 2 = RED Teams, 3 = BLU Teams)_

# Small Problems
- **HUD** will Disappear in **2-3** s.
- **Spy** Disguised as their Own Team, **HUD** will **Not Work**.
- **ConVar:** `sm_tfhud_hp` should not be used in **MVM** _`(I haven't tested it in MVM, I think it might be a problem).`_

# How To Change Icon
- Open File - _**...\steamapps\common\Team Fortress 2\tf\tf2_misc_dir.vpk\root\scripts\mod_textures.txt**_
