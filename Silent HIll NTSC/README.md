# Silent Hill 1 NTSC-U

## Score Screen UI
Shows the score screen entries in an User Interface, in real time.

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

| Games Clear             | Points  |
| ----------------------- | ------- |
| 5+                      | 10      |
| 4                       | 8       |
| 3                       | 6       |
| 2                       | 4       |
| 1                       | 2       |
| 0                       | 0       |

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
