"""Conversational phrasing for chat responses — persona-informed variety (see docs/product/personas.md)."""

from __future__ import annotations

import random
import re
from typing import Any, Dict, List

PERSONA_LIBRARY = [
    {
        "name": "Markus",
        "country": "Germany",
        "age": 56,
        "life_stage": "senior executive",
        "digital_fluency": "medium",
        "main_motivation": "stay healthy and productive without feeling old",
        "main_fear": "a silent cardiovascular event that interrupts work and family plans",
        "tone": "concise and credibility-first",
    },
    {
        "name": "Sofia",
        "country": "Spain",
        "age": 41,
        "life_stage": "working parent",
        "digital_fluency": "medium",
        "main_motivation": "feel in control again without adding another burden",
        "main_fear": "burning out while ignoring early warning signs",
        "tone": "empathetic and sustainable",
    },
    {
        "name": "Claire",
        "country": "France",
        "age": 67,
        "life_stage": "active retiree",
        "digital_fluency": "low-medium",
        "main_motivation": "stay active and independent as long as possible",
        "main_fear": "gradual quality-of-life decline",
        "tone": "simple and independence-focused",
    },
    {
        "name": "Johanna",
        "country": "Austria",
        "age": 61,
        "life_stage": "pre-retirement professional",
        "digital_fluency": "medium",
        "main_motivation": "enter retirement in strong health with decisions she can trust",
        "main_fear": "discovering prevention risk too late",
        "tone": "trust-heavy and practical",
    },
    {
        "name": "Luca",
        "country": "Italy",
        "age": 29,
        "life_stage": "shift worker",
        "digital_fluency": "high",
        "main_motivation": "better daily energy and recovery",
        "main_fear": "falling into unhealthy routines he cannot sustainably fix",
        "tone": "fast, low-friction, affordable-feeling",
    },
    {
        "name": "Anika",
        "country": "Netherlands",
        "age": 46,
        "life_stage": "dual-career professional",
        "digital_fluency": "high",
        "main_motivation": "optimize healthspan with measurable personalization",
        "main_fear": "paying for generic wellness without real value",
        "tone": "precise and measurable",
    },
    {
        "name": "Tomasz",
        "country": "Poland",
        "age": 52,
        "life_stage": "small business owner",
        "digital_fluency": "medium-low",
        "main_motivation": "prevent a bigger problem without a complicated program",
        "main_fear": "developing diabetes or heart disease while too busy to notice",
        "tone": "direct and ROI-focused",
    },
    {
        "name": "Ingrid",
        "country": "Sweden",
        "age": 34,
        "life_stage": "health-aware knowledge worker",
        "digital_fluency": "high",
        "main_motivation": "make prevention more scientific and less guesswork",
        "main_fear": "missing an early pattern while appearing healthy",
        "tone": "evidence-led and nuanced",
    },
    {
        "name": "Elise",
        "country": "Belgium",
        "age": 74,
        "life_stage": "fixed-income retiree",
        "digital_fluency": "low",
        "main_motivation": "maintain independence and avoid sudden deterioration",
        "main_fear": "being overwhelmed by either medical or digital complexity",
        "tone": "gentle, clear, and reassuring",
    },
]


def _as_int(value: Any) -> int | None:
    try:
        if value in (None, ""):
            return None
        return int(float(value))
    except (TypeError, ValueError):
        return None


def _digital_signal_limit(digital_fluency: str) -> int:
    level = digital_fluency.lower()
    if "low" in level:
        return 3
    if "medium" in level:
        return 4
    return 5


