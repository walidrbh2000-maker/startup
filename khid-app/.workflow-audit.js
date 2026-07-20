export const meta = {
  name: 'khid-screens-audit',
  description: 'Audit all Khidmeti Flutter screens against pro UI checklist, adversarially verify findings',
  phases: [
    { title: 'Audit', detail: 'one agent per screen group, checklist-driven' },
    { title: 'Verify', detail: 'adversarial verification of each group findings' },
  ],
}

const ROOT = '/data/data/com.termux/files/home/myproject/khid-app'

const FINDINGS_SCHEMA = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['file', 'line', 'severity', 'category', 'issue', 'fix'],
    properties: {
      file: { type: 'string' }, line: { type: 'integer' },
      severity: { enum: ['P0', 'P1', 'P2'] }, category: { type: 'string' },
      issue: { type: 'string' }, fix: { type: 'string' },
    } } } },
}

const VERDICTS_SCHEMA = {
  type: 'object', required: ['verdicts'],
  properties: { verdicts: { type: 'array', items: {
    type: 'object', required: ['index', 'confirmed', 'reason'],
    properties: { index: { type: 'integer' }, confirmed: { type: 'boolean' }, reason: { type: 'string' } },
  } } },
}

const CONVENTIONS = `
PROJECT CONVENTIONS (do NOT flag these as issues):
- Design language "Point Final": single indigo accent #4F46E5, flat surfaces (no gradients/glows), restrained motion, typographic brand (headline + accent full stop). 0.5dp hairline borders (AppConstants.cardBorderWidth) are intentional.
- Tokens live in lib/utils/app_theme.dart (AppTheme.light*/dark*) and lib/utils/constants.dart (AppConstants.spacing*/padding*/radius*/animDuration*/buttonHeight*). File-local layout metrics named _kSomething at top of widget files are an accepted convention.
- Shared widgets that MUST be reused instead of ad-hoc ones: AppBackButton/AppBarBackButton (lib/widgets/back_button.dart), AppSliverHeader, FeatureErrorState, FeatureEmptyState, sheet chrome/handle (lib/widgets/sheet_chrome.dart), ErrorHandler snackbars.
- 'emoji:X' sentinel values in profileImageUrl are an intentional avatar system, not a bug.

WHAT TO CHECK (report only violations you verified by reading the code, with real line numbers):
1. Touch targets >= 48x48dp (or documented hit-area expansion); buttons use AppConstants.buttonHeight* tokens.
2. Text contrast >= 4.5:1 body / >= 3:1 secondary — check BOTH light and dark values; low-alpha text on colored surfaces.
3. RTL correctness: EdgeInsets with left/right instead of EdgeInsetsDirectional; Alignment.centerLeft vs AlignmentDirectional; chevrons/arrows that must flip; Positioned left/right vs PositionedDirectional. App ships Arabic-first.
4. Reduced motion: entrance/looping animations must gate on MediaQuery.disableAnimationsOf(context).
5. Semantics: interactive elements labeled; labels localized via context.tr (hardcoded English strings in Semantics/labels = P1); decorative visuals excluded.
6. Spacing rhythm 4/8dp; raw magic numbers where a token exists = P2.
7. Animation durations 150-400ms via AppConstants tokens; anything instant (0ms) or > 500ms without reason.
8. Pressed feedback on every tappable (InkWell/ripple/opacity), no GestureDetector on bare Container for primary actions without feedback.
9. Disabled/loading states visually distinct and non-interactive.
10. Field errors shown near the field, not only in snackbars; fixed-height error slots so layout does not jump.
11. Safe areas; scroll bodies add AppConstants.navBarScrollClearance when a floating nav bar overlays them.
12. No layout shift on focus/press/state change (border width changes, size jumps).
13. Font sizes >= 12; single icon family (Material rounded); no emoji as structural icons.
14. Raw Color(0x...)/Colors.* in screen files where an AppTheme token exists = P2 (except Colors.white/black on accent surfaces).
15. Dark-mode parity: every isDark branch has sensible dark values; nothing readable only in one theme.
Severity: P0 = unusable/inaccessible/clearly broken visual; P1 = noticeable best-practice violation; P2 = polish.
Return ONLY high-confidence findings. No speculation. file = path relative to ${ROOT}.`

function auditPrompt(g) {
  return `You are a senior mobile UI/UX auditor reviewing a production Flutter app (Arabic-first, RTL+LTR, light+dark themes).
Read ONLY these files (prefix each with ${ROOT}/):
${g.files.join('\n')}
Also read for reference (tokens): lib/utils/app_theme.dart lines 1-200 and lib/utils/constants.dart lines 1-160 under the same root.
${CONVENTIONS}
Audit every listed file. Your final output is ONLY the structured findings (raw data, no prose).`
}

function verifyPrompt(g, findings) {
  return `You are an adversarial reviewer. Another auditor produced findings for Flutter files under ${ROOT}.
For EACH finding below (identified by its array index), open the cited file at the cited line and try to REFUTE it:
- Is the claim factually true in the code as written?
- Is it actually a violation, or an intentional project convention? ${CONVENTIONS.split('WHAT TO CHECK')[0]}
- Is the proposed fix safe and non-breaking?
Mark confirmed=false for anything vague, duplicated, already handled elsewhere in the file, or intentional. Be strict: when uncertain, confirmed=false.
FINDINGS:
${JSON.stringify(findings, null, 1)}
Return a verdict for every index.`
}

log(`Auditing ${args.groups.length} screen groups`)

const results = await pipeline(
  args.groups,
  g => agent(auditPrompt(g), { label: `audit:${g.name}`, phase: 'Audit', schema: FINDINGS_SCHEMA }),
  (rev, g) => {
    if (!rev || !rev.findings.length) return { group: g.name, findings: [] }
    return agent(verifyPrompt(g, rev.findings), { label: `verify:${g.name}`, phase: 'Verify', schema: VERDICTS_SCHEMA })
      .then(v => ({
        group: g.name,
        findings: rev.findings.map((f, i) => {
          const verdict = v && v.verdicts.find(x => x.index === i)
          return { ...f, confirmed: verdict ? verdict.confirmed : true, verifyReason: verdict ? verdict.reason : 'no verdict' }
        }),
      }))
  },
)

const flat = results.filter(Boolean)
const total = flat.reduce((n, r) => n + r.findings.length, 0)
const confirmed = flat.reduce((n, r) => n + r.findings.filter(f => f.confirmed).length, 0)
log(`${total} raw findings, ${confirmed} confirmed`)
return flat