"""Conversational phrasing for chat responses — persona-informed variety (see docs/product/personas.md)."""

from __future__ import annotations

import random
import re
from typing import Any, Dict, List


def humanize_metric_key(key: str) -> str:
    k = key.replace("_", " ").strip()
    k = re.sub(r"\b7d\b", "7-day", k)
    k = re.sub(r"\b30d\b", "30-day", k)
    k = re.sub(r"\bmmhg\b", "mmHg", k, flags=re.I)
    k = re.sub(r"\bmg l\b", "mg/L", k, flags=re.I)
    k = re.sub(r"\bhba1c\b", "HbA1c", k, flags=re.I)
    k = re.sub(r"\bhrv\b", "HRV", k, flags=re.I)
    k = re.sub(r"\bspo2\b", "SpO2", k, flags=re.I)
    return k


def format_signals_for_coach(signals: Dict[str, Any], max_items: int = 5) -> str:
    """Turn key_signals into short spoken-style clauses (not a raw dict repr)."""
    if not signals:
        return "the usual profile and wearable-style inputs we have on file"
    parts: List[str] = []
    for key, val in list(signals.items())[:max_items]:
        label = humanize_metric_key(key)
        if isinstance(val, float):
            if abs(val - round(val)) < 1e-6:
                vtxt = str(int(round(val)))
            else:
                vtxt = f"{val:.1f}".rstrip("0").rstrip(".")
        else:
            vtxt = str(val)
        parts.append(f"{label} around {vtxt}")
    if len(parts) == 1:
        return parts[0]
    if len(parts) == 2:
        return f"{parts[0]} and {parts[1]}"
    return ", ".join(parts[:-1]) + f", and {parts[-1]}"


def _pick(options: List[str]) -> str:
    return random.choice(options)


def opening_ack(message: str) -> str:
    """Light mirror of the user's ask — avoids identical 'You asked:' every time."""
    short = message.strip()
    if len(short) > 120:
        short = short[:117] + "…"
    return _pick(
        [
            f"Thanks for asking — I've read that as: “{short}”.",
            f"Good question. Here's how I'd frame it from your records: “{short}”.",
            f"On “{short}”, here's what your compass data supports.",
        ]
    )


def trend_phrase(trend: str) -> str:
    m = {
        "improving": _pick(["moving in a good direction", "trending upward lately", "showing improvement"]),
        "drifting": _pick(["softening a bit", "needs a steadier hand right now", "slipping compared with where we'd like it"]),
        "stable": _pick(["fairly steady", "holding about where it was", "flat for now — not alarming, but worth attention if the score is low"]),
    }
    return m.get(trend, trend)


