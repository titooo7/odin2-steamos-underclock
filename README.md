# Odin 2 CPU underclock for SteamOS

> **For the AYN Odin 2 Pro running SteamOS (the unofficial SteamOS ARM image) only.**
> Not for Android, and not for other handhelds: the clock values are the steps of
> the Odin 2's Snapdragon 8 Gen 2 (SM8550). The installer checks the chip and
> stops on anything else.

Lower the Odin 2's maximum CPU clocks to get lower temperatures, a quieter fan
and less power draw, usually with the same fps. Choose between three underclock
profiles, a `light` profile for CPU-heavy games, or stock, system-wide or per
game, without a password.

Tested on an AYN Odin 2 Pro with Unofficial SteamOS ARM 1.4 (kernel 7.2.8-sm8550-steamos).
The Odin 2 / Max / Mini / Portal use the same chip and should work too, but are untested.

## Profiles

| Profile | Cores 0-2 | Cores 3-6 | Core 7 |
|---|---|---|---|
| `light` | 2.02 GHz (stock) | 2.32 GHz | 2.96 GHz (stock) |
| `small` (default) | 1.79 GHz | 2.32 GHz | 2.48 GHz |
| `medium` | 1.56 GHz | 2.05 GHz | 2.09 GHz |
| `large` | 1.46 GHz | 1.79 GHz | 1.84 GHz |
| `stock` | 2.02 GHz | 2.80 GHz | 2.96 GHz |

The `small` / `medium` / `large` values are the Small / Medium / Large presets of
the Android app ClusterTuner. `light` caps only cores 3-6 and leaves the little
cores and the fastest core (7) at stock, for games limited by one main thread.
The GPU is not touched. Start with `small`; try `medium` or `large` if a game
still runs well and you want it cooler and quieter. If a game loses fps with
`small`, give it `light` (or `stock`) with a per-game profile.

### Measured result (MotoGP 20, `small` vs `stock`)

Same race, Balanced performance profile, on battery, average of the last 3 minutes
of a 5-minute race:

| | `small` | `stock` |
|---|---|---|
| CPU temperature | 85.8 °C (peak 93) | 93.0 °C (peak 97) |
| GPU temperature | 73.6 °C | 76.4 °C |
| Fan | 5,287 rpm | 6,257 rpm |
| Power draw | 11.7 W | 13.1 W |
| FPS | about the same | about the same |

### Measured result (SP Football Life 2026, `small` / `light` vs `stock`)

Game resolution 1280x720 and in-game graphics on Medium, same teams in every run,
Balanced performance profile, on battery, last 2 minutes of a 3-minute match. This game runs through Box64 (x86 emulation), which keeps the
CPU at its maximum the whole match, so here the underclock costs fps:

| | `small` | `light` | `stock` |
|---|---|---|---|
| CPU temperature | 77.4 °C (peak 79) | 89.1 °C (peak 95) | 91.4 °C (peak 95) |
| GPU temperature | 64.1 °C | 69.8 °C | 69.9 °C |
| Fan | 3,299 rpm | 5,933 rpm | 6,107 rpm |
| Power draw | 9.2 W | 11.9 W | 12.7 W |
| FPS | about 25 | 33-39 | about 35 |

(The `small` run started cooler than the others, 76 °C vs 87-89 °C at kick-off,
which exaggerates its temperature and fan gaps a little.) While playing, cores 0
and 7 sat at 100% and the others didn't: the game is limited by its main thread on
the fastest core. `light` keeps that core at stock, so it keeps the fps and still
saves a little power; `small` slows it and loses about 10 fps. For games like
this, use a per-game profile (`game-profile.sh light %command%`, see below).

## Install

You need the sudo password of the `steamos` user. If you never set one, open
Konsole in Desktop Mode and run `passwd` first.

**On the Odin 2** (Desktop Mode, open Konsole):

    git clone https://github.com/titooo7/odin2-steamos-underclock.git /home/steamos/underclock
    sudo bash /home/steamos/underclock/install.sh

**Or from a PC** that can `ssh` into the Odin 2 (replace `steamos@<odin2-ip>`):

    ssh steamos@<odin2-ip> git clone https://github.com/titooo7/odin2-steamos-underclock.git /home/steamos/underclock
    ssh -t steamos@<odin2-ip> sudo bash /home/steamos/underclock/install.sh

The installer ends by printing the CPU caps; with the default profile they are
`1785600`, `2323200` and `2476800`. That's it: the underclock is active now and
after every reboot, in Game Mode and Desktop Mode.

Keep the folder at `/home/steamos/underclock`: the commands below use that path,
and your chosen profile is saved there. Use full paths over ssh, not `~`: some
shells (e.g. fish) expand `~` to your PC's home folder before ssh sends the command.

