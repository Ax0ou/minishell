#!/bin/bash
# tests/unit/test_robustness.sh
# Regressions trouvees par la campagne adversariale du 23/09.
# 1. Le lexer debordait de son buffer fixe de 4096 octets (segfault).
# 2. exp_var_replace etait quadratique (28 s pour 100 000 caracteres).
# 3. La recherche dans le PATH s'arretait au premier candidat non executable.

cd "$(dirname "$0")/../.."
source tests/lib.sh

echo "═══ Robustesse : lignes longues (ex-segfault) ═══"

for n in 4095 4096 8192 100000; do
	word=$(python3 -c "print('a' * $n)")
	printf 'echo %s\n' "$word" | $SHELL_BIN > /dev/null 2>&1
	code=$?
	assert_eq "mot de $n caracteres : pas de crash" "0" "$code"
done

word=$(python3 -c "print('a' * 5000)")
out=$(printf 'echo %s\n' "$word" | $SHELL_BIN 2>/dev/null | _strip_prompt)
assert_eq "mot de 5000 caracteres : sortie complete" "5000" "${#out}"

quoted=$(python3 -c "print('b' * 8000)")
printf 'echo "%s"\n' "$quoted" | $SHELL_BIN > /dev/null 2>&1
assert_eq "mot quote de 8000 caracteres : pas de crash" "0" "$?"

python3 -c "print('echo ' + ' '.join(['x'] * 10000))" | $SHELL_BIN > /dev/null 2>&1
assert_eq "10 000 arguments : pas de crash" "0" "$?"

python3 -c "print('echo ' + '\"' * 500)" | $SHELL_BIN > /dev/null 2>&1
assert_eq "500 guillemets : erreur de syntaxe, pas de crash" "0" "$?"

echo "═══ Robustesse : l'expansion ne doit pas etre quadratique ═══"

# timeout(1) vient des coreutils GNU : absent de macOS, present sous le nom
# gtimeout si l'utilisateur a installe coreutils. On s'en passe s'il manque,
# la mesure du temps ecoule reste l'assertion qui compte.
TIMEOUT=""
if command -v timeout > /dev/null 2>&1; then
	TIMEOUT="timeout 30"
elif command -v gtimeout > /dev/null 2>&1; then
	TIMEOUT="gtimeout 30"
fi

big=$(python3 -c "print('a' * 200000)")
start=$SECONDS
printf 'echo %s\n' "$big" | $TIMEOUT $SHELL_BIN > /dev/null 2>&1
code=$?
elapsed=$((SECONDS - start))
assert_eq "200 000 caracteres : sortie normale" "0" "$code"
if [ "$elapsed" -le 5 ]; then
	printf "  ${C_GREEN}✓${C_RESET} 200 000 caracteres en %s s (lineaire)\n" "$elapsed"
	PASS=$((PASS + 1))
else
	printf "  ${C_RED}✗${C_RESET} 200 000 caracteres en %s s — l'expansion a reregresse\n" "$elapsed"
	FAIL=$((FAIL + 1))
	FAILED_TESTS+=("expansion lineaire")
fi

echo "═══ Robustesse : recherche dans le PATH comme bash ═══"

FIX=$(mktemp -d)
mkdir -p "$FIX/gauche" "$FIX/droite" "$FIX/gauche/collision"
printf '#!/bin/sh\necho DROITE\n' > "$FIX/droite/cible"
chmod +x "$FIX/droite/cible"
printf 'pas executable\n' > "$FIX/gauche/cible"
chmod 644 "$FIX/gauche/cible"
printf '#!/bin/sh\necho DROITE2\n' > "$FIX/droite/collision"
chmod +x "$FIX/droite/collision"
printf '#!/bin/sh\necho GAUCHE\n' > "$FIX/gauche/ordre"
printf '#!/bin/sh\necho DROITE3\n' > "$FIX/droite/ordre"
chmod +x "$FIX/gauche/ordre" "$FIX/droite/ordre"

P="$FIX/gauche:$FIX/droite"

out=$(printf 'export PATH=%s\ncible\n' "$P" | $SHELL_BIN 2>/dev/null | _strip_prompt)
assert_eq "un fichier non executable ne masque pas le binaire suivant" "DROITE" "$out"

out=$(printf 'export PATH=%s\ncollision\n' "$P" | $SHELL_BIN 2>/dev/null | _strip_prompt)
assert_eq "un repertoire du meme nom ne masque pas le binaire suivant" "DROITE2" "$out"

out=$(printf 'export PATH=%s\nordre\n' "$P" | $SHELL_BIN 2>/dev/null | _strip_prompt)
assert_eq "l'ordre gauche vers droite est respecte" "GAUCHE" "$out"

assert_exit "rien d'executable nulle part : 126" 126 \
	"export PATH=$FIX/gauche
cible"

assert_exit ".. n'est pas un executable : 127" 127 ".."

rm -rf "$FIX"

summary