def _age_guidance(age: int | None) -> Dict[str, str]:
    if age is None:
        return {
            "frame": "keep the advice practical and grounded in the current data",
            "next_step_style": "one realistic next step",
        }
    if age >= 70:
        return {
            "frame": "protect independence and avoid overwhelm",
            "next_step_style": "one simple next step that feels manageable",
        }
    if age >= 60:
        return {
            "frame": "protect long-term independence with clear, trustworthy prevention logic",
            "next_step_style": "one clear prevention step with obvious benefit",
        }
    if age >= 45:
        return {
            "frame": "keep prevention credible and worth the time investment",
            "next_step_style": "one high-ROI step that fits a busy week",
        }
    if age >= 35:
        return {
            "frame": "build sustainable control without adding another burden",
            "next_step_style": "one sustainable habit change rather than a full reset",
        }
    return {
        "frame": "protect energy and recovery with routines you can actually sustain",
        "next_step_style": "one lightweight, high-feedback habit",
    }


def derive_persona_context(profile: Dict[str, Any]) -> Dict[str, Any]:
    age = _as_int(profile.get("age"))
    country = str(profile.get("country") or "").strip()

    candidates = [
        persona for persona in PERSONA_LIBRARY if persona["country"].lower() == country.lower()
    ] or PERSONA_LIBRARY

    def persona_distance(persona: Dict[str, Any]) -> int:
        if age is None:
            return 0
        return abs(persona["age"] - age)

    persona = min(candidates, key=persona_distance)
    age_guidance = _age_guidance(age)
    return {
        "persona_name": persona["name"],
        "persona_country": persona["country"],
        "persona_age": persona["age"],
        "patient_age": age,
        "patient_country": country or None,
        "life_stage": persona["life_stage"],
        "digital_fluency": persona["digital_fluency"],
        "main_motivation": persona["main_motivation"],
        "main_fear": persona["main_fear"],
        "tone": persona["tone"],
        "signal_limit": _digital_signal_limit(persona["digital_fluency"]),
        "age_frame": age_guidance["frame"],
        "next_step_style": age_guidance["next_step_style"],
    }


def _is_low_complexity_persona(persona_context: Dict[str, Any] | None) -> bool:
    if not persona_context:
        return False
    digital = str(persona_context.get("digital_fluency") or "").lower()
    age = _as_int(persona_context.get("patient_age"))
    return "low" in digital or bool(age and age >= 70)


def followup_examples_line(persona_context: Dict[str, Any] | None) -> str:
    if not persona_context:
        return _pick(
            [
                "You can ask how sleep compares to stress, what 'weakest pillar' means for you, or for one concrete habit to try this week.",
                "Ask about energy and recovery, cardiometabolic prevention, or what to ignore for now — I can route those.",
            ]
        )

    if _is_low_complexity_persona(persona_context):
        return _pick(
            [
                "You can ask what matters most this week, what you can safely leave on maintenance, or what one manageable next step would help most.",
                "Ask me which area needs attention first, which one is doing well enough already, or what simple habit would be worth trying.",
            ]
        )

    digital = str(persona_context.get("digital_fluency") or "").lower()
    if "high" in digital:
        return _pick(
            [
                "Ask me to compare two pillars, explain the evidence behind the score, or suggest the highest-leverage experiment for the week.",
                "You can ask for a sharper trade-off, the strongest supporting signals, or the one change most likely to move the trend.",
            ]
        )

    return _pick(
        [
            "You can ask which pillar deserves focus first, where you're relatively protected, or what one realistic habit would help this week.",
            "Ask me to compare your strongest and weakest pillars, explain the trend in plain language, or narrow this to one practical next move.",
        ]
    )


def next_step_frame(persona_context: Dict[str, Any] | None) -> str:
    if not persona_context:
        return "Keep the next move practical and realistic."

    age = _as_int(persona_context.get("patient_age"))
    if age is None:
        return "Keep the next move practical and realistic."
    if age >= 70:
        return "Keep the next move simple enough to feel manageable."
    if age >= 60:
        return "Keep the next move clear, trustworthy, and obviously useful."
    if age >= 45:
        return "Keep the next move high-return and respectful of your time."
    if age >= 35:
        return "Keep the next move sustainable rather than intense."
    return "Keep the next move light, repeatable, and easy to learn from."


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