## Choose a profile

In Konsole (or over ssh). No password needed:

    /home/steamos/underclock/underclock-profile.sh medium     # light, small, medium, large or stock
    /home/steamos/underclock/underclock-profile.sh            # show the current profile and caps

It takes effect within 2 seconds and stays chosen after reboots.

### Per game

In Steam: the game > Properties > Launch options, enter:

    /home/steamos/underclock/game-profile.sh large %command%

(`light`, `small`, `medium`, `large` or `stock`; if the game already has launch options,
keep them after `%command%`). That game runs with that profile, and your normal
profile comes back when you quit it. It works however the game is launched (Game
Mode, Big Picture or Desktop Mode). Example: a game that loses fps with the
underclock gets `game-profile.sh light %command%` (or `stock`).

To undo it for a game, clear its launch options.

## Turn it off

Without a password:

- `/home/steamos/underclock/underclock-off.sh`: stock clocks until reboot or until you turn it back on
- `/home/steamos/underclock/underclock-on.sh`: back on, with your chosen profile

While it's off, profiles have no effect. To turn it off permanently (also after
reboots): `sudo systemctl disable --now odin2-underclock`; back on:
`sudo systemctl enable --now odin2-underclock`.

## Uninstall

    sudo bash /home/steamos/underclock/uninstall.sh

This restores stock clocks and removes everything the installer added. The
folder stays; delete it if you like, and clear any `game-profile.sh` launch options.

## Update

    git -C /home/steamos/underclock pull
    sudo bash /home/steamos/underclock/install.sh

Your chosen profile is kept.

## How it works

The SteamOS ARM image's power daemon (`konkrd`, when you change the performance
profile) and Steam's TDP slider reset the CPU maximum clock to stock, so a
one-time setting doesn't last. A small service, `odin2-underclock`, checks every
2 seconds and puts your profile's caps back. Within a profile it only ever
lowers the maximum, so a stricter TDP slider setting still wins.

Underclocking only lowers the maximum clock the CPU may use. It doesn't change
voltages and can't damage the device; at worst a game runs slower, and `stock`
or `underclock-off.sh` puts everything back.

The installer adds:

| File | Purpose |
|---|---|
| `/etc/odin2-underclock.conf` | Profile values (in kHz) and the default profile |
| `/etc/odin2-underclock.sh` | The loop that applies the chosen profile |
| `/etc/systemd/system/odin2-underclock.service` | Starts it at boot; restores stock clocks when stopped |
| `/etc/sudoers.d/zz-odin2-underclock` | Lets your user run exactly two commands as root without a password, `systemctl stop odin2-underclock.service` and `systemctl start odin2-underclock.service`, for `underclock-off.sh` / `underclock-on.sh`. Nothing else. |

The chosen profile is saved in `/home/steamos/underclock/profile`; the service
accepts only the names `light`, `small`, `medium`, `large` and `stock` from it.

## Change the profile values

Edit `odin2-underclock.conf` in this folder (values in kHz for cores 0-2, 3-6
and 7; each must be one of that cluster's
`/sys/devices/system/cpu/cpufreq/policyN/scaling_available_frequencies`, with
N = 0, 3 or 7; 0 = stock), then run the installer again.

## Measure a game yourself

Compare two profiles in the same game. On battery (power can't be measured while
charging), same game, scene and performance profile in both runs:

1. Start the logger and leave it running:
   `bash /home/steamos/underclock/thermlog.sh /home/steamos/underclock/mygame.csv`
2. Run 1: note the time (`date +%T`) when gameplay starts, play 5 minutes, note
   the time again, quit. Note the fps (Steam overlay, level 1).
3. Switch profile, e.g. `/home/steamos/underclock/underclock-profile.sh stock`, and
   let the Odin 2 cool until the CPU is back near its starting temperature (about 5 minutes).
4. Run 2: same as step 2.
5. Switch back to your usual profile and stop the logger (Ctrl+C).
6. Compare the last 3 minutes of each run:
   `bash /home/steamos/underclock/thermsummary.sh /home/steamos/underclock/mygame.csv <start> <end>`

The `svc` column shows the service state and profile of each row (for example
`active/medium`). `results-spfl26-2026-10-23.csv` is the raw log of the SP Football Life 2026 test
(small 06:46:29-06:48:29, stock 06:59:03-07:01:03);
`results-spfl26-light-2026-10-23.csv` the `light` run (07:51:00-07:53:00).
`results-motogp20-2026-10-21.csv` is the raw log of the MotoGP 20
test above, recorded before profiles existed (`active` = `small`; run 1
22:08:03-22:13:19, run 2 22:23:23-22:28:31).

## License

MIT, see [LICENSE](LICENSE). Use at your own risk.
