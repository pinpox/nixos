---
name: todos
description: Manage pinpox's personal todos/tasks in Vikunja from the command line via the `vja` CLI. Use whenever the user wants to add, list, show, complete, edit, defer, or organize their todos/tasks, or mentions vikunja/vja.
---

# Todos via `vja` (Vikunja CLI)

`vja` is a Python CLI talking to the user's Vikunja server at `https://todo.pablo.tools`
(deployed by the `@pinpox/vikunja` clan service on `porree`).

Both the binary and `~/.config/vja/config.rc` are declarative — see
`home-manager/modules/vja/default.nix` in the nixos repo. `vja` is on `PATH`; just run it:

```bash
vja <command> ...
```

The auth token in `~/.config/vja/token.json` is mutable state and already present, so
no login is needed. If a command fails with an auth error, the token expired — tell the
user to run `vja user show` interactively to re-login rather than guessing credentials.

## Core commands

### List — `vja ls`

```bash
vja ls                              # open (not-done) tasks: id, prio, title, project, urgency
vja ls --custom-format=simple       # compact: id, title, project, assignee, due
vja ls --all                        # include completed tasks
vja ls 1 3                          # only tasks with id 1 and 3
```

The `simple` format is defined in `config.rc` and is the best default for
skimming a list.

Filtering (combine multiple `--filter`, they AND together):

```bash
vja ls -o Inbox                     # by project (id or title regex)
vja ls -i 'gutschein'               # by title regex
vja ls -l shopping                  # by label
vja ls -p 'ge 3'                    # priority >= 3
vja ls -d 'before today'            # due before today
vja ls -u 5                         # urgency >= 5
vja ls -t Work                      # by base project (whole subtree)
vja ls --filter="due_date after now" --filter="priority ge 2"
vja ls --sort="-urgency,due_date"   # sort; prefix "-" reverses
```

Operators for `--filter`: `eq ne gt lt ge le before after contains`.

Machine-readable: `--json` (raw Vikunja) or `--jsonvja` (vja model). Use these
when you need to parse fields programmatically.

### Add — `vja add TITLE...`

```bash
vja add "Buy milk"                                  # into default/first-favorite project
vja add "Call dentist" -o Inbox -d "tomorrow 9am"   # project + due date
vja add "Pay rent" -p 4 -r "1d before due_date" -d "in 3 days"
vja add "Read paper" -l reading                     # label must already exist (or --force-create)
vja add "Groceries" -n "eggs, bread, coffee"        # description/note
vja add "Sprint" --start "monday" --end "friday"    # start/end dates
```

Dates accept natural language (parsedatetime): `tomorrow`, `next monday 18:00`,
`in 2 weeks`, `friday`. Reminders accept absolute (`in 3 days at 18:00`) or
relative-to-due (`1h30m before due_date`, or bare `-r` = equal to due date).

### Show — `vja show ID...`

```bash
vja show 3          # full detail of task 3
vja show 1 2 --json
```

### Complete / uncomplete — `vja toggle ID`

```bash
vja toggle 3        # mark done (or undo if already done)
```

Takes exactly one id. `vja edit ID --done true` also works and accepts several ids.

### Edit — `vja edit ID...`

```bash
vja edit 3 -i "New title"                 # rename
vja edit 3 -d "next friday" -p 5          # set due + priority
vja edit 3 -o Work                        # move to another project
vja edit 3 -a "and this too"              # append a line to the note
vja edit 3 --done true                    # explicitly mark completed
vja edit 3 -f                             # favorite (star); --no-star to unstar
```

### Defer — `vja defer ID... DELAY`

Shifts due date and reminders. Delay like `2d`, `1h30m`:

```bash
vja defer 3 2d
```

### Delete — `vja delete ID...`

Permanent, no undo. Confirm intent before running.

```bash
vja delete 5
```

## Projects, labels, relations

```bash
vja project ls                       # id, title, description, parent
vja project add "New Project"
vja label ls
vja label add shopping
vja relation add 3 subtask 7         # KIND: subtask parenttask related blocking blocked precedes follows ...
vja relation rm 3 subtask 7
vja clone 3 "Copy of task"           # clone needs a new title
```

## Notes / gotchas

- Tasks are addressed by numeric **id** (shown in `ls`/`show`), not title.
  To find an id first: `vja ls -i '<title regex>'`.
- `vja edit ID` / `vja open ID` with no options opens a **browser** — always pass
  an option when scripting.
- Labels must exist before use, or pass `--force-create`.
- Priority is an integer, higher = more urgent; Vikunja scale is 1–5 (0 = unset).
- Add `-q` to mutating commands to suppress the confirmation dump, `-v` to print
  the resulting task.
- Titles with umlauts (`Gummibär`, `Sperrmüll`, `prüfen`) MUST reach `vja` as a
  single argv element from a direct exec — e.g. the bash tool. Do **not** route
  them through a JS `Bun.$` template shell: it miscounts UTF-8 byte vs character
  offsets, so the child receives a mangled argument (`Gummibär` arrives as
  `GummibGummibär`) and the corruption is stored silently. `Bun.spawn` with an
  argv array is safe. Read the value back after any non-ASCII write.
- `vja` cannot delete labels, nor rename/colour/delete projects. Use the REST API
  with the token from `~/.config/vja/token.json`:
  - create: `PUT /labels`, `PUT /projects`
  - update: `POST /labels/{id}`, `POST /projects/{id}` (`PUT` returns 405)
  - delete: `DELETE /labels/{id}` — also detaches the label from every task
  - `hex_color` is a bare hex string with no leading `#`
  - `POST /user/settings/general` rejects this token (401); change the capture
    project in the web UI instead.

## Conventions in this instance

Agreed with the user. Do not "improve" on these unprompted:

- **Projects are areas, exactly one home per task**: `Haus` (green `4caf50`),
  `Infra` (yellow `fbc02d`), `Garage` (blue `2196f3`), `Papierkram` (purple
  `9c27b0`). `Inbox` means captured-but-unclassified and is drained to zero onAdd lis
  review — that emptiness is what stops things being forgotten.
- **Labels are motorcycle names only**: `Gummibär`, `Silverstar`, `Pony`,
  `Tornado`. Every `Garage` task carries the bike it belongs to.
- **Priorities are unused.** Leave priority at 0 unless asked.
- **Due dates only for externally imposed deadlines**, never for mere intent, so
  the overdue list stays trustworthy.
- Titles read `Subject: action` (`Stalwart: Lislon hinzufügen`). German for
  personal tasks, English for technical ones — match how the user wrote it.
- Capture is a bare `vja add "..."`, which lands in `Inbox` via the server-side
  `default_project_id = 2`.
