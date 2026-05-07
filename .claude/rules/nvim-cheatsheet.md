# Neovim cheatsheet (Khazad-dum config)

Leader = space (`␣`). Reference for `modules/home-manager/neovim/`.

---

## Vim core

### Modes

- `i` insert before cursor | `a` after | `I` line start | `A` line end
- `o` new line below + insert | `O` above + insert
- `v` visual char | `V` visual line | `<C-v>` visual block
- `<Esc>` / `<C-[>` back to normal | `<C-c>` also (sometimes skips InsertLeave)

### Motion

- `h/j/k/l` left/down/up/right
- `w/W` next word start | `e/E` word end | `b/B` word back
- `0` line start | `^` first non-blank | `$` line end
- `gg` file start | `G` file end | `<num>G` or `:<num>` go to line
- `H/M/L` top/middle/bottom of screen
- `<C-d>/<C-u>` half-page down/up | `<C-f>/<C-b>` full page
- `zz` center cursor | `zt` cursor top | `zb` cursor bottom
- `%` jump matching `(/{/[`
- `f{c}` find next char | `F{c}` back | `t{c}` till before | `;` repeat | `,` repeat reverse
- `*` search word forward | `#` back | `n/N` next/prev match
- `''` jump back to last position | `` `. `` last edit | `<C-o>/<C-i>` jump list back/forward

### Edit (operators)

Operator + motion. `d` delete, `c` change, `y` yank, `=` indent, `>` indent right, `<` left.

- `dw` delete word | `d$` to end | `dd` line | `D` to end of line
- `cw` change word | `cc` line | `C` to end of line
- `yw` yank word | `yy` line | `Y` to end of line (mapped) or whole line
- `x` delete char | `r{c}` replace char | `R` replace mode
- `~` toggle case | `gu{motion}` lowercase | `gU{motion}` uppercase
- `J` join line below | `gJ` join no space
- `u` undo | `<C-r>` redo | `U` undo all on line
- `.` repeat last change

### Copy / paste / registers

- `y{motion}` yank | `yy` line | `p` paste after | `P` before
- `"+y` yank to system clipboard | `"+p` paste from it (your config: `clipboard=unnamedplus`, `y/p` already use system clipboard)
- `"_d` delete to black hole (no yank) | visual `p` already `"_dP` (configured)
- `"{r}y` yank to register `r` | `"{r}p` paste from `r`
- `:reg` list registers | `<C-r>{r}` paste reg in insert mode
- Special regs: `"0` last yank | `"1`–`"9` recent deletes | `"+` system clip | `"*` selection clip | `".` last inserted text | `"%` filename | `":` last cmd

### Search / replace

- `/text` forward search | `?text` back | `n/N` next/prev
- `*` / `#` search word under cursor
- `:%s/foo/bar/g` replace all in file | `:%s/foo/bar/gc` confirm each
- `:s/foo/bar/g` replace in current line
- visual `:s/foo/bar/g` replace in selection
- `:noh` clear highlight (also `<Esc>` mapped)

### Visual mode

- `v`/`V`/`<C-v>` enter visual char/line/block
- `o` swap cursor end of selection | `gv` re-select last visual
- `<C-v>I{text}<Esc>` insert before each line in block
- `<C-v>A{text}<Esc>` append after each line
- `:'<,'>` apply ex cmd to selection (auto-inserted by `:` in visual)

### Marks

- `m{a-z}` set local mark | `m{A-Z}` global mark (across files)
- `` `{mark} `` jump to exact pos | `'{mark}` to line
- `:marks` list

### Folds (vim core)

- `zf{motion}` create fold | `zd` delete | `zE` delete all
- `zo` open | `zc` close | `za` toggle (under cursor)
- `zR/zM` open/close all | `zr/zm` open/close one level
- `zj/zk` next/prev fold

### Windows

- `<C-w>s` hsplit | `<C-w>v` vsplit | `<C-w>q` close | `<C-w>o` only
- `<C-w>h/j/k/l` move (you have `<C-h/j/k/l>` mapped — same)
- `<C-w>=` equal sizes | `<C-w>_` max height | `<C-w>|` max width
- `<C-w>>/<` resize +/- width | `<C-w>+/-` height

### Buffers / tabs

- `:e file` open | `:b name` switch | `:bd` delete | `:bn/:bp` next/prev
- `:ls` list buffers | `:%bd|e#|bd#` close all but current
- `:tabnew` new tab | `gt/gT` next/prev tab | `:tabclose`

### Macros

- `q{r}` start record to register `r` | `q` stop
- `@{r}` replay | `@@` replay last | `<num>@{r}` replay N times

