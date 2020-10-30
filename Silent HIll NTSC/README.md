# Silent Hill 1 NTSC-U [SLUS-00707]

## Score Screen UI
Shows the score screen entries in an User Interface, in real time.  
![score_screen](https://i.imgur.com/CGKQwH9.png)

### Script Configurable Parameters:
The script allows the user to customize some aspects of the UI.

| Variable          | Description                                         | Possible Values                             |   Default                     |
| ----------------- | --------------------------------------------------- | ------------------------------------------- | ----------------------------- |
| gui_x             | GUI X Coordinate                                    | Numeric                                     | 1                             |
| gui_y             | GUI Y Coordinate                                    | Numeric                                     | 1                             |
| gui_anchor        | Gui Anchor                                          | topleft, topright, bottomleft, bottomright  | null                          |
| line_hight        | Space between Text Lines                            | Numeric                                     | 15                            |
| txt_color_normal  | Normal Text Color                                   | Hexadecimal / String (\*)                   | 0xFFFFFFFF (White)            |
| txt_color_maxed   | Maxed Text Color (shown where points are maxed)     | Hexadecimal / String (\*)                   | 0xFFF8D868 (Gold)             |
| txt_color_sh      | Show/Hide button Text Color                         | Hexadecimal / String (\*)                   | 0x99FFFFFF (Transparent White)|
| saves_max         | Maximum number of saves to display                  | Numeric                                     | 999                           |
| fighting_kills_max| Maximum number of fighting kills to display         | Numeric                                     | 4000                          |
| shooting_kills_max| Maximum number of shooting kills to display         | Numeric                                     | 4000                          |
| sh_gui_key        | Button to show/hide stats GUI                       | String (\*\*)                               | "ControlLeft"                 |
| input_cooldown    | Cooldown frames between show/hide GUI button presses| Numeric                                     | 30 (at 60 fps ~ 0.5s)         |

(\*) Check [TASVideos Lua API](http://tasvideos.org/Bizhawk/LuaFunctions.html) for more info.  
(\*\*) Check [TASVideos Table Keys](http://tasvideos.org/LuaScripting/TableKeys.html) for more info.  

Additionally, the description and UI index can be changed for all the UI entries.

### Points System (0-100):
#### Mode:
Current game difficulty.

| Difficulty              | Points  |
| ----------------------- | ------- |
| Hard                    | 0       |
| Normal                  | 0       |
| Easy                    | -5      |

#### Games Clear:
Number of games cleared.  
**Note:** There is no 0 games clear, the player always gets at least 2 points for clearing the game.

| Games Clear             | Points  |
| ----------------------- | ------- |
| 5+                      | 10      |
| 4                       | 8       |
| 3                       | 6       |
| 2                       | 4       |
| 1                       | 2       |

#### Ending Type:
Type of ending achieved. Since there's no way to know the ending until it is reached, Good+ ending is assumed for the rank calculation.

| Ending Type             | Points  |
| ----------------------- | ------- |
| Good+                   | 10      |
| Good                    | 5       |
| Bad+                    | 3       |
| Bad                     | 1       |
| UFO                     | 0       |

#### Number of Saves:
Number of times the player saved the game.

| Number of Saves         | Points  |
| ----------------------- | ------- |
| 0-2                     | 5       |
| 3-5                     | 4       |
| 6-10                    | 3       |
| 11-20                   | 2       |
| 21-30                   | 1       |
| 31+                     | 0       |

#### Number of Continues:
Number of game continues, after a death.

| Number of Continues     | Points  |
| ----------------------- | ------- |
| 0-1                     | 5       |
| 2-3                     | 4       |
| 4-5                     | 3       |
| 6-7                     | 2       |
| 8-9                     | 1       |
| 10+                     | 0       |

#### Total Time:
Total ingame time.  
**Note:** Total time does not stop while in the pause or options screen.

| Total Time              | Points  |
| ----------------------- | ------- |
| 01:30:00                | 10      |
| 03:00:00                | 5       |
| 04:00:00                | 3       |
| 06:00:00                | 2       |
| 12:00:00                | 1       |
| 12:00:00+               | 0       |

#### Items Picked:
Total items picked. Objective items count as items picked.

| Items Picked            | Points  |
| ----------------------- | ------- |
| 150+                    | 10      |
| 135                     | 9       |
| 120                     | 8       |
| 105                     | 7       |
| 90                      | 6       |
| 75                      | 5       |
| 60                      | 4       |
| 45                      | 3       |
| 30                      | 2       |
| 15                      | 1       |
| 0-15                    | 0       |

#### Special Items Picked:
Total Special Items picked. Special items are basically New Game+ items like the Katana, Hyper Blaster ...

| Special Items Picked    | Points  |
| ----------------------- | ------- |
| 5-6                     | 10      |
| 4                       | 8       |
| 3                       | 6       |
| 2                       | 4       |
| 1                       | 2       |
| 0                       | 0       |

#### Kills:
Calculated with the formula:
```
Points = (A + B / 2) / (5 + C)
A = The bigger of Fighting and Shooting Kills
B = The smaller of Fighting and Shooting Kills
C = attacks with special weapons - (15 + game clears x 5)

Assuming:
0 < Points <= 30
C >= 0
```
* A kill is a fighting kill if the enemy is finished off by a melee weapon or by the player pressing the *action button* (stomping) when the enemy is down;  
A kill is a shooting kill if the enemy is finished off by a firearm;  
**Note:** A commonly used tactic to get fighting kills faster, is to shoot an enemy until they are down and finish them off by pressing the *action button* (stomping).  
  
* Even if the player misses the enemy with a special weapon, it still counts for the "*attacks with special weapons*" parameter;  
The more game clears the player has, the more attacks they can do with special weapons.

#### Shooting Style:
Calculated with the formula:
```
Points = A x 10 + B x 20 + C x 30 - D x 40
A = Short Range Shots
B = Medium Range Shots
C = Long Range Shots
D = No Aiming Shots

Assuming:
0 < Points <= 10
```
* No aiming shots are shots that missed the enemy.  
**Note:** The Shotgun can contribute heavily for this parameter. Use it in close proximity to enemies and use it wisely.

#### Rank:
Final rank obtained by adding all the previous values.  
The value shown ranges between 0.0 and 10.0.
