#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

ROOT = Path(".")
spec = importlib.util.spec_from_file_location(
    "validator", ROOT / "tools/validate_post_dh_rights_status.py"
)
validator = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(validator)

STATUS_PATH = ROOT / validator.STATUS
STATUS = json.loads(STATUS_PATH.read_text(encoding="utf-8"))
Mutation = Callable[[dict], None]


def expect_rejected(name: str, mutation: Mutation) -> None:
    candidate = copy.deepcopy(STATUS)
    mutation(candidate)
    try:
        validator.validate_status(candidate)
    except (validator.ValidationError, KeyError, TypeError, IndexError):
        return
    raise AssertionError(f"mutation survived: {name}")


def main() -> int:
    cases: list[tuple[str, Mutation]] = [
        ("schema drift", lambda d: d.__setitem__("schema_version", 5)),
        ("protected main drift", lambda d: d.__setitem__("protected_main", "0" * 40)),
        ("protected main semantics drift", lambda d: d.__setitem__("protected_main_semantics", "latest_dynamic_head")),
        ("playable release drift", lambda d: d.__setitem__("playable_release", "v0.2.0-alpha.3")),
        ("Alpha.3 candidate drift", lambda d: d["alpha3"].__setitem__("candidate_head_sha", "0" * 40)),
        ("Alpha.3 merge drift", lambda d: d["alpha3"].__setitem__("merged_main_sha", "0" * 40)),
        ("Alpha.3 package drift", lambda d: d["alpha3"].__setitem__("package_version", 2)),
        ("Alpha.3 export opened", lambda d: d["alpha3"].__setitem__("ordinary_export_included", True)),
        ("active current issue created", lambda d: d["current_release"].update({"issue": 130, "release_id": "future"})),
        ("current release activated", lambda d: d["current_release"].__setitem__("activation_authorized", True)),
        ("successor issue selected", lambda d: d["recommended_next_release"].__setitem__("github_issue", 130)),
        ("successor release selected", lambda d: d["recommended_next_release"].__setitem__("release_id", "DH-ART-001")),
        ("successor activated", lambda d: d["recommended_next_release"].__setitem__("activation_authorized", True)),
        ("Codex required prematurely", lambda d: d["recommended_next_release"].__setitem__("codex_required", True)),
        ("owner attestation removed", lambda d: d.__setitem__("pending_inputs", [])),
        ("owner attestation marked resolved", lambda d: d["pending_inputs"][0].__setitem__("state", "resolved")),
        ("rights resolution falsely complete", lambda d: d["pending_inputs"][0].__setitem__("rights_resolution_complete", True)),
        ("attestation implementation authorized", lambda d: d["pending_inputs"][0].__setitem__("implementation_authorized", True)),
        ("attestation identity drift", lambda d: d["pending_inputs"][0].__setitem__("input_id", "visual_art_ready")),
        ("visual baseline merge drift", lambda d: d["visual_planning"]["visual_baseline"].__setitem__("merged_main_sha", "0" * 40)),
        ("visual baseline identity drift", lambda d: d["visual_planning"]["visual_baseline"].__setitem__("baseline_id", "DH-VBL-002")),
        ("High Water merge drift", lambda d: d["visual_planning"]["presentation_study"].__setitem__("merged_main_sha", "0" * 40)),
        ("High Water candidate created", lambda d: d["visual_planning"]["presentation_study"].__setitem__("visual_candidate_created", True)),
        ("presentation family merge drift", lambda d: d["visual_planning"]["presentation_family"].__setitem__("merged_main_sha", "0" * 40)),
        ("presentation family ready", lambda d: d["visual_planning"]["presentation_family"].__setitem__("conversion_readiness", "ready")),
        ("presentation family implementation authorized", lambda d: d["visual_planning"]["presentation_family"].__setitem__("implementation_authorized", True)),
        ("presentation family candidate created", lambda d: d["visual_planning"]["presentation_family"].__setitem__("visual_candidate_created", True)),
        ("UX merge drift", lambda d: d["visual_planning"]["ux_advisory"].__setitem__("merged_main_sha", "0" * 40)),
        ("UX disposition promoted", lambda d: d["visual_planning"]["ux_advisory"].__setitem__("disposition", "approved_runtime_specification")),
        ("UX conversion ready", lambda d: d["visual_planning"]["ux_advisory"].__setitem__("conversion_readiness", "ready")),
        ("UX implementation authorized", lambda d: d["visual_planning"]["ux_advisory"].__setitem__("implementation_authorized", True)),
        ("UX candidate created", lambda d: d["visual_planning"]["ux_advisory"].__setitem__("candidate_id", "DH-UX-CAND-001")),
        ("rights merge drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("merged_main_sha", "0" * 40)),
        ("rights release identity drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("release_id", "DH-RIGHTS-REG-002")),
        ("rights record identity drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("record_id", "DH-RIGHTS-002")),
        ("rights disposition fully resolved", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("disposition", "fully_resolved")),
        ("rights prerequisite completed", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("prerequisite_state", "complete")),
        ("rights owner attestation removed", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("owner_attestation_required", False)),
        ("rights tier advanced to R2", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("max_rights_tier", "R2_planning")),
        ("rights direct pixels cleared", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("direct_pixel_use_cleared", True)),
        ("rights source art authorized", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("source_art_authorized", True)),
        ("rights runtime art authorized", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("runtime_art_authorized", True)),
        ("rights public distribution cleared", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("public_distribution_cleared", True)),
        ("rights legal clearance created", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("legal_clearance_created", True)),
        ("rights candidate created", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("candidate_created", True)),
        ("rights implementation authorized", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("implementation_authorized", True)),
        ("rights conversion ready", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("conversion_readiness", "ready")),
        ("rights nonproduction removed", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("reference_only_nonproduction", False)),
        ("rights asset count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("asset_count", 24)),
        ("rights PNG count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("png_count", 25)),
        ("rights JPEG count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("jpeg_with_png_extension_count", 0)),
        ("rights OpenAI count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("openai_family_count", 20)),
        ("rights Gemini count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("gemini_family_count", 5)),
        ("rights C2PA count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("local_c2pa_detected_not_authenticated_count", 17)),
        ("rights OpenAI attribution count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("openai_source_attribution_only_count", 4)),
        ("rights Gemini attribution count drift", lambda d: d["visual_planning"]["rights_provenance"].__setitem__("gemini_source_attribution_only_count", 3)),
        ("external binary admitted", lambda d: d["visual_planning"].__setitem__("external_binaries_in_git", True)),
        ("production art authorized", lambda d: d["visual_planning"].__setitem__("production_art_authorized", True)),
        ("runtime art authorized", lambda d: d["visual_planning"].__setitem__("runtime_art_authorized", True)),
        ("public asset release authorized", lambda d: d["visual_planning"].__setitem__("public_github_release_assets_authorized", True)),
        ("catalog opened", lambda d: d["production"].__setitem__("drowned_harbor_catalog_registered", True)),
        ("provider opened", lambda d: d["production"].__setitem__("drowned_harbor_provider_registered", True)),
        ("normal library opened", lambda d: d["production"].__setitem__("drowned_harbor_normal_library_visible", True)),
        ("ordinary export opened", lambda d: d["production"].__setitem__("drowned_harbor_ordinary_export_included", True)),
        ("ordinary play opened", lambda d: d["drowned_harbor"].__setitem__("ordinary_playable", True)),
        ("runtime implementation authorized", lambda d: d.__setitem__("runtime_implementation_authorized", True)),
        ("visual implementation authorized", lambda d: d.__setitem__("visual_implementation_authorized", True)),
        ("top-level UX implementation authorized", lambda d: d.__setitem__("ux_implementation_authorized", True)),
        ("human evidence claimed", lambda d: d.__setitem__("human_evidence_claimed", True)),
        ("issue 7 gate removed", lambda d: d["gates"].__setitem__(0, {"issue": 7, "purpose": "naming", "state": "closed"})),
        ("issue 39 gate changed", lambda d: d["gates"].__setitem__(1, {"issue": 39, "purpose": "human evidence", "state": "completed"})),
        ("PR 32 boundary removed", lambda d: d.__setitem__("unrelated_open_pull_requests", [])),
        ("Companion Undici drift", lambda d: d["companion_dependency_security"]["override_policy"].__setitem__("undici", "7.28.0")),
        ("preserved visual merge drift", lambda d: d["preserved_authorities"].__setitem__("dh_visual_baseline_merge", "0" * 40)),
        ("preserved High Water merge drift", lambda d: d["preserved_authorities"].__setitem__("dh_present_registration_merge", "0" * 40)),
        ("preserved family merge drift", lambda d: d["preserved_authorities"].__setitem__("dh_present_family_registration_merge", "0" * 40)),
        ("preserved UX merge drift", lambda d: d["preserved_authorities"].__setitem__("dh_ux_registration_merge", "0" * 40)),
        ("preserved rights merge drift", lambda d: d["preserved_authorities"].__setitem__("dh_rights_registration_merge", "0" * 40)),
    ]
    for name, mutation in cases:
        expect_rejected(name, mutation)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        for path in [validator.README, validator.INDEX, validator.ROADMAP]:
            target = temp / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / path, target)
        validator.validate_docs(temp)

        readme = temp / validator.README
        readme.write_text(
            readme.read_text(encoding="utf-8")
            + "\nRights and provenance fully resolved. Direct generated-pixel use authorized.\n",
            encoding="utf-8",
        )
        try:
            validator.validate_docs(temp)
        except validator.ValidationError:
            pass
        else:
            raise AssertionError("false rights completion claim survived")

        for path in [validator.README, validator.INDEX, validator.ROADMAP]:
            target = temp / path
            shutil.copy2(ROOT / path, target)
        for path in [validator.README, validator.INDEX, validator.ROADMAP]:
            target = temp / path
            text = target.read_text(encoding="utf-8")
            text = text.replace("Project Owner attestation", "Unspecified follow-up")
            text = text.replace("project owner attestation", "unspecified follow-up")
            text = text.replace("generation-session reconstruction", "unspecified reconstruction")
            target.write_text(text, encoding="utf-8")
        try:
            validator.validate_docs(temp)
        except validator.ValidationError:
            pass
        else:
            raise AssertionError("missing owner-attestation blocker survived")

        for path in [validator.README, validator.INDEX, validator.ROADMAP]:
            target = temp / path
            shutil.copy2(ROOT / path, target)
        roadmap = temp / validator.ROADMAP
        roadmap.write_text(
            roadmap.read_text(encoding="utf-8")
            + "\nStatus-reconciliation baseline:** `22b43893b7726e5c5bea1078aced1cf11e08049f`\n",
            encoding="utf-8",
        )
        try:
            validator.validate_docs(temp)
        except validator.ValidationError:
            pass
        else:
            raise AssertionError("stale post-UX baseline survived")

    print(f"Validated {len(cases) + 3} fail-closed post-DH-RIGHTS status mutations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
