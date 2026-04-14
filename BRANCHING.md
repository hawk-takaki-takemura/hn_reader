# Branching Strategy

This repository uses a 3-branch workflow:

- `dev`: daily development branch
- `stg`: staging verification branch
- `main`: release branch

## Merge Flow

1. Create feature branch from `dev`
   - Example: `feature/add-hn-api-client`
2. Open PR to `dev`
3. After integration checks, open PR from `dev` to `stg`
4. Verify app behavior on staging
5. Open PR from `stg` to `main` for release

## Naming Convention

- Feature: `feature/<topic>`
- Fix: `fix/<topic>`
- Chore: `chore/<topic>`

## Recommended Rules

- Never commit directly to `main`
- Avoid direct commits to `stg` and `dev` when possible
- Use pull requests for all branch promotions
- Require at least one review before merging to `stg` and `main`