def format_signals_for_coach(
    signals: Dict[str, Any],
    max_items: int = 5,
    persona_context: Dict[str, Any] | None = None,
) -> str:
    """Turn key_signals into short spoken-style clauses (not a raw dict repr)."""
    if not signals:
        return "the usual profile and wearable-style inputs we have on file"
    if persona_context:
        max_items = min(max_items, int(persona_context.get("signal_limit", max_items)))
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


def persona_alignment_line(
    persona_context: Dict[str, Any] | None,
    focus_name: str,
    *,
    strongest_name: str | None = None,
) -> str:
    if not persona_context:
        return f"For someone in your position, {focus_name} is where the next decision has the most leverage."

    motivation = persona_context["main_motivation"]
    fear = persona_context["main_fear"]
    frame = persona_context["age_frame"]
    if strongest_name:
        return _pick(
            [
                f"Given your stage of life, the aim is to {frame}; that makes {focus_name} the place to work, while {strongest_name} can stay on maintenance.",
                f"If the real goal is to {motivation}, then {focus_name} deserves the energy now — especially because the bigger risk is {fear}.",
            ]
        )
    return _pick(
        [
            f"For someone in your stage of life, the point is to {frame}, not to chase perfect scores.",
            f"If the real goal is to {motivation}, then this answer should help you move without feeding the fear of {fear}.",
        ]
    )


def persona_style_line(persona_context: Dict[str, Any] | None) -> str:
    if not persona_context:
        return "I'll keep this practical and grounded in the data we have."
    return _pick(
        [
            f"I'm answering with your situation in mind: the goal is to {persona_context['main_motivation']}.",
            f"I'll keep this {persona_context['tone']} because the point is to {persona_context['main_motivation']}, not to add more health noise.",
        ]
    )


def compose_priority_sections(
    intent: str,
    weakest: Dict[str, Any],
    strongest: Dict[str, Any],
    next_weakest: Dict[str, Any],
    persona_context: Dict[str, Any] | None = None,
) -> List[str]:
    wn, ws = weakest["name"], weakest["score"]
    wtrend = trend_phrase(weakest["trend"])
    wsig = format_signals_for_coach(weakest.get("key_signals") or {}, persona_context=persona_context)
    sn, ss = strongest["name"], strongest["score"]
    strend = trend_phrase(strongest["trend"])
    ssig = format_signals_for_coach(strongest.get("key_signals") or {}, persona_context=persona_context)
    nn = next_weakest["name"]
    style = persona_style_line(persona_context)

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
        return [lead, style, body, persona_alignment_line(persona_context, wn, strongest_name=sn), close]

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
        return [lead, style, body, persona_alignment_line(persona_context, wn, strongest_name=sn), close]

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
        return [lead, style, body, persona_alignment_line(persona_context, wn, strongest_name=sn), close]

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
    return [lead, style, body, persona_alignment_line(persona_context, wn, strongest_name=sn), close]


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


def compose_pillar_sections(
    pillar: Dict[str, Any],
    firebase_summary: str,
    persona_context: Dict[str, Any] | None = None,
) -> List[str]:
    name = pillar["name"]
    state, trend, score = pillar["state"], pillar["trend"], pillar["score"]
    expl = pillar.get("explanation") or ""
    sig = format_signals_for_coach(pillar.get("key_signals") or {}, persona_context=persona_context)
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
    return [lead, body, persona_alignment_line(persona_context, name), evidence, ctx, unc, safe]


def compose_tailored_sections(payload: Dict[str, Any]) -> List[str]:
    context = payload["context"]
    claims = payload.get("claims", [])
    trade_offs = payload.get("trade_offs", [])
    actions = payload.get("next_best_actions", [])
    persona_context = payload.get("persona_context")

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
    sections.append(persona_style_line(persona_context))

    for claim in claims:
        ev = claim["evidence"][0]
        sig = format_signals_for_coach(ev.get("key_signals") or {}, persona_context=persona_context)
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
                    f"{next_step_frame(persona_context)} {a['action']} {a['why']}",
                    f"You might try this next: {a['action']} {a['why']}",
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


