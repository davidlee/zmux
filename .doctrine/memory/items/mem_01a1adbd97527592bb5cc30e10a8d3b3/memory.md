- A change to `dev-tools` changes the forms. `just forms` calls `~/flakes/bin/dev-envs-forms`,
  then prints the `quotient allow` lines. Approving is the operator's act. Until then,
  quotient calls here are refused with `form-unapproved`.
- dev-envs' `checks.project-pins` fails on any real project: it reads `nixpkgsRev`, which
  only its stub sets. Compare `dev-tools` store paths instead.
