"""Firestore helper utilities for the ADK agent."""

from __future__ import annotations

import os
import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import firebase_admin
from google.auth.exceptions import DefaultCredentialsError
from firebase_admin import credentials, firestore

logger = logging.getLogger(__name__)

OVERVIEW_COLLECTIONS = [
    "patients",
    "longevity_data_overview",
    "pillar_mappings",
    "actionable_opportunities",
    "engagement_queries",
]

LEGACY_COLLECTIONS = [
    "patients",
    "patient_profiles",
    "coach_context",
    "goals",
    "care_plans",
]


def _flag_enabled(*names: str) -> bool:
    return any(os.getenv(name, "").lower() in {"1", "true", "yes", "on"} for name in names)


def _get_env_value(*names: str) -> Optional[str]:
    """Return the first non-empty environment value for the provided names."""
    for name in names:
        value = os.getenv(name)
        if value:
            return value
    return None


def _get_project_id() -> Optional[str]:
    """Resolve the Firebase project id from explicit config or Cloud Run defaults."""
    return _get_env_value("FIREBASE_PROJECT_ID", "GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT")


def _get_database_id() -> str:
    """Resolve the Firestore database id, defaulting to the standard database."""
    return os.getenv("FIRESTORE_DATABASE_ID", "(default)")


def _is_debug_enabled() -> bool:
    return _flag_enabled("AGENT_DEBUG")


def _is_firestore_debug_enabled() -> bool:
    return _flag_enabled("AGENT_DEBUG", "AGENT_DEBUG_FIRESTORE")


def _credentials_diagnostics() -> Dict[str, Any]:
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    return {
        "present": bool(cred_path),
        "basename": os.path.basename(cred_path) if cred_path else None,
        "exists": os.path.exists(cred_path) if cred_path else None,
    }


def _exception_details(exc: Exception, *, stage: str, collection: str | None = None) -> Dict[str, Any]:
    return {
        "stage": stage,
        "collection": collection,
        "type": type(exc).__name__,
        "message": str(exc),
        "repr": repr(exc),
    }


def get_runtime_diagnostics() -> Dict[str, Any]:
    """Expose safe runtime diagnostics for debugging env wiring."""
    return {
        "project_id_resolved": _get_project_id(),
        "database_id_resolved": _get_database_id(),
        "env_present": {
            "FIREBASE_PROJECT_ID": bool(os.getenv("FIREBASE_PROJECT_ID")),
            "GOOGLE_CLOUD_PROJECT": bool(os.getenv("GOOGLE_CLOUD_PROJECT")),
            "GCLOUD_PROJECT": bool(os.getenv("GCLOUD_PROJECT")),
            "GOOGLE_APPLICATION_CREDENTIALS": bool(os.getenv("GOOGLE_APPLICATION_CREDENTIALS")),
            "AGENT_DEBUG": os.getenv("AGENT_DEBUG", ""),
            "AGENT_DEBUG_FIRESTORE": os.getenv("AGENT_DEBUG_FIRESTORE", ""),
            "AGENT_DEBUG_CHAT": os.getenv("AGENT_DEBUG_CHAT", ""),
        },
        "credentials_file": _credentials_diagnostics(),
        "firebase_app_initialized": bool(firebase_admin._apps),  # pylint: disable=protected-access
        "firebase_app_names": list(firebase_admin._apps.keys()),  # pylint: disable=protected-access
    }


def _get_or_init_app() -> firebase_admin.App:
    """Initialize Firebase Admin once, then reuse the existing app."""
    if firebase_admin._apps:  # pylint: disable=protected-access
        return firebase_admin.get_app()

    project_id = _get_project_id()
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    if _is_debug_enabled():
        logger.info(
            "Firestore init start | project_id=%s | database_id=%s | has_credentials_file=%s",
            project_id,
            _get_database_id(),
            bool(cred_path),
        )

    if cred_path:
        cred = credentials.Certificate(cred_path)
        if project_id:
            return firebase_admin.initialize_app(cred, {"projectId": project_id})
        return firebase_admin.initialize_app(cred)

    # Uses Application Default Credentials when no explicit JSON key path is set.
    if project_id:
        return firebase_admin.initialize_app(options={"projectId": project_id})
    return firebase_admin.initialize_app()


def get_firestore_client() -> firestore.Client:
    """Return a Firestore client with initialized Firebase app."""
    _get_or_init_app()
    database_id = _get_database_id()
    if _is_debug_enabled():
        logger.info("Firestore client create | project_id=%s | database_id=%s", _get_project_id(), database_id)
    if database_id == "(default)":
        return firestore.client()
    return firestore.client(database_id=database_id)


