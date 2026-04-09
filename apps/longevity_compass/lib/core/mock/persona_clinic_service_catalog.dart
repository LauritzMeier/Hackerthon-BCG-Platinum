class PersonaClinicProgram {
  const PersonaClinicProgram({
    required this.personaName,
    required this.country,
    required this.focus,
    required this.positioning,
    required this.salesNarrative,
    required this.services,
  });

  final String personaName;
  final String country;
  final String focus;
  final String positioning;
  final String salesNarrative;
  final List<ClinicServiceMock> services;
}

class ClinicServiceMock {
  const ClinicServiceMock({
    required this.title,
    required this.format,
    required this.outcome,
    required this.commercialRole,
  });

  final String title;
  final String format;
  final String outcome;
  final String commercialRole;
}

const mvpPersonaClinicPrograms = <PersonaClinicProgram>[
  PersonaClinicProgram(
    personaName: 'Markus Weber',
    country: 'Germany',
    focus: 'Cardiometabolic prevention with executive-level trust',
    positioning:
        'Premium clinic services for high-intent patients who want concise guidance, credible diagnostics, and minimal time waste.',
    salesNarrative:
        'Markus converts when the clinic feels medically serious, commercially premium, and respectful of his schedule.',
    services: [
      ClinicServiceMock(
        title: 'Executive CardioMetabolic Baseline',
        format:
            '90-minute physician visit, blood panel, blood-pressure review, and prevention summary',
        outcome:
            'Detects hidden cardiovascular and metabolic drift before it becomes a disruptive event.',
        commercialRole: 'High-value diagnostic anchor package',
      ),
      ClinicServiceMock(
        title: 'Precision Recovery Coaching',
        format: '6-week physician plus coach follow-up with wearable check-ins',
        outcome:
            'Turns lab results into a practical sleep, stress, and activity recovery plan.',
        commercialRole:
            'Recurring follow-up revenue with clear clinical relevance',
      ),
      ClinicServiceMock(
        title: 'Annual Longevity Review',
        format: 'Quarterly remote check-ins plus one in-clinic yearly review',
        outcome:
            'Keeps prevention visible without forcing Markus into a heavy-touch program.',
        commercialRole: 'Retention layer for premium prevention members',
      ),
    ],
  ),
  PersonaClinicProgram(
    personaName: 'Sofia Alvarez',
    country: 'Spain',
    focus: 'Stress, sleep, and sustainable routines',
    positioning:
        'Supportive, low-friction services for patients who need relief and structure, not another complicated health program.',
    salesNarrative:
        'Sofia converts when the offer feels empathetic, time-aware, and immediately useful for sleep and burnout prevention.',
    services: [
      ClinicServiceMock(
        title: 'Sleep Recovery Sprint',
        format:
            '2-week sleep assessment with coaching, sleep diary, and practical habit reset',
        outcome:
            'Improves energy and sleep consistency without requiring a major lifestyle overhaul.',
        commercialRole: 'Accessible entry package for repeat engagement',
      ),
      ClinicServiceMock(
        title: 'Stress Reset Consult Track',
        format:
            'Three short clinician or coach sessions with HRV-aware stress guidance',
        outcome:
            'Gives Sofia a clear plan for reducing overload before it becomes burnout.',
        commercialRole:
            'Mid-tier care package with strong repeat-booking potential',
      ),
      ClinicServiceMock(
        title: 'Family-Fit Preventive Check',
        format:
            'Convenient screening slots plus nutrition and recovery recommendations',
        outcome:
            'Makes prevention feel realistic for a working parent with limited spare time.',
        commercialRole: 'Bundled service that broadens household conversion',
      ),
    ],
  ),
  PersonaClinicProgram(
    personaName: 'Tomasz Nowak',
    country: 'Poland',
    focus: 'Metabolic-risk prevention without time burden',
    positioning:
        'Straightforward clinic services for busy patients who want obvious ROI on time, cost, and prevention effort.',
    salesNarrative:
        'Tomasz converts when the offer is practical, easy to schedule, and clearly tied to diabetes or heart-risk prevention.',
    services: [
      ClinicServiceMock(
        title: 'Metabolic Risk Turnaround',
        format:
            'Lab bundle, clinician consult, and one-page risk explanation with next steps',
        outcome:
            'Creates a simple first intervention for glucose, weight, and cardiovascular risk.',
        commercialRole:
            'Core prevention package with broad clinic applicability',
      ),
      ClinicServiceMock(
        title: 'Dietitian Fast-Track',
        format:
            'Three focused nutrition sessions with a realistic meal and routine reset',
        outcome:
            'Helps Tomasz act quickly without signing up for an overwhelming long-term program.',
        commercialRole: 'Low-friction upsell after diagnostic screening',
      ),
      ClinicServiceMock(
        title: 'Time-Saver Annual Risk Review',
        format:
            'Remote follow-up review with yearly in-person screening refresh',
        outcome:
            'Keeps monitoring simple for patients who are motivated but chronically short on time.',
        commercialRole:
            'Retention package for high-risk but low-availability patients',
      ),
    ],
  ),
];
