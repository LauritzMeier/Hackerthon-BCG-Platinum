# Documentation Index

This repository keeps product and architecture documentation intentionally structured and lightweight.

## Start Here

Read in this order:

1. [Product Brief](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/brief.md)
2. [Personas](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/personas.md)
3. [User Journeys](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/journeys.md)
4. [Longevity Compass](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/longevity-compass.md)
5. [Google-First MVP Architecture](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/architecture/google-first-mvp.md)
6. [ADR Index](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md)

## Structure

```text
docs/
  README.md
  product/
    brief.md
    personas.md
    journeys.md
    longevity-compass.md
  architecture/
    google-first-mvp.md
  adr/
    README.md
    0001-...
    ...
```

## Source Of Truth

- Product problem and hackathon goals belong in `docs/product/brief.md`.
- Persona segmentation belongs in `docs/product/personas.md`.
- User behavior and monetization flows belong in `docs/product/journeys.md`.
- Core app concept and surface design belong in `docs/product/longevity-compass.md`.
- Deployment direction and cloud decisions belong in `docs/architecture/`.
- Durable decisions belong in `docs/adr/`.

## Documentation Hygiene

- Prefer updating an existing source-of-truth document over adding a new standalone note.
- If a doc becomes redundant, merge or remove it.
- If an ADR is no longer the best expression of the current state, update its status or clarify its scope.

