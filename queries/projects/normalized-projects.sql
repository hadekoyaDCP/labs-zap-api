-- this is the base query used for filtering

CREATE MATERIALIZED VIEW normalized_projects AS
SELECT dcp_project.*,
  CASE
    WHEN dcp_project.dcp_publicstatus = 'Filed' THEN 'Filed'
    WHEN dcp_project.dcp_publicstatus = 'Certified' THEN 'In Public Review'
    WHEN dcp_project.dcp_publicstatus = 'Approved' THEN 'Completed'
    WHEN dcp_project.dcp_publicstatus = 'Withdrawn' THEN 'Completed'
    ELSE 'Unknown'
  END AS dcp_publicstatus_simp,
  STRING_AGG(SUBSTRING(actions.dcp_name FROM '^(\w+)'), ';') AS actiontypes,
  STRING_AGG(DISTINCT actions.dcp_ulurpnumber, ';') AS ulurpnumbers,
  STRING_AGG(dcp_projectbbl.dcp_validatedblock, ';') AS blocks,
  STRING_AGG(applicantteams.name, ';') AS applicants,
  lastmilestonedates.lastmilestonedate
FROM dcp_project
LEFT JOIN (
  SELECT * FROM dcp_projectaction
  WHERE statuscode <> 'Mistake'
  AND SUBSTRING(dcp_name FROM '^(\w+)') IN (
    'BD',
    'BF',
    'CM',
    'CP',
    'DL',
    'DM',
    'EB',
    'EC',
    'EE',
    'EF',
    'EM',
    'EN',
    'EU',
    'GF',
    'HA',
    'HC',
    'HD',
    'HF',
    'HG',
    'HI',
    'HK',
    'HL',
    'HM',
    'HN',
    'HO',
    'HP',
    'HR',
    'HS',
    'HU',
    'HZ',
    'LD',
    'MA',
    'MC',
    'MD',
    'ME',
    'MF',
    'ML',
    'MM',
    'MP',
    'MY',
    'NP',
    'PA',
    'PC',
    'PD',
    'PE',
    'PI',
    'PL',
    'PM',
    'PN',
    'PO',
    'PP',
    'PQ',
    'PR',
    'PS',
    'PX',
    'RA',
    'RC',
    'RS',
    'SC',
    'TC',
    'TL',
    'UC',
    'VT',
    'ZA',
    'ZC',
    'ZD',
    'ZJ',
    'ZL',
    'ZM',
    'ZP',
    'ZR',
    'ZS',
    'ZX',
    'ZZ'
  )
) actions
  ON actions.dcp_project = dcp_project.dcp_projectid
LEFT JOIN dcp_projectbbl
  ON dcp_projectbbl.dcp_project = dcp_project.dcp_projectid
LEFT JOIN (
  SELECT dcp_project, CASE WHEN pa.dcp_name IS NOT NULL THEN pa.dcp_name ELSE account.name END as name
  FROM dcp_projectapplicant pa
  LEFT JOIN account
	ON account.accountid = pa.dcp_applicant_customer
  WHERE dcp_applicantrole IN ('Applicant', 'Co-Applicant')
  AND pa.statuscode = 'Active'
  ORDER BY dcp_applicantrole ASC
) applicantteams
  ON applicantteams.dcp_project = dcp_project.dcp_projectid
LEFT JOIN (
  SELECT dcp_project, MAX(dcp_actualenddate) as lastmilestonedate FROM (
    SELECT dcp_project, dcp_milestone.dcp_name, dcp_actualenddate FROM dcp_projectmilestone mm
    	LEFT JOIN dcp_milestone
    	   ON mm.dcp_milestone = dcp_milestone.dcp_milestoneid
    	WHERE dcp_milestone.dcp_name IN (
    	  'Land Use Fee Payment',
    	  'Land Use Application Filed Review',
    	  'CEQR Fee Payment',
    	  'Filed EAS Review',
    	  'EIS Draft Scope Review',
    	  'EIS Public Scoping Meeting',
    	  'Final Scope of Work Issued',
    	  'NOC of Draft EIS Issued',
    	  'DEIS Public Hearing Held',
    	  'Review Session - Certified / Referred',
    	  'Community Board Referral',
    	  'Borough President Referral',
    	  'Borough Board Referral',
    	  'CPC Public Meeting - Vote',
    	  'CPC Public Meeting - Public Hearing',
    	  'City Council Review',
    	  'Mayoral Veto',
    	  'Final Letter Sent'
    	)
    	AND mm.statuscode <> 'Overridden'
    )x GROUP BY dcp_project
) lastmilestonedates
	ON lastmilestonedates.dcp_project = dcp_project.dcp_projectid
GROUP BY dcp_project.dcp_projectid, dcp_project.dcp_publicstatus, lastmilestonedates.lastmilestonedate
