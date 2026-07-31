#!/usr/bin/env bash
# fix-zenn-slugs.sh - normaliza nomes de arquivo de artigos para as regras de slug do Zenn.
#
# Regra do Zenn: o nome do arquivo sem .md e o slug do artigo, e precisa casar
# com ^[a-z0-9_-]{12,50}$. O Zenn aborta o deploy inteiro no primeiro arquivo
# invalido que encontrar, entao um unico nome errado bloqueia todos os artigos.
#
# Uso:
#   ./fix-zenn-slugs.sh            # dry-run: so mostra o que faria
#   ./fix-zenn-slugs.sh --apply    # aplica os renames com git mv
#   ./fix-zenn-slugs.sh --check    # so valida; exit 1 se houver invalido (para CI/hook)
#
# Rode na raiz do repositorio zenn_dev_articles.

set -euo pipefail

DIR="${ZENN_ARTICLES_DIR:-articles}"
MODE="dry"
case "${1:-}" in
  --apply) MODE="apply" ;;
  --check) MODE="check" ;;
  ""|--dry-run) MODE="dry" ;;
  *) echo "uso: $0 [--apply|--check|--dry-run]" >&2; exit 2 ;;
esac

[ -d "$DIR" ] || { echo "erro: diretorio '$DIR' nao encontrado (rode na raiz do repo)" >&2; exit 2; }

# Deriva um slug valido a partir do nome atual:
#   minusculas -> troca tudo que nao for [a-z0-9_-] por '-' -> colapsa '-' repetido
#   -> remove '-' das pontas -> trunca em 50.
# Nao inventa caracteres para atingir o minimo de 12: nome curto demais e decisao
# editorial sua, nao do script.
slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9_-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-50 \
    | sed -E 's/-+$//'
}

invalid=0
renamed=0
manual=0

while IFS= read -r path; do
  file="$(basename "$path")"
  slug="${file%.md}"

  # Ja valido? segue o baile.
  if printf '%s' "$slug" | grep -Eq '^[a-z0-9_-]{12,50}$'; then
    continue
  fi

  invalid=$((invalid + 1))
  new_slug="$(slugify "$slug")"

  # Diagnostico do porque falhou.
  reasons=""
  printf '%s' "$slug" | grep -q '[^a-z0-9_-]' && reasons="caracteres invalidos"
  if [ "${#slug}" -lt 12 ]; then
    reasons="${reasons:+$reasons, }curto demais (${#slug} < 12)"
  fi
  [ "${#slug}" -gt 50 ] && reasons="${reasons:+$reasons, }longo demais (${#slug} > 50)"

  # Se nem o slug normalizado atinge o minimo, o script nao tem como adivinhar.
  if [ "${#new_slug}" -lt 12 ]; then
    printf 'MANUAL  %-52s %s\n' "$file" "$reasons -- '$new_slug' ainda tem ${#new_slug} chars, renomeie a mao"
    manual=$((manual + 1))
    continue
  fi

  new_file="${new_slug}.md"
  if [ "$new_file" = "$file" ]; then
    continue
  fi

  # Colisao com um arquivo que ja existe e que NAO e o mesmo arquivo diferindo
  # so por maiusculas/minusculas (em FS case-insensitive o teste -e da falso positivo).
  if [ -e "$DIR/$new_file" ] && [ "$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$new_file" | tr '[:upper:]' '[:lower:]')" ]; then
    printf 'CONFLITO %-51s -> %s ja existe, pulando\n' "$file" "$new_file"
    manual=$((manual + 1))
    continue
  fi

  printf 'RENAME  %-52s -> %s   (%s)\n' "$file" "$new_file" "$reasons"

  if [ "$MODE" = "apply" ]; then
    # Duas etapas por causa do macOS/APFS case-insensitive: um git mv direto entre
    # nomes que so diferem no case e no-op ou erro. O nome intermediario forca o
    # git a registrar a mudanca de verdade.
    tmp="$DIR/.zenn-rename-tmp-$$"
    git mv -- "$DIR/$file" "$tmp"
    git mv -- "$tmp" "$DIR/$new_file"
    renamed=$((renamed + 1))
  fi
done < <(find "$DIR" -maxdepth 1 -name '*.md' | sort)

echo
if [ "$invalid" -eq 0 ]; then
  echo "OK: todos os slugs em '$DIR' sao validos."
  exit 0
fi

echo "$invalid arquivo(s) fora da regra; $manual precisa(m) de decisao manual."

case "$MODE" in
  check) exit 1 ;;
  apply)
    echo "$renamed renomeado(s) e staged. Revise com 'git status' e commite."
    [ "$manual" -gt 0 ] && exit 1
    ;;
  dry) echo "Nada foi alterado. Rode com --apply para aplicar." ;;
esac
exit 0
