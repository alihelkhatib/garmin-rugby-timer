# Release spec

## Purpose
Define the release checklist and exact steps to produce a signed PRG and submit to the Connect IQ Store.

## Checklist
1. Bump version in `manifest.xml` and update `strings/` as needed.
2. Update `resources/drawables/` and `layouts/` for store assets.
3. Run the build command to produce a signed PRG (see `specs/002-build/spec.md`).
4. Verify the PRG in simulator and at least one physical device.
5. Tag the release, create a GitHub release, and upload the PRG as an artifact.
6. If using CI to upload, ensure `CONNECTIQ_STORE_TOKEN` is populated and secure.

## Commands (example)
```bash
# bump manifest version (manual)
java -Xms1g -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" \
  -o bin/garminrugbytimer.prg -f monkey.jungle -y developer_key -d fenix6 -w
```

## Post-release
- Add the release notes and testing checklist to `project_technical_document.md`.
- Track store review and feedback in `log.md`.
