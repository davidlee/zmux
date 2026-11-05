# EVD-002: zmx list fields are tab-separated and cmd holds spaces

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

zmx 0.8.1 through the wrapper, 2026-11-06, with a scratch `ZMX_DIR`. A session started
with `zmx attach my_repo.1 sh -c 'sleep 5'` listed as:

    name=my_repo.1<TAB>...<TAB>cmd=sh -c 'sleep 5'<TAB>id=1<TAB>project=my_repo

The Emacs plugin split on `[\t ]+` and crashed on the token `-c`. Stubbed tests had
not caught this, because their fixtures held no multi-word `cmd`. Fixed in the Emacs
config, `0beaad3`.

## Not established

Whether zmx escapes a tab inside a `cmd`. Not tested.