### Ex / cmdline

- `:!cmd` run shell | `:r !cmd` insert output | `:r file` insert file
- `:w` save | `:wq`/`ZZ` save+quit | `:q!`/`ZQ` force quit
- `q:` cmdline history window | `q/` search history
- `<C-r>"` paste yanked into cmdline | `<C-r>{r}` paste any register
- `:set ft=go` force filetype | `:e!` reload file from disk

### Indent / format

- `>>` indent line | `<<` unindent | `==` auto-indent line
- visual `>` `<` `=` apply to selection
- `gq{motion}` reformat (wrap)

---

## Files / search (telescope)

- `␣ff` find files | `␣fg` live grep | `␣fr` recent | `␣fb` buffers | `␣fh` help | `␣ft` todos
- Picker: `<C-q>` qflist | `<C-x>/<C-v>` hsplit/vsplit | `<C-u>/<C-d>` preview scroll

## Buffers / windows

- `S-h`/`S-l` prev/next buffer
- `␣bd` delete buffer (snacks, keeps window layout)
- `C-h/j/k/l` jump windows
- `:vsp`/`:sp` split right/below
- `␣w` save | `␣W` save all

## File manager (yazi)

- `␣-` open at current file | `␣cw` open at cwd | `C-Up` resume last yazi

## LSP (on attach)

- `K` hover (rounded border)
- `␣gd` definition | `␣gD` declaration | `␣gr` references
- `␣a` code action | `␣r` rename

## Diagnostics

- `]d`/`[d` next/prev diag (with float)
- `␣e` line diag float | `␣q` send diags to loclist
- `␣xx` workspace (trouble) | `␣xX` buffer | `␣cs` symbols | `␣cl` LSP panel
- `␣xL` loclist | `␣xQ` qflist | `␣xt` todos panel
- Inline UI: signs in signcolumn, full diag below current line, short virtual_text on others

## Folds (ufo)

- `za` toggle | `zR` open all | `zM` close all | `zr` open except comment/import
- `foldcolumn = auto:3` → only shows on fold lines

## Edit

- Comment: `gcc` line | `gc{motion}` | `gcap` paragraph | visual `gc`
- Surround: `ysiw"` add | `cs"'` change | `ds"` del | visual `S"`
- Autopairs: auto `()/{}/[]/""`
- Visual `</>` re-selects
- Visual `J/K` move lines down/up
- Visual `p` paste no-yank
- `<C-d>/<C-u>` half-page + auto-center
- `n/N` search next/prev + auto-center

## Textobjects (mini.ai + TS)

- `f` function — `vaf` whole | `vif` body
- `c` class/struct/interface — `vac` whole | `vic` inner
- `o` block (if/loop) — `vao` | `vio`
- `a` argument/param — `vaa` | `via`
- Defaults: `i"` `i'` `i)` `i]` `i}` `it` (tag) `i?` (prompt)
- Go specifics: `c` matches struct/interface declarations and struct literals

## Jump (flash)

- `s{c}{c}` then label → labeled forward jump
- `S` flash via TS nodes (function/class)
- `r` (operator mode) remote — e.g. `dr{flash}` deletes from remote position
- `R` flash TS search

## Git

- gitsigns inline blame on by default
- `␣gv` diffview (was ␣gd, moved due to LSP collision)
- `␣gh` file history | `␣gH` branch history

## Completion (blink, enter preset)

- `<Tab>/<S-Tab>` cycle | `<CR>` accept | `<C-Space>` trigger | `<C-e>` cancel

## Sessions (persistence)

- `␣qs` restore cwd session | `␣ql` last session | `␣qd` stop saving

## Notifications (snacks)

- `␣un` dismiss notifications

## Misc

- `␣;` dropbar pick (winbar symbol jump)
- `[;`/`];` context start/next
- `]t`/`[t` next/prev TODO comment
- `<Esc>` clear search highlight
- Format on save: ON via conform — `:ConformInfo` to debug
- Lint on save/read/InsertLeave via nvim-lint — manual `:lua require('lint').try_lint()`
- `:Lazy` plugin manager UI
- `:checkhealth` diagnose

## Built-in keymap discovery

- Press `<leader>` and **wait** → which-key shows leader subtree
- `<leader>?` → buffer-local maps only
- `:WhichKey` → full menu | `:WhichKey <leader>g` → subtree
- `:map` / `:nmap` / `:imap` → raw keymap dump
- `:verbose nmap K` → show binding + defining file
- `:help index` → vim default keymap reference
- `:help <plugin-name>` → plugin's own help
