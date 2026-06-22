{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.starship;
  jj = lib.getExe config.programs.jujutsu.package;
  git = lib.getExe config.programs.git.package;
  bash = lib.getExe pkgs.bash;
in
{
  options.home_modules.starship = {
    enable = lib.mkEnableOption "starship prompt with a self-contained jujutsu segment";

    gitModules = lib.mkOption {
      type = lib.types.enum [
        "disabled"
        "conditional"
        "native"
      ];
      default = "disabled";
      description = ''
        How starship's built-in git modules behave alongside the jj segment.
        starship's git modules cannot be disabled conditionally (`disabled` is a
        static bool — no `when`/detect option), so this picks the strategy:

          - "disabled": turn the native git modules off entirely so the jj
            segment owns the VCS prompt everywhere. Best when every repo is
            jj-colocated (no plain-git checkouts to account for).
          - "conditional": turn the native git modules off, then re-add a git
            branch + status fallback (a custom module) that renders only when
            NOT in a jj repo, so plain-git checkouts still show the branch and
            the native-style dirty symbols (=+!✘»?⇡⇣).
          - "native": leave the built-in git modules untouched — they render as
            usual and will appear next to the jj segment in colocated repos
            (i.e. no guard).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      # Custom modules render in name order: git (only outside jj), then jj.
      settings = lib.mkMerge [
        {
          # Self-contained jj segment (no starship-jj). Rendered by hand for
          # full control over spacing and content:
          #   <symbol> <nearest bookmark> ⇡ <distance> <change id> <state…>
          # Three `jj log` calls: nearest ancestor bookmark, distance to it,
          # and @ (change id + working-copy state). The symbol is emitted as
          # raw UTF-8 bytes (U+F15C6) so the glyph can't be mangled in source;
          # ⇡ (U+21E1) is safe as a literal.
          custom.jj = {
            description = "jj segment: symbol, nearest bookmark + distance, change id, state";
            shell = [ bash ];
            when = "${jj} --ignore-working-copy root";
            command = ''
              j() { ${jj} log --no-graph --ignore-working-copy --color never "$@"; }
              bk=$(j -r 'heads(::@ & bookmarks())' -T 'bookmarks.map(|b| b.name()).join(",")')
              n=$(j -r 'heads(::@ & bookmarks())..@' -T '"x\n"' | grep -c x)
              raw=$(j -r @ -T 'change_id.shortest(8) ++ "|" ++ if(conflict,"conflict ") ++ if(divergent,"divergent ") ++ if(empty,"empty ") ++ if(hidden,"hidden ") ++ if(immutable,"immutable ")')
              IFS='|' read -r id states <<< "$raw"

              B=$'\033[34m'; M=$'\033[35m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; RST=$'\033[0m'
              seg="$B$(printf '\xf3\xb1\x97\x86')$RST"
              if [ -n "$bk" ]; then
                seg="$seg $M$bk$RST"
                [ "$n" -gt 0 ] && seg="$seg $M⇡ $n$RST"
              fi
              seg="$seg $Y$id$RST"
              for st in $states; do
                case $st in
                  conflict)  seg="$seg $R(CONFLICT)$RST";;
                  divergent) seg="$seg $C(DIVERGENT)$RST";;
                  empty)     seg="$seg $Y(EMPTY)$RST";;
                  hidden)    seg="$seg $Y(HIDDEN)$RST";;
                  immutable) seg="$seg $Y(IMMUTABLE)$RST";;
                esac
              done
              printf '%s' "$seg"
            '';
            format = "$output ";
            ignore_timeout = true;
          };
        }

        # Guard: disable the native git modules so they don't duplicate what the
        # jj segment already shows in colocated repos.
        (lib.mkIf (cfg.gitModules != "native") {
          git_branch.disabled = true;
          git_commit.disabled = true;
          git_state.disabled = true;
          git_status.disabled = true;
        })

        # Conditional fallback: re-add a git branch that renders only outside a
        # jj repo. `jj root` exits 0 inside a jj workspace; `!` flips it.
        (lib.mkIf (cfg.gitModules == "conditional") {
          custom.git = {
            description = "Git branch + status (shown only outside jj repos)";
            # Pin a clean bash so the script behaves the same regardless of the
            # interactive shell starship would otherwise reuse.
            shell = [ bash ];
            # Render only inside a git work tree that is NOT also a jj repo. The
            # work-tree check stops it from firing (and printing a bare "on ")
            # in plain directories; `jj root` exits 0 inside a jj workspace, so
            # `!` lets colocated repos fall through to the jj segment.
            when = "${git} rev-parse --is-inside-work-tree && ! ${jj} --ignore-working-copy root";
            # Reproduce the native git_status symbols (=✘»!+?⇡⇣) from a single
            # `git status` so plain-git checkouts keep branch + dirty state. jj
            # has no index, so "staged vs not committed" is meaningful only here.
            command = ''
              ${git} status --porcelain=v1 -b | ${pkgs.gawk}/bin/awk '
                NR==1 {
                  b=$0
                  sub(/^## /,"",b); sub(/\.\.\..*/,"",b)
                  sub(/ \(no branch\)/,"",b); sub(/^No commits yet on /,"",b)
                  branch=b
                  if ($0 ~ /ahead /)  ahead=1
                  if ($0 ~ /behind /) behind=1
                  next
                }
                {
                  x=substr($0,1,1); y=substr($0,2,1)
                  if (x=="?") untracked=1
                  else {
                    if (index("MTADRC",x))                                 staged=1
                    if (y=="M" || y=="T")                                  modified=1
                    if (x=="D" || y=="D")                                  deleted=1
                    if (x=="R" || x=="C")                                  renamed=1
                    if (x=="U"||y=="U"||(x=="A"&&y=="A")||(x=="D"&&y=="D")) conflict=1
                  }
                }
                END {
                  s=""
                  if (conflict)  s=s"="
                  if (deleted)   s=s"✘"
                  if (renamed)   s=s"»"
                  if (modified)  s=s"!"
                  if (staged)    s=s"+"
                  if (untracked) s=s"?"
                  if (ahead)     s=s"⇡"
                  if (behind)    s=s"⇣"
                  if (s=="") print branch; else print branch " " s
                }
              '
            '';
            format = "on [$output](bold purple) ";
          };
        })
      ];
    };
  };
}
