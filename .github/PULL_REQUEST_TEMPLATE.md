## What
<!-- 1-2 lignes : ce qui change -->

## Why
Closes #<!-- numéro d'issue -->

## How to test
<!-- Commande/scénario à reproduire + output attendu -->

```bash
# exemple
echo "hello $USER" | ./minishell
# attendu : hello <login>
```

## Checklist
- [ ] `make re` compile sans warning
- [ ] `norminette src/ includes/` → 0 erreur
- [ ] Tests associés écrits et passent
- [ ] `valgrind` → aucun leak côté nous (readline OK)
- [ ] La branche est à jour avec `dev`
