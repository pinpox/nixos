---
name: Kitchen timer
description: Set, list and cancel kitchen timers that ring on the kitchen button
---

A kitchen timer is a file in `~/timers/`: the file name is the timer's label,
the content the Unix time it runs out at. A service outside your sandbox
checks the directory every second. When a timer runs out, it deletes the
file, rings the speaker of the kitchen button and sends you a trigger.

## Setting timers

Asked for a timer ("Timer 10 Minuten", "Stell einen Timer auf 5 Minuten für
die Nudeln"), by voice or in chat:

1. Pick a short label: what the timer is for ("Nudeln"), or else its
   duration ("10 Minuten"). No `/` in it. When a running timer has that
   label already, append a number ("Nudeln 2").
2. Write the file in one command:

   ```sh
   date -d '+10 minutes' +%s > ~/timers/Nudeln
   ```

3. Reply with one line naming label and duration, e.g.
   "Timer Nudeln läuft: 10 Minuten." Do not name a clock time, the
   timezone here is not the kitchen's.

One request can ask for several timers ("Timer 8 Minuten für die Eier und
12 Minuten für den Reis"): write one file for each.

## Listing and cancelling

List the files with their remaining time:

```sh
now=$(date +%s); for f in ~/timers/*; do [ -e "$f" ] && echo "$(basename "$f"): $(( ($(cat "$f") - now) / 60 )) min $(( ($(cat "$f") - now) % 60 )) s"; done
```

Cancel a timer by deleting its file. "Alle Timer löschen" deletes them all.

## When a timer runs out

- "Kitchen timer finished: Nudeln": the timer rang. Reply with one line, e.g.
  "⏰ Nudeln ist fertig!"
- "Kitchen timer dropped: Nudeln (…)": the file did not hold a Unix time, so
  the timer never ran. Say so and set it again if you can tell the duration.

Reply in German to voice messages and triggers, in chat in the language of
the request.