def compose_priority_sections(
    intent: str,
    weakest: Dict[str, Any],
    strongest: Dict[str, Any],
    next_weakest: Dict[str, Any],
) -> List[str]:
    wn, ws = weakest["name"], weakest["score"]
    wtrend = trend_phrase(weakest["trend"])
    wsig = format_signals_for_coach(weakest.get("key_signals") or {})
    sn, ss = strongest["name"], strongest["score"]
    strend = trend_phrase(strongest["trend"])
    ssig = format_signals_for_coach(strongest.get("key_signals") or {})
    nn = next_weakest["name"]

    if intent == "weakness":
        lead = _pick(
            [
                f"If we're honest about the numbers, {wn} is the area that's carrying the most risk weight right now.",
                f"The pillar that most wants attention this cycle is {wn}.",
                f"I'd name {wn} as your biggest pressure point today — not to worry you, but so we focus effort where it helps.",
            ]
        )
        body = _pick(
            [
                f"You're sitting near a {ws} score there, with a trajectory that's {wtrend}. What I'm weighing most: {wsig}.",
                f"Score-wise that's about {ws}, {wtrend}. The signals I'd lean on in conversation: {wsig}.",
            ]
        )
        close = _pick(
            [
                f"That's why I'd line up support for {wn} before pouring energy into {nn} or your stronger pillars.",
                f"Practically: stabilize {wn} first — then {nn} — while keeping your stronger areas on maintenance.",
            ]
        )
        return [lead, body, close]

    if intent == "strength":
        lead = _pick(
            [
                f"{sn} is genuinely your bright spot right now — worth protecting.",
                f"If you want reassurance: {sn} is where you're most resilient at the moment.",
                f"Your relative strength is {sn}; I'd treat that as something to defend, not overhaul.",
            ]
        )
        body = _pick(
            [
                f"You're around {ss} there, {strend}. Behind that: {ssig}.",
                f"Roughly a {ss} with momentum that's {strend}. The data backing that: {ssig}.",
            ]
        )
        close = _pick(
            [
                "Keep the habits that built that — small tweaks only unless something changes.",
                "I'd avoid over-optimizing here; celebrate it and redirect discipline to the weaker pillar.",
            ]
        )
        return [lead, body, close]

    if intent == "deprioritize":
        lead = _pick(
            [
                f"You don't need {sn} to be the drama of the week — it's already in good shape.",
                f"It's natural to fixate on what's going well; I'd gently steer attention away from {sn} as a 'project'.",
                f"{sn} is strong enough that obsessing there probably won't move your longevity story much.",
            ]
        )
        body = _pick(
            [
                f"You're near {ss}, {strend}. In plain terms: {ssig}.",
                f"About {ss} on the compass, {strend}. Supporting detail: {ssig}.",
            ]
        )
        close = _pick(
            [
                f"Where I'd actually spend cognitive bandwidth is {wn} — that's the drag on your overall picture.",
                f"Better ROI on your time: lean into {wn} while {sn} stays on light maintenance.",
            ]
        )
        return [lead, body, close]

    # priority / default
    lead = _pick(
        [
            f"This week I'd anchor on {wn} — it's the lever with the clearest upside for your trajectory.",
            f"If you only pick one pillar to nurture right now, I'd make it {wn}.",
            f"Your compass is nudging toward {wn} as the main storyline — not forever, but for this phase.",
        ]
    )
    body = _pick(
        [
            f"Score there is about {ws}, {wtrend}. The bits of data I'd want you to know: {wsig}.",
            f"You're roughly at {ws}, which reads as {wtrend}. What stands out underneath: {wsig}.",
        ]
    )
    close = _pick(
        [
            f"Meanwhile {sn} is comparatively solid (~{ss}) — keep it steady without turning it into a second job.",
            f"{sn} is your cushion right now near {ss}, so you can afford to prioritize {wn} without guilt.",
            f"Less urgent: {sn} at about {ss}. Protect it, but don't let it steal focus from {wn}.",
        ]
    )
    return [lead, body, close]


def firebase_context_line(summary: str) -> str:
    if not summary or summary.startswith("No patient"):
        return _pick(
            [
                "I don't have rich Firestore context for you yet, so I'm leaning on the curated warehouse signals.",
                "Firestore is thin or empty for this id — I'm still grounding this in the structured health records we loaded.",
            ]
        )
    return _pick(
        [
            f"Behind the scenes: {summary}",
            f"For transparency on sources — {summary.lower()[0]}{summary[1:]}"
            if len(summary) > 1
            else f"For transparency on sources — {summary}",
            f"Context sync: {summary}",
        ]
    )


def safety_footers() -> List[str]:
    return [
        _pick(
            [
                "I'm coaching from lifestyle and record data — not diagnosing or replacing your clinician.",
                "Think of this as wellness coaching, not a medical opinion; flag anything worrying with your doctor.",
                "This is supportive guidance from your records, not a diagnosis or emergency triage.",
            ]
        ),
        _pick(
            [
                "If numbers look off or you feel unwell, that's a clinician conversation, not something to 'optimize' in chat.",
                "When in doubt about symptoms or meds, your care team wins over any app summary.",
            ]
        ),
    ]