def push_test_message(message: str) -> Dict[str, Any]:
    """Write a test payload to Firestore and return metadata about the write."""
    client = get_firestore_client()
    doc_ref = client.collection("agent_test_messages").document()

    payload = {
        "message": message,
        "source": "gcp-adk-agent",
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    doc_ref.set(payload)

    return {
        "ok": True,
        "collection": "agent_test_messages",
        "document_id": doc_ref.id,
        "project_id": _get_project_id() or "auto-detect",
        "database_id": _get_database_id(),
    }


def _normalize_overview_context(data: Dict[str, Any]) -> Dict[str, Any]:
    overview = data.get("longevity_data_overview") or {}
    pillar_mappings = data.get("pillar_mappings") or {}
    opportunities = data.get("actionable_opportunities") or {}
    engagement = data.get("engagement_queries") or {}
    return {
        "schema_version": overview.get("schema_version", "overview_v1"),
        "context_format": "overview_v1",
        "available_datasets": overview.get("available_datasets") or [],
        "primary_focus": (overview.get("insights_strategy") or {}).get("primary_focus") or {},
        "pillar_mappings": pillar_mappings.get("pillars") or [],
        "opportunities": opportunities.get("opportunities") or [],
        "engagement_prompts": engagement.get("prompts") or [],
    }


def _normalize_legacy_context(data: Dict[str, Any]) -> Dict[str, Any]:
    coach_context = data.get("coach_context") or {}
    goals = data.get("goals") or {}
    care_plans = data.get("care_plans") or {}
    return {
        "schema_version": "legacy_v1",
        "context_format": "legacy_v1",
        "available_datasets": [],
        "primary_focus": coach_context.get("primary_focus") or {},
        "pillar_mappings": [],
        "opportunities": care_plans.get("actions") or [],
        "engagement_prompts": coach_context.get("suggested_prompts") or goals.get("activeGoals") or [],
    }


def _normalize_context(data: Dict[str, Any]) -> Dict[str, Any]:
    if "longevity_data_overview" in data:
        return _normalize_overview_context(data)
    return _normalize_legacy_context(data)


def get_patient_firebase_context(patient_id: str) -> Dict[str, Any]:
    """Fetch patient-specific context from common Firestore collections."""
    collections: List[str] = []
    for collection_name in OVERVIEW_COLLECTIONS + LEGACY_COLLECTIONS:
        if collection_name not in collections:
            collections.append(collection_name)
    diagnostics: Dict[str, Any] = {
        "runtime": get_runtime_diagnostics(),
        "collection_reads": [],
    }

    try:
        client = get_firestore_client()
    except Exception as exc:  # pylint: disable=broad-except
        response = {
            "patient_id": patient_id,
            "project_id": _get_project_id() or "auto-detect",
            "database_id": _get_database_id(),
            "collections_checked": collections,
            "collections_found": [],
            "data": {},
            "normalized": _normalize_context({}),
            "firebase_available": False,
            "lookup_status": "unavailable",
            "failure_stage": "client_init",
            "warning": _firebase_unavailable_reason(exc),
        }
        if _is_firestore_debug_enabled():
            diagnostics["failure"] = _exception_details(exc, stage="client_init")
            response["diagnostics"] = diagnostics
        return response

    data: Dict[str, Any] = {}
    warning: Optional[str] = None
    failure_stage: Optional[str] = None

    for collection_name in collections:
        read_debug: Dict[str, Any] = {"collection": collection_name}
        try:
            snapshot = client.collection(collection_name).document(patient_id).get()
            read_debug["exists"] = bool(snapshot.exists)
            if snapshot.exists:
                document = snapshot.to_dict() or {}
                data[collection_name] = document
                read_debug["field_count"] = len(document)
            else:
                read_debug["field_count"] = 0
        except Exception as exc:  # pylint: disable=broad-except
            failure_stage = f"collection_read:{collection_name}"
            warning = f"{type(exc).__name__}: {exc}"
            read_debug["error"] = _exception_details(
                exc,
                stage=failure_stage,
                collection=collection_name,
            )
            logger.exception(
                "Firestore context lookup failed | patient_id=%s | collection=%s | project_id=%s | database_id=%s",
                patient_id,
                collection_name,
                _get_project_id(),
                _get_database_id(),
            )
            if _is_firestore_debug_enabled():
                diagnostics["collection_reads"].append(read_debug)
                diagnostics["failure"] = read_debug["error"]
            break
        if _is_firestore_debug_enabled():
            diagnostics["collection_reads"].append(read_debug)

    response = {
        "patient_id": patient_id,
        "project_id": _get_project_id() or "auto-detect",
        "database_id": _get_database_id(),
        "collections_checked": collections,
        "collections_found": list(data.keys()),
        "data": data,
        "normalized": _normalize_context(data),
        "firebase_available": warning is None,
        "lookup_status": "partial" if warning and data else ("unavailable" if warning else "ok"),
    }
    if failure_stage:
        response["failure_stage"] = failure_stage
    if warning:
        response["warning"] = warning
    if _is_firestore_debug_enabled():
        response["diagnostics"] = diagnostics
    elif _is_debug_enabled():
        response["diagnostics"] = {"runtime": get_runtime_diagnostics()}
    return response


def _firebase_unavailable_reason(exc: Exception) -> str:
    if isinstance(exc, DefaultCredentialsError):
        return "Application Default Credentials are not configured."
    return str(exc)
