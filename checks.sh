#!/bin/bash
# Flow Energy site — guardrail acceptance tests (from the Kimi handover +
# Jacko's rulings, 19 Aug 2026). Run before every push: ./checks.sh
# Exit 0 = all guardrails hold. Any failure prints the broken rule.
set -u
F=index.html
fail=0
say(){ printf '%-58s %s\n' "$1" "$2"; }
ck(){ if [ "$2" = "0" ]; then say "$1" "PASS"; else say "$1" "FAIL"; fail=1; fi }

# ── Ruling ②: no dates for Solaris Two / Three, anywhere ──────────────
n=$(grep -cE '2036|2037|2038|2039|2040' $F); ck "No 2036-2040 dates on the page" $((n>0?1:0))
n=$(awk '/Solaris Two|Solaris Three/{f=1} f&&/P50|P80/{c++} /<\/(div|tr|section)>/{f=0} END{print c+0}' $F)
ck "No P50/P80 attached to Two or Three" $((n>0?1:0))

# ── P50/P80 explainer must stay byte-identical ────────────────────────
n=$(grep -c 'P50 means we estimate a 50% chance of hitting the date, P80 an 80% chance of the later one' $F)
ck "P50/P80 explainer sentence unchanged" $((n==1?0:1))

# ── Ruling ①: siting truth ────────────────────────────────────────────
n=$(grep -c 'New England' $F);                 ck "Solaris Two region is New England" $((n>=1?0:1))
n=$(grep -ci 'coalfields' $F);                 ck "No 'coalfields' node naming" $((n>0?1:0))
n=$(grep -c 'Latrobe Valley, VIC' $F);         ck "Latrobe never a committed node" $((n>0?1:0))

# ── Copy nits (both accepted) ─────────────────────────────────────────
n=$(grep -ci 'robotic' $F);                    ck "No robotic-installation claim" $((n>0?1:0))
n=$(grep -c 'took a decade to learn' $F);      ck "No unauditable decade claim" $((n>0?1:0))

# ── Ruling ④: tier naming — plain words, no Tier-N badges ────────────
n=$(grep -cE 'Tier [123] —|Tier [123] badge' $F); ck "No 'Tier N' evidence badges" $((n>0?1:0))

# ── Journal No. 01 must be untouched (hash of article block) ─────────
awk '/<article class="article" id="no-01">/,/<\/article>/' $F | md5 -q > /tmp/no01.now
if [ -f .no01.md5 ]; then
  if diff -q /tmp/no01.now .no01.md5 >/dev/null; then say "Journal No. 01 byte-identical" "PASS"; else say "Journal No. 01 byte-identical" "FAIL"; fail=1; fi
else
  cp /tmp/no01.now .no01.md5; say "Journal No. 01 baseline recorded" "PASS"
fi

# ── Standing invariants ───────────────────────────────────────────────
n=$(grep -c 'Estimates from our published cost reference, August 2026. We will update this chart when supplier quotes arrive.' $F)
ck "Capital-bar caption verbatim" $((n==1?0:1))
n=$(grep -c 'Concept animation — Solaris One is in development' $F)
ck "Hero animation caption present" $((n==1?0:1))
n=$(grep -c 'Photography via Wikimedia Commons' $F)
ck "Attribution footer present" $((n==1?0:1))
n=$(grep -c 'upload.wikimedia.org' $F)
ck "No hotlinked images" $((n>0?1:0))
n=$(grep -c 'Flow Energy — solar parks with storage' $F)
ck "Title stays plural (parks)" $((n>=1?0:1))

exit $fail