def compose_pillar_sections(pillar: Dict[str, Any], firebase_summary: str) -> List[str]:
    name = pillar["name"]
    state, trend, score = pillar["state"], pillar["trend"], pillar["score"]
    expl = pillar.get("explanation") or ""
    sig = format_signals_for_coach(pillar.get("key_signals") or {})
    sources = ", ".join(pillar.get("data_sources") or [])

    lead = _pick(
        [
            f"Here's how I'd talk about {name} with you.",
            f"Let's zoom in on {name}.",
            f"On {name}, this is the picture your data paints.",
        ]
    )
    body = _pick(
        [
            f"You're in a '{state}' band with a {trend} trend and a score near {score}. {expl}",
            f"State reads as {state}, trend {trend}, score about {score}. In short: {expl}",
        ]
    )
    evidence = _pick(
        [
            f"The metrics I'd reference are {sig} (pulled from {sources}).",
            f"What I'm looking at: {sig}. Sources: {sources}.",
        ]
    )
    ctx = firebase_context_line(firebase_summary)
    unc = _pick(
        [
            "New labs or wearables can shift this — worth a quick revisit when data updates.",
            "Interpretation tightens as we get fresher rows; treat this as a snapshot.",
        ]
    )
    safe = _pick(
        [
            "Not a diagnosis — use this to steer habits and questions for your clinician.",
            "Coaching-only context; clinical decisions stay with your doctor.",
        ]
    )
    return [lead, body, evidence, ctx, unc, safe]


def compose_tailored_sections(payload: Dict[str, Any]) -> List[str]:
    context = payload["context"]
    claims = payload.get("claims", [])
    trade_offs = payload.get("trade_offs", [])
    actions = payload.get("next_best_actions", [])

    direction = context["overall_direction"]
    avg = context["average_score"]
    fb = context.get("firebase_context_summary") or ""

    intro = _pick(
        [
            f"Directionally you're {direction.replace('_', ' ')} with an average pillar score near {avg}. {firebase_context_line(fb)}",
            f"Big picture: things look {direction.replace('_', ' ')} overall (avg ~{avg}). {firebase_context_line(fb)}",
        ]
    )

    sections: List[str] = [intro]

    for claim in claims:
        ev = claim["evidence"][0]
        sig = format_signals_for_coach(ev.get("key_signals") or {})
        sections.append(
            _pick(
                [
                    f"{claim['claim']} {claim['why']} "
                    f"I'm seeing {ev['pillar_id'].replace('_', ' ')} at about {ev['score']}, {ev['trend']} — especially {sig}.",
                    f"{claim['claim']} Why I say that: {claim['why']} "
                    f"The evidence anchor is {ev['pillar_id'].replace('_', ' ')} (score {ev['score']}, {ev['trend']}); details: {sig}.",
                ]
            )
        )

    for t in trade_offs:
        sections.append(
            _pick(
                [
                    f"Trade-off to keep in mind — {t['topic'].lower()}: {t['detail']}",
                    f"One tension: {t['topic']}. {t['detail']}",
                ]
            )
        )

    for a in actions:
        sections.append(
            _pick(
                [
                    f"Suggestion: {a['action']} — {a['why']}",
                    f"You might try: {a['action']}. Rationale: {a['why']}",
                ]
            )
        )

    sections.append(
        _pick(
            [
                "Records can lag or be incomplete — if something material changed, we should re-check the picture.",
                "Guidance follows what's in the file today; missing data always leaves blind spots.",
            ]
        )
    )
    sections.extend(safety_footers())
    return sections


def compose_general_sections(message: str, patient_id: str, focus_evidence: Dict[str, Any]) -> List[str]:
    pid = focus_evidence.get("pillar_id", "a priority pillar").replace("_", " ")
    sc = focus_evidence.get("score", "?")
    tr = focus_evidence.get("trend", "?")

    return [
        opening_ack(message),
        _pick(
            [
                f"For {patient_id}, the compass is highlighting {pid} (about {sc}, {tr}) as the first place I'd explore in conversation.",
                f"Right now {patient_id}'s data points hardest at {pid} — score near {sc}, trend {tr}.",
                f"If we opened your dashboard together, I'd probably start with {pid}: ~{sc}, {tr}.",
            ]
        ),
        _pick(
            [
                "You can ask how sleep compares to stress, what 'weakest pillar' means for you, or for one concrete habit to try this week.",
                "Try: weakest vs strongest pillar, a plain-language nutrition readout, or where burnout risk shows up in the data.",
                "Ask about energy and recovery, cardiometabolic prevention, or what to ignore for now — I can route those.",
            ]
        ),
        _pick(
            [
                "I'm coaching from structured records and any Firestore context we synced — not replacing your clinician.",
                "Wellness coaching only; use this to steer habits and better questions for your doctor.",
            ]
        ),
    ]
