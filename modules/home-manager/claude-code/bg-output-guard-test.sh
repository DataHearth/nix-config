#!/usr/bin/env bash
# Regression cases for bg-output-guard.sh: `<verdict><TAB><command>`.
set -u
guard=$(dirname "$0")/bg-output-guard.sh
fail=0

check() {
  local want=$1 cmd=$2 out got
  out=$(jq -n --arg c "$cmd" '{tool_input: {command: $c, run_in_background: true}}' | bash -o nounset -o pipefail "$guard")
  got=allow
  [ -n "$out" ] && got=deny
  if [ "$got" != "$want" ]; then
    printf 'FAIL want=%s got=%s  %s\n' "$want" "$got" "$cmd"
    fail=1
  fi
}

while IFS=$'\t' read -r want cmd; do
  [ -n "$want" ] && check "$want" "$(printf '%b' "$cmd")"
done <<'EOF'
deny	make > log
deny	make >log
deny	make>log
deny	make 1>log
deny	make >> log
deny	make &> log
deny	make &>> log
deny	make >| log
deny	make 2> err.log
deny	make 2>/dev/null
deny	make 1>/dev/null
deny	make >/dev/null 2>&1
deny	make 2>&1 >/dev/null
deny	make 2>&1 1>log
deny	make >&-
deny	make >&3
deny	make > "$S/server.log" 2>&1
deny	make 2>&1 | tee log >/dev/null
deny	make |& tee log >/dev/null
deny	make | cat > log
deny	{ make; } > log
deny	( make ) > log 2>&1
deny	exec > log 2>&1; make
deny	for i in 1 2; do make; done > log
deny	while true; do date; sleep 1; done >/dev/null
deny	make > >(cat > log)
deny	time make > log
deny	sh -c 'make > log'
deny	nix develop -c bash -c 'cargo build > log 2>&1'
deny	kubectl exec pod -- sh -c 'make > /tmp/log'
deny	docker exec c sh -c "make 2>/dev/null"
deny	ssh host 'make > log'
deny	jj st >/dev/null; nix build -L .#foo 2>&1
deny	x=$(make 2> err.log); echo "$x"
deny	until curl -s localhost >/dev/null; do sleep 1; done; make >/dev/null
deny	if true; then make > log; fi
deny	jq '.a > 1' f.json
deny	make 2>&1 | tail -30
deny	make 2>&1 | tail -n 5
deny	make | head -8
deny	make |& tail
deny	a | tail -5; b 2>&1
deny	ssh host 'make | tail -5'
deny	nohup make
deny	ssh host "nohup make"
deny	setsid make
deny	setsid -f make
deny	make & disown
deny	make &
deny	make 2>&1 &
allow	make
allow	make 2>&1
allow	make 1>&2
allow	echo err >&2
allow	make 2>&1 | tee log
allow	make |& tee log
allow	make 2>&1 | tee "log file" | rg error
allow	make 2>&1 | rg -v warning
allow	make < input
allow	cat <<EOF
allow	cargo run -- --flag=value
allow	rg '->' src
allow	nohupx make
allow	make --nohup
allow	make; echo done
allow	make && echo ok || echo fail
allow	a & b & wait
allow	make 2>&1 && echo '&'
allow	tail -f log
allow	tail -F /var/log/x
allow	kubectl logs pod | tail -f
allow	make 2>&1 | tail -n 100 -f
allow	journalctl -f | tail --follow
allow	x=$(make 2>/dev/null); echo "$x"
allow	echo "$(date 2>/dev/null)"
allow	n=$(kubectl get pods 2>&1 | tail -1); echo "$n"
allow	echo $(( $(date +%s) + 5 ))
allow	until curl -s localhost:8080 >/dev/null; do sleep 1; done; make
allow	until xh -q localhost 2>/dev/null; do :; done; exec python3 app.py
allow	while ! pg_isready >/dev/null 2>&1; do sleep 1; done
allow	until [ "$(wc -l < f 2>/dev/null)" -ge 9 ] 2>/dev/null; do sleep 5; done; echo READY
allow	until kubectl exec p -- sh -c 'grep -q x /l; true' 2>/dev/null; do sleep 20; done; date
allow	while read -r u; do\n  h=$(xh GET "$u" 2>/dev/null)\n  echo "$h"\ndone < urls
allow	until curl -sf x >/dev/null\ndo sleep 1\ndone\nmake
allow	if command -v foo >/dev/null; then foo; fi
allow	command -v foo >/dev/null && foo
allow	command -v foo &>/dev/null || echo missing
allow	> out.txt; make 2>&1 | tee -a out.txt
allow	: > out.txt\nmake 2>&1
allow	out=f.tsv; > "$out"; make
EOF

[ "$fail" = 0 ] && echo "all cases pass"
exit "$fail"