def compose_offer_recommendation_sections(
    offer: Dict[str, Any],
    *,
    primary_focus: Dict[str, Any] | None = None,
    persona_context: Dict[str, Any] | None = None,
    scheduled_label: str | None = None,
    existing_booking: Dict[str, Any] | None = None,
) -> List[str]:
    label = offer.get("offer_label") or "this support option"
    summary = offer.get("summary") or offer.get("rationale") or "It is the clearest next support step from your current data."
    why_now = offer.get("why_now") or offer.get("rationale") or "It fits the current pattern in your records."
    personalization = offer.get("personalization_note") or ""
    missing_data = offer.get("missing_data") or []
    focus_name = (primary_focus or {}).get("pillar_name") or label

    sections = [
        _pick(
            [
                f"The support option I'd put first right now is {label}.",
                f"If you want one concrete support step, I'd point to {label}.",
            ]
        ),
        persona_style_line(persona_context),
        _pick(
            [
                f"{summary} The main reason now is simple: {why_now}",
                f"Why this one: {summary} More specifically, {why_now}",
            ]
        ),
        persona_alignment_line(persona_context, focus_name),
    ]

    if personalization:
        sections.append(personalization)

    if existing_booking:
        sections.append(
            f"You already have this booked for {existing_booking.get('scheduled_label') or 'a saved slot'}, so I would treat that as your active next step."
        )
    elif scheduled_label:
        sections.append(
            f"If you want, I can book the first available demo slot for you automatically: {scheduled_label}. Just say 'book it'."
        )

    if missing_data:
        sections.append(
            _pick(
                [
                    f"To make it even sharper, {missing_data[0]}",
                    f"One thing that would personalize this more: {missing_data[0]}",
                ]
            )
        )

    return sections


def compose_offer_booking_sections(
    offer: Dict[str, Any],
    booking: Dict[str, Any],
    *,
    persona_context: Dict[str, Any] | None = None,
) -> List[str]:
    label = offer.get("offer_label") or booking.get("offer_label") or "your support option"
    scheduled_label = booking.get("scheduled_label") or "the next available slot"
    first_week = offer.get("first_week") or []

    sections = [
        _pick(
            [
                f"I've booked {label} for {scheduled_label}.",
                f"{label} is now booked for {scheduled_label}.",
            ]
        ),
        _pick(
            [
                "I saved it to your support bookings, so it should show up alongside the other booked next steps.",
                "That booking is now saved in your support bookings, not just mentioned in chat.",
            ]
        ),
        next_step_frame(persona_context),
    ]

    if first_week:
        sections.append(
            _pick(
                [
                    f"Before then, start with this: {first_week[0]}",
                    f"The best thing to do before that slot is simple: {first_week[0]}",
                ]
            )
        )
    return sections


def compose_general_sections(
    message: str,
    patient_id: str,
    focus_evidence: Dict[str, Any],
    persona_context: Dict[str, Any] | None = None,
) -> List[str]:
    pid = focus_evidence.get("pillar_id", "a priority pillar").replace("_", " ")
    sc = focus_evidence.get("score", "?")
    tr = focus_evidence.get("trend", "?")

    return [
        opening_ack(message),
        persona_style_line(persona_context),
        _pick(
            [
                f"Based on your current data, I'd start with {pid}: about {sc} and {tr}.",
                f"The part of your compass asking for the most attention right now is {pid}, sitting near {sc} and {tr}.",
                f"If we opened your dashboard together, I'd probably start with {pid}: roughly {sc} and {tr}.",
            ]
        ),
        persona_alignment_line(persona_context, pid),
        followup_examples_line(persona_context),
        _pick(
            [
                "I'm coaching from structured records and any Firestore context we synced — not replacing your clinician.",
                "Wellness coaching only; use this to steer habits and better questions for your doctor.",
            ]
        ),
    ]
