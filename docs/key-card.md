# ACH-NEOVIM Key Card

The keys worth having at hand, on one page. `scripts/check` reads this card and checks every key on it against the keys Neovim actually has, so a key renamed or removed fails the check until the card is changed to match.

## The idea

Neovim has modes. It starts in normal mode, where every letter is a command rather than text: `j` moves down a line and `d d` deletes one. Press `i` and you are in insert mode, where letters type as in any other editor, and `Esc` brings you back. Almost every key on this card is pressed in normal mode, so when in doubt, press `Esc` first.

Thirteen menus hang off the Space bar, one per kind of work. Press `Space`, pause, and which-key draws every key that can follow, each with an icon and a description. You do not memorise keys: you pick a menu, then read the list.

`Space f f` means Space, then f, then f, one after another. `Ctrl-h` means holding Ctrl while pressing h, and `Shift-h` is a capital H. `Alt` is the left Option key, which Ghostty sends as Alt, while the right Option key still types accents. `Backslash` is the `\` key.

The Description column is each key's description word for word, the text `Space s k` searches and which-key shows. One exception: which-key shows a key whose description begins with Toggle as Enable or Disable instead, naming what a press will do now.

## Neovim's own keys

These belong to Neovim, and this configuration leaves every one of them as it is. They are the core of every Vim tutorial, and `nvim --clean +Tutor`, which opens Neovim's own lessons without this configuration, teaches them in about half an hour.

| Key | What it does |
| --- | --- |
| `i` | Starts typing before the cursor |
| `a` | Starts typing after the cursor |
| `o` | Opens a new line below and starts typing on it |
| `v` `V` | Starts selecting characters, or whole lines |
| `u` | Undoes the last change |
| `Ctrl-r` | Redoes what `u` undid |
| `x` | Deletes the character under the cursor |
| `d d` | Cuts the line |
| `y y` | Copies the line |
| `p` | Pastes after the cursor |
| `.` | Repeats the last change |
| `c i w` | Deletes the word under the cursor and starts typing in its place |
| `w` `b` | Moves to the next word, or back to the one before |
| `0` `$` | Moves to the start of the line, or to its end |
| `g g` `G` | Moves to the top of the file, or to the bottom |
| `/` | Searches forward: type the text and press Enter, then `n` for the next match and `N` for the one before |
| `Ctrl-o` | Goes back to where the cursor was before the last jump |

Commands start with a colon and end with Enter: `:w` saves, `:q` closes the window, and `:wq` does both.

## The menus

| Keys | Menu | For |
| --- | --- | --- |
| `Space Tab` | tabs | a new tab, the next one, closing them |
| `Space a` | claude | Claude Code beside the file |
| `Space b` | buffer | the open files: switching, closing |
| `Space c` | code | the language server, formatting, Mason, building a document |
| `Space d` | debug | breakpoints, stepping, the debugger's panes |
| `Space f` | file/find | opening, recent files, new files, the file tree, a terminal |
| `Space g` | git | Lazygit, Neogit, changes, history, GitHub |
| `Space m` | multicursor | a cursor at each match, to edit them all at once |
| `Space q` | quit/session | quitting, and bringing back the last session |
| `Space s` | search | text, help, keys, symbols, replacing |
| `Space u` | toggles | switching a setting off and on |
| `Space w` | windows | splitting, moving, closing |
| `Space x` | diagnostics/quickfix | errors and warnings, lists, TODO comments |

Four more prefixes work the same way without Space. `[` and `]` move to the previous and the next of something, a diagnostic after `d`, a changed block after `h`, an open file after `b`; `g` goes to things, and `z` folds. `Space ?` lists the keys that belong to the file in front of you.

## Files and buffers

| Key | Description | What it does |
| --- | --- | --- |
| `Space Space` | Find Files (Root Dir) | Finds a file in this project by typing part of its name |
| `Space f r` | Recent | Lists the files opened lately |
| `Space f n` | New File | Opens an empty file with no name yet; `:w notes.md` saves it as notes.md |
| `Space e` | File Tree (project) | Shows the project's files as a tree beside the text |
| `Space f o` | Open Folder as Text (oil) | Opens this file's folder as a page of text, where changing a name and saving renames the file |
| `Space ,` | Buffers | Lists the open files, to switch to one |
| `Shift-h` | Prev Buffer | Moves to the open file before this one |
| `Shift-l` | Next Buffer | Moves to the open file after this one |
| `Space b d` | Delete Buffer | Closes this file and keeps the window |
| `Ctrl-s` | Save File | Saves the file, in insert mode as well |
| `Space q s` | Restore Session for This Folder | Reopens the files that were open when Neovim last closed in this folder |
| `Space q q` | Quit All | Quits Neovim |

A buffer is a file Neovim has open, and a window is a view onto one, so closing a window leaves the file open and `Space ,` still finds it. Root Dir is the project's top folder, the nearest one above the file that holds `.git`, or else the folder Neovim was started in. A key marked cwd uses the folder Neovim was started in, whatever the file.

In any list these keys open, type to narrow it, `Ctrl-j` and `Ctrl-k` move down and up, and Enter opens the choice. `Esc` once stops typing, and a second `Esc` closes the list.

## Search and moving

| Key | Description | What it does |
| --- | --- | --- |
| `Space /` | Grep (Root Dir) | Searches the text of every file in the project |
| `Space s b` | Buffer Lines | Searches the lines of this file |
| `Space s r` | Search and Replace | Finds text across the project and replaces it, showing each change first |
| `Space s h` | Help Pages | Searches Neovim's own help |
| `Space s k` | Keymaps | Searches every key by its description |
| `Space s R` | Resume | Reopens the last search where it was left |
| `s` | Flash Jump | Type a character or two from where you want to go, then the letter that appears there |
| `S` | Flash Select by Syntax | Selects a whole piece of code, such as a function, by the letter shown on it |

## Code

These work once a language server is running for the file, which happens on its own for every language the configuration knows, except the last three, which belong to particular files.

| Key | Description | What it does |
| --- | --- | --- |
| `g d` | Goto Definition | Jumps to where the name under the cursor is defined; `Ctrl-o` comes back |
| `g r r` | References | Lists every place the name under the cursor is used |
| `K` | Hover | Shows the documentation for the name under the cursor |
| `Space c a` | Code Action | Lists the fixes the language server offers here |
| `Space c r` | Rename | Renames the name under the cursor everywhere it is used |
| `Space c f` | Format | Formats the file, or the selected lines |
| `Space c d` | Line Diagnostics | Shows the whole error or warning on this line |
| `] d` | Next Diagnostic | Moves to the next error or warning |
| `Space x x` | Problems (Trouble) | Lists the errors and warnings in a panel at the bottom |
| `Space c m` | Mason | Shows the language tools Mason has installed |
| `Space c x` | x86 Manual | Opens Intel's manual at the instruction under the cursor |
| `Space c b` | Build Document | In a LaTeX file, builds the PDF |
| `Space c p` | Markdown Preview | In a Markdown file, shows it in the browser, kept in step as you type; pressed again, stops |

In a LaTeX file, `Space ?` also lists VimTeX's own keys, which all begin with Backslash then l.

In a LilyPond file, Swara's keys begin with Backslash. `Backslash o` opens the PDF in Skim, `Backslash v` shows the score inside the editor, `Backslash p` plays it, `Backslash s` stops playing, `Backslash m` opens it in MuseScore, and `Backslash b` builds the PDF and the MIDI file.

## Git

| Key | Description | What it does |
| --- | --- | --- |
| `Space g g` | Lazygit (Root Dir) | Opens Lazygit, a whole git program in a window, on this project |
| `Space g n` | Neogit (Root Dir) | Opens Neogit, git's status page inside Neovim, where changes are staged and committed |
| `] h` | Next Hunk | Moves to the next changed block in this file |
| `Space g h p` | Preview Hunk Inline | Shows the block under the cursor as it was before the change |
| `Space g h s` | Stage or Unstage Hunk | Stages the changed block under the cursor, or unstages it |
| `Space g h r` | Reset Hunk | Throws away the change in the block under the cursor |
| `Space g D` | Diff View (Root Dir) | Shows every uncommitted change, file by file |
| `Space u b` | Toggle Git Blame Line | Shows who last changed the line under the cursor, and when, at its end |
| `Space g B` | Git Browse (open) | Opens this file on GitHub in the browser |
| `Space g p` | GitHub Pull Requests | Lists the repository's pull requests |

A hunk is one block of lines changed together, and the bars in the left margin mark each one.

## Claude Code

| Key | Description | What it does |
| --- | --- | --- |
| `Space a c` | Toggle Claude | Opens Claude Code in a panel beside the file, or hides it |
| `Space a b` | Add Buffer to Claude | Hands this file to Claude |
| `Space a s` | Send to Claude | With lines selected, hands Claude just those lines |
| `Space a a` | Accept Diff | Takes the change Claude proposed |
| `Space a d` | Deny Diff | Turns that change down |
| `Space a r` | Resume Claude | Picks an earlier conversation to carry on |

## Debugging

| Key | Description | What it does |
| --- | --- | --- |
| `Space d b` | Toggle Breakpoint | Sets a stop on this line, or clears it |
| `Space d c` | Start or Continue | Starts the program under the debugger, or runs on to the next stop |
| `Space d O` | Step Over | Runs this line and stops on the next |
| `Space d i` | Step Into | Goes into the function this line calls |
| `Space d o` | Step Out | Runs to the end of this function and stops in the one that called it |
| `Space d t` | Stop Debugging | Ends the run |
| `Space d u` | Debug Interface | Shows or hides the panes of variables, calls and breakpoints |

## Windows and toggles

| Key | Description | What it does |
| --- | --- | --- |
| `Ctrl-h` | Go to Left Window | Moves to the window on the left; `Ctrl-j`, `Ctrl-k` and `Ctrl-l` go down, up and right |
| `Space -` | Split Window Below | Splits the window, with the new one below |
| `Space \|` | Split Window Right | Splits the window, with the new one to the right |
| `Space w d` | Delete Window | Closes this window |
| `Space u f` | Toggle Format on Save (all buffers) | Stops formatting files as they are saved, or starts again |
| `Space u F` | Toggle Format on Save (this buffer) | Does the same for this file alone |
| `Space u w` | Toggle Wrap | Wraps long lines at the window's edge, or stops |
| `Space u s` | Toggle Spelling | Underlines misspelt words, or stops |
| `Space u z` | Toggle Zen Mode | Hides everything but the text, or brings it back |
| `Space u u` | Undo Tree | Shows every earlier state of the file, to return to any of them |

## Outside the menus

| Key | Description | What it does |
| --- | --- | --- |
| `Esc` | Escape and Clear hlsearch | Leaves insert mode, and clears the highlight a search leaves behind |
| `Ctrl-/` | Terminal (Root Dir) | Opens a terminal at the project's top folder; pressed in the terminal, hides it |
| `Alt-j` | Move Down | Moves the line, or the selected lines, down one; `Alt-k` moves them up |
| `Ctrl-Space` | Grow Selection by Syntax | Selects the code under the cursor, a larger piece at each press |
| `Alt-Down` | Add Cursor Below | Adds a cursor on the line below, so typing goes to both; `Esc` removes the extra ones |
| `Space n` | Notification History | Shows the messages that flashed past |
| `Space N` | News | Opens the news reader |
| `Space l` | Lazy | Opens Lazy, which lists the plugins |
| `Space ?` | Buffer Keymaps (which-key) | Lists the keys that belong to this file |

## Ghostty's keys

Ghostty, the terminal Neovim runs in, keeps its own keys, and none of them reaches Neovim. Command is the ⌘ key.

| Key | What it does |
| --- | --- |
| `Command-T` | Opens a new tab |
| `Command-N` | Opens a new window |
| `Command-D` | Splits the current pane, with the new one to the right |
| `Command-Shift-D` | Splits the current pane, with the new one below |
| `Command-[` and `Command-]` | Moves to the previous or the next split |
| `Command-Option` with an arrow | Moves to the split in that direction |
| `Command-Shift-Enter` | Zooms the current split to fill the window, and back |
| `Command-Shift-[` and `Command-Shift-]` | Moves to the previous or the next tab |
| `Command-1` to `Command-8` | Moves to that tab; `Command-9` moves to the last |
| `Command-W` | Closes the current split, or the tab when it holds one pane, asking first while a program such as Neovim is running in it |
| `Command-=` and `Command-minus` | Makes the text bigger or smaller; `Command-0` returns it to 16 points |
| `Command-,` | Opens Ghostty's settings file for editing |
| `Command-Shift-,` | Reads the settings file again, so a change shows without restarting |

## What catches people out

Typing in normal mode runs commands. If text vanishes or jumps about as you type, you were in normal mode: press `Esc`, then `u` until the file is as it was, then `i` and type again.

`s` is Flash Jump here. Older Vim tutorials teach it as deleting a character and typing in its place, which `c l` still does.

Some keys belong to a file rather than to Neovim. The language server's keys, `g d`, `K` and the rest of the Code table, appear once the file's server is running; `] h` and the `Space g h` keys appear once git tracks the file; `Space c b` is there only in LaTeX files and `Space c p` only in Markdown. `Space ?` lists what the file in front of you has.

Files are formatted as they are saved. If a save rearranges more than you wanted, `u` takes the formatting back, and `Space u F` stops it for that file alone.

A running Neovim keeps the configuration it started with. After changing a file under `lua/`, quit with `Space q q` and start Neovim again, and `Space q s` brings the files back.

After Homebrew updates Neovim, the first start says the fast check is running in the background, and about a minute later says whether the configuration still passes. The editor works as usual meanwhile. A failure names the folder to run `scripts/check` in, which shows the test that failed, and the check runs again at every start until it passes.

## What still needs a person

Run `gh auth login` once, so `Space g p` and the other GitHub keys can reach GitHub. `Space c x` needs Intel's manual, which the Mac's setup downloads once you say yes. Anything else `scripts/check --full` reports as needing a person comes with the line that does it.
